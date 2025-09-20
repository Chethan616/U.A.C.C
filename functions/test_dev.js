const axios = require('axios');

async function testGeminiProxy() {
  try {
    console.log('Testing geminiProxy with dev bypass...');
    console.log('API Key available:', !!process.env.GEMINI_API_KEY);
    
    const response = await axios.post('http://localhost:5001/uacc-uacc/us-central1/geminiProxy', 
      {
        transcript: 'Schedule a meeting with John tomorrow at 2 PM and remind me to buy groceries today',
        instructions: 'Extract tasks and events clearly'
      }, 
      {
        headers: { 
          'Content-Type': 'application/json',
          'x-dev-uid': 'test-user-123'  // Dev bypass header
        },
        timeout: 30000  // 30 second timeout
      }
    );
    
    console.log('✅ Success! Response:');
    console.log(JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('❌ Error details:');
    console.error('Status:', error.response?.status);
    console.error('Status Text:', error.response?.statusText);
    console.error('Response Data:', error.response?.data);
    console.error('Full Error:', error.message);
  }
}

testGeminiProxy();