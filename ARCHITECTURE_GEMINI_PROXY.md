Gemini Proxy Architecture (on-device ASR + server-side LLM)

Overview
--------
This repo uses an on-device or on-edge ASR (ML Kit, platform SDK) to convert audio to text locally on the user's device. The app then sends the transcript (not audio, and not API keys) to a secure Firebase Function which calls Gemini 2.0 Flash and returns structured JSON.

Flow
----
1. User records audio on device (ML Kit or other SDK).
2. Device performs speech-to-text locally and produces `transcript`.
3. Flutter app gets Firebase ID token after user signs in.
4. Flutter POSTs {transcript,instructions?} to `https://us-central1-<project>.cloudfunctions.net/geminiProxy` with Authorization: Bearer <ID_TOKEN>.
5. Function verifies ID token, reads Gemini API key from Secret Manager or env, calls Gemini API, and returns structured JSON (summary, tasks, events).
6. Flutter receives JSON and updates UI or writes to Firestore as needed.

Security notes
--------------
- Do not store long-lived API keys in client apps.
- Use Secret Manager for production secrets; set minimal IAM permissions.
- Add rate-limiting, logging, and monitoring to the function to detect abuse.

Next steps
----------
- Implement ML Kit / platform ASR integration (Android/iOS) in Flutter.
- Harden the Function: add rate-limiting, request validation, unit tests.
- Create Flutter client examples and end-to-end tests using emulator.
