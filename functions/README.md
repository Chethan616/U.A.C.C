Firebase Functions proxy for Gemini 2.0 Flash

Purpose
- Provide a secure server-side proxy so the Gemini API key is never embedded in the Flutter app.
- Verifies Firebase ID tokens and accepts transcript text, calls Gemini, and returns structured JSON.

Files
- index.js - the Cloud Function implementation
- package.json - node dependencies and scripts

Setup & deploy
1. Install firebase-tools and login: `npm i -g firebase-tools` then `firebase login`.
2. From this `functions/` folder run `npm install`.
3. Set the Gemini API key in functions environment or better: use Secret Manager.

# Using environment variables (quick, less secure than Secret Manager)
firebase functions:config:set gemini.key="YOUR_GEMINI_KEY"
Then in `index.js` you can read it via `functions.config().gemini.key` OR set process env during deploy.

# Using Secret Manager (recommended for production)
1. gcloud secrets create GEMINI_API_KEY --data-file=-
2. gcloud secrets versions add GEMINI_API_KEY --data-file=key.txt
3. Add IAM binding so Cloud Functions can access the secret or use runtime environment binding.

Local testing (emulator)
1. From repo root: `cd functions && npm install`
2. Start emulator: `firebase emulators:start --only functions`
3. Send a test request (use a valid Firebase ID token for Authorization header):


curl -X POST 'http://localhost:5001/<project-id>/us-central1/geminiProxy' -H 'Authorization: Bearer <FIREBASE_ID_TOKEN>' -H 'Content-Type: application/json' -d '{"transcript":"Hello from emulator"}'

Notes
- Do NOT store GEMINI API keys in the Flutter app or in Firestore/Remote Config.
- Consider adding rate-limiting and auditing on the function to prevent misuse.

Flutter client example (short)
--------------------------------
Use Firebase Auth to get the ID token in Flutter and then call the function endpoint. Do NOT include the Gemini key in the app.

// Pseudocode (Dart):
// final idToken = await FirebaseAuth.instance.currentUser!.getIdToken();
// final resp = await http.post(Uri.parse('https://us-central1-<project-id>.cloudfunctions.net/geminiProxy'),
//   headers: {'Authorization': 'Bearer $idToken', 'Content-Type': 'application/json'},
//   body: jsonEncode({'transcript': transcript, 'instructions': instructions}),
// );

Secret Manager quick note
-------------------------
- Use Secret Manager to store the Gemini API key and grant access to the Functions service account. This avoids embedding the key in env vars or source control.

