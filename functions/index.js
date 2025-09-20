const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');
const {SecretManagerServiceClient} = require('@google-cloud/secret-manager');

admin.initializeApp();

// Rate limiting: simple in-memory store (use Redis/Firestore for production)
const rateLimitMap = new Map();
const RATE_LIMIT_WINDOW = 60000; // 1 minute
const MAX_REQUESTS_PER_WINDOW = 20;

// Initialize Secret Manager client
const secretClient = new SecretManagerServiceClient();

/**
 * Get secret from Secret Manager
 */
async function getSecret(secretName) {
  try {
    const name = `projects/${process.env.GCLOUD_PROJECT}/secrets/${secretName}/versions/latest`;
    const [version] = await secretClient.accessSecretVersion({name});
    return version.payload.data.toString();
  } catch (error) {
    console.error(`Failed to access secret ${secretName}:`, error);
    throw error;
  }
}

/**
 * Simple rate limiting
 */
function checkRateLimit(userId) {
  const now = Date.now();
  const userKey = userId || 'anonymous';
  
  if (!rateLimitMap.has(userKey)) {
    rateLimitMap.set(userKey, {count: 1, windowStart: now});
    return true;
  }
  
  const userData = rateLimitMap.get(userKey);
  if (now - userData.windowStart > RATE_LIMIT_WINDOW) {
    // Reset window
    userData.count = 1;
    userData.windowStart = now;
    return true;
  }
  
  if (userData.count >= MAX_REQUESTS_PER_WINDOW) {
    return false;
  }
  
  userData.count++;
  return true;
}

/**
 * Cloud Function: geminiProxy
 * Expects POST with JSON: { transcript: string, instructions?: string }
 * Auth: Firebase ID token in Authorization: Bearer <token>
 * Returns: { summary, tasks: [], events: [] }
 */
exports.geminiProxy = functions.runWith({
  memory: '1GB', 
  timeoutSeconds: 60,
  secretsToLoad: [
    { key: 'GEMINI_API_KEY', versionId: 'latest' }
  ]
}).https.onRequest(async (req, res) => {
  const startTime = Date.now();
  
  try {
    // CORS headers
    res.set('Access-Control-Allow-Origin', '*');
    res.set('Access-Control-Allow-Methods', 'POST, OPTIONS');
    res.set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
    
    if (req.method === 'OPTIONS') {
      return res.status(200).send('');
    }
    
    if (req.method !== 'POST') {
      return res.status(405).send({error: 'Method not allowed'});
    }

    // DEV-ONLY: Skip auth in emulator mode with special header
    let decoded;
    if (process.env.FUNCTIONS_EMULATOR === 'true' && req.get('x-dev-uid')) {
      console.log('DEV MODE: Using fake auth for emulator testing');
      decoded = { uid: req.get('x-dev-uid') };
    } else {
      // Validate Authorization header
      const auth = req.get('Authorization') || '';
      if (!auth.startsWith('Bearer ')) {
        return res.status(401).send({error: 'Missing Authorization Bearer token'});
      }
      const idToken = auth.split('Bearer ')[1].trim();

      // Verify Firebase ID token
      try {
        decoded = await admin.auth().verifyIdToken(idToken);
      } catch (e) {
        console.error('Invalid ID token:', e.message);
        return res.status(401).send({error: 'Invalid ID token'});
      }
    }

    // Rate limiting
    if (!checkRateLimit(decoded.uid)) {
      return res.status(429).send({error: 'Rate limit exceeded', retryAfter: 60});
    }

    // Validate request body
    const {transcript, instructions} = req.body || {};
    if (!transcript || typeof transcript !== 'string') {
      return res.status(400).send({error: 'Missing transcript string in body'});
    }
    
    if (transcript.length > 10000) {
      return res.status(400).send({error: 'Transcript too long (max 10000 characters)'});
    }

    // Get API key from Secret Manager or env
    let apiKey;
    try {
      apiKey = process.env.GEMINI_API_KEY || await getSecret('GEMINI_API_KEY');
    } catch (error) {
      console.error('Failed to get API key:', error);
      return res.status(500).send({error: 'Server configuration error'});
    }

    if (!apiKey) {
      return res.status(500).send({error: 'Server misconfiguration: GEMINI_API_KEY not available'});
    }

    // Build structured prompt for Gemini
    const systemPrompt = `You are an AI assistant that processes voice transcripts and extracts structured information. 
Given a transcript, provide a JSON response with:
1. A concise summary
2. Actionable tasks with due dates (if mentioned)
3. Calendar events with start/end times (if mentioned)

Respond with valid JSON only, no additional text.`;

    const prompt = `${systemPrompt}

Transcript: "${transcript}"
${instructions ? `Additional instructions: ${instructions}` : ''}

Required JSON format:
{
  "summary": "Brief summary of the transcript",
  "tasks": [{"title": "Task description", "due": "YYYY-MM-DD or null"}],
  "events": [{"title": "Event name", "start": "ISO8601 datetime", "end": "ISO8601 datetime", "description": "Details"}]
}`;

    // Call Gemini API (using Google AI Studio endpoint format)
    const geminiUrl = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp:generateContent';
    
    const payload = {
      contents: [{
        parts: [{
          text: prompt
        }]
      }],
      generationConfig: {
        maxOutputTokens: 1024,
        temperature: 0.1
      }
    };

    console.log('Calling Gemini API for user:', decoded.uid);
    const response = await axios.post(geminiUrl, payload, {
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey
      },
      timeout: 45000
    });

    // Extract text from Gemini response
    const candidates = response.data?.candidates || [];
    if (candidates.length === 0) {
      return res.status(500).send({error: 'No response from Gemini'});
    }

    const generatedText = candidates[0]?.content?.parts?.[0]?.text || '';
    if (!generatedText) {
      return res.status(500).send({error: 'Empty response from Gemini'});
    }

    // Parse JSON from response
    let parsedResult;
    try {
      // Try to extract JSON from the response (in case there's extra text)
      const jsonMatch = generatedText.match(/\{[\s\S]*\}/);
      const jsonText = jsonMatch ? jsonMatch[0] : generatedText;
      parsedResult = JSON.parse(jsonText);
      
      // Validate structure
      if (!parsedResult.summary) parsedResult.summary = 'No summary available';
      if (!Array.isArray(parsedResult.tasks)) parsedResult.tasks = [];
      if (!Array.isArray(parsedResult.events)) parsedResult.events = [];
      
    } catch (parseError) {
      console.warn('Failed to parse Gemini response as JSON:', parseError.message);
      // Fallback: return raw text with basic structure
      parsedResult = {
        summary: generatedText.substring(0, 500),
        tasks: [],
        events: [],
        raw: generatedText
      };
    }

    // Log success metrics
    const duration = Date.now() - startTime;
    console.log(`Request completed for ${decoded.uid} in ${duration}ms`);

    return res.status(200).send({
      success: true,
      data: parsedResult,
      metadata: {
        userId: decoded.uid,
        timestamp: new Date().toISOString(),
        processingTime: duration
      }
    });

  } catch (error) {
    const duration = Date.now() - startTime;
    console.error('geminiProxy error:', {
      message: error.message,
      stack: error.stack,
      duration,
      url: error.config?.url,
      status: error.response?.status,
      data: error.response?.data
    });
    
    if (error.response?.status === 429) {
      return res.status(429).send({error: 'Gemini API rate limit exceeded', retryAfter: 60});
    }
    
    return res.status(500).send({
      error: 'Internal server error',
      requestId: req.get('X-Request-ID') || 'unknown'
    });
  }
});
