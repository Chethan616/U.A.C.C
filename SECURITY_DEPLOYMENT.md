# Security & Deployment Guide

## Security Overview

### API Key Management
**NEVER store API keys in:**
- Mobile app source code
- Firebase Remote Config
- Firestore documents
- Client-accessible storage

**DO use:**
- Google Secret Manager (recommended)
- Firebase Functions environment variables (for development)
- Cloud KMS for additional encryption

### Secret Manager Setup (Production)

1. **Create the secret:**
```bash
# Create secret and add initial version
echo "your-gemini-api-key-here" | gcloud secrets create GEMINI_API_KEY --data-file=-

# Or from file
gcloud secrets create GEMINI_API_KEY --data-file=key.txt
```

2. **Grant access to Cloud Functions:**
```bash
# Get your project's default compute service account
PROJECT_ID=$(gcloud config get-value project)
SERVICE_ACCOUNT="${PROJECT_ID}@appspot.gserviceaccount.com"

# Grant Secret Manager access
gcloud secrets add-iam-policy-binding GEMINI_API_KEY \
    --member="serviceAccount:${SERVICE_ACCOUNT}" \
    --role="roles/secretmanager.secretAccessor"
```

3. **Update function to use secrets:**
The function is already configured to load secrets. Deploy with:
```bash
firebase deploy --only functions:geminiProxy
```

### Rate Limiting & Security Features

The updated function includes:
- **Rate limiting:** 20 requests per minute per user
- **Input validation:** Maximum transcript length (10,000 chars)
- **Error handling:** Structured logging and error responses
- **CORS support:** For web applications
- **Request monitoring:** Processing time and user tracking

### Key Rotation

To rotate the Gemini API key:

1. **Create new version:**
```bash
echo "new-api-key-here" | gcloud secrets versions add GEMINI_API_KEY --data-file=-
```

2. **The function automatically uses the latest version**

3. **Disable old version (after testing):**
```bash
gcloud secrets versions disable VERSION_NUMBER --secret="GEMINI_API_KEY"
```

## Deployment Guide

### Prerequisites

1. **Install Firebase CLI:**
```bash
npm install -g firebase-tools
```

2. **Login and select project:**
```bash
firebase login
firebase use uacc-uacc  # or your project ID
```

3. **Enable required APIs:**
```bash
gcloud services enable cloudfunctions.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### Local Development

1. **Install dependencies:**
```bash
cd functions
npm install
```

2. **Set up local environment:**
```bash
# For emulator testing, set env var
export GEMINI_API_KEY="your-key-for-testing"
```

3. **Start emulator:**
```bash
firebase emulators:start --only functions
```

4. **Test locally:**
```bash
# Get a Firebase ID token from your app, then:
curl -X POST 'http://localhost:5001/uacc-uacc/us-central1/geminiProxy' \
  -H 'Authorization: Bearer YOUR_FIREBASE_ID_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"transcript":"Test transcript for local development"}'
```

### Production Deployment

1. **Set up Secret Manager (see above)**

2. **Deploy function:**
```bash
firebase deploy --only functions:geminiProxy
```

3. **Verify deployment:**
```bash
# Test the production endpoint
curl -X POST 'https://us-central1-uacc-uacc.cloudfunctions.net/geminiProxy' \
  -H 'Authorization: Bearer YOUR_FIREBASE_ID_TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"transcript":"Production test"}'
```

### Monitoring & Logging

View logs:
```bash
firebase functions:log --only geminiProxy
```

Set up monitoring:
- Enable Cloud Monitoring for the function
- Set up alerts for error rates and latency
- Monitor quota usage for Gemini API

### Environment Variables

For non-secret configuration:
```bash
# Set function config
firebase functions:config:set gemini.model="gemini-2.0-flash-exp"
firebase functions:config:set app.rate_limit="20"

# Deploy to apply changes
firebase deploy --only functions:geminiProxy
```

## Security Checklist

- [ ] API key stored in Secret Manager (not in code)
- [ ] Service account has minimal required permissions
- [ ] Rate limiting enabled and tested
- [ ] Input validation in place
- [ ] Error handling doesn't leak sensitive information
- [ ] Monitoring and alerting configured
- [ ] HTTPS-only communication
- [ ] Firebase ID token verification working
- [ ] Regular key rotation schedule established

## Incident Response

### If API Key is Compromised

1. **Immediately disable the current version:**
```bash
gcloud secrets versions disable CURRENT_VERSION --secret="GEMINI_API_KEY"
```

2. **Create new key and update secret:**
```bash
echo "new-emergency-key" | gcloud secrets versions add GEMINI_API_KEY --data-file=-
```

3. **Deploy function to pick up new key:**
```bash
firebase deploy --only functions:geminiProxy
```

4. **Monitor for unusual activity**

### High Error Rate Response

1. **Check function logs:**
```bash
firebase functions:log --only geminiProxy --lines 100
```

2. **Check Gemini API quotas and billing**

3. **Temporarily reduce rate limits if needed**

## Cost Management

- Monitor Gemini API usage and costs
- Set up billing alerts
- Consider implementing user quotas
- Review and optimize function memory/timeout settings
- Use Cloud Functions pricing calculator for estimates

## Compliance Notes

- User data (transcripts) are temporarily processed but not stored by the function
- Ensure compliance with data protection regulations (GDPR, CCPA)
- Consider data residency requirements when selecting function regions
- Implement audit logging for sensitive operations