## PLEASE FOLLOW SETUP.MD AND GOOGLE_WORKSPACE_SEUP.MD AND THIS FILE AND ALSO REQUIREMENTS.TXT
# Web - https://github.com/jayashish05/UACC

# Android
# U.A.C.C (Cairo)
## Unified AI Communication Companion  
*Revolutionizing mobile communication with on‑device + Firebase intelligence – Samsung PRISM project*

---
## Overview
The **Unified AI Communication Companion (U.A.C.C.)** is a **privacy-aware Android AI assistant** that unifies:
- Real‑time call understanding
- Intelligent notification triage
- Action & task surfacing via expressive widgets

Core principle: **Reduce cognitive overload** by transforming volatile streams (calls, notifications, schedules) into **concise, actionable context** that lives locally first, and syncs securely to Firebase.

Target: **Samsung / Android ecosystem** (optimized for AMOLED + low power overlays).

---
## Functional Capabilities
### 1. AI Call Companion
- **Input:** Live call audio hooks / microphone session (user authorized)
- **Pipeline:** On‑device ASR (Whisper / TFLite) → semantic condensation → key actions extraction
- **Output:** Structured transcript + bullet summary + `actions[]`
- **Enhancement (optional):** Cloud `geminiProxy` function for higher‑order synthesis when network available (Gemini model). No other LLM providers are embedded.

### 2. Notification Intelligence
- **Input:** Android Notification Listener stream
- **Processing:** Rule + lightweight ML scoring → grouping → priority labeling
- **Output:** Digest feed + suppression of low‑signal noise

### 3. Expressive Widgets & Surfaces
- `CookieCalendarWidget` (AMOLED adaptive, grayscale energy frugal)
- `TasksWidget` (dynamic ticket container shape, real‑time sync)
- Dynamic overlay ("island" style) for ephemeral call / task state cues

### 4. Privacy & Security
- **Local First:** Classification + initial ASR remains on device
- **Selective Sync:** Only distilled artifacts (summary, task objects) persisted to Firestore
- **Transport:** HTTPS + Firebase Auth
- **Isolation:** Per‑user Firestore namespace; no multi‑tenant leakage
- **Crash & Metrics:** Crashlytics + Analytics (minimal PII)

---
## Current Architecture (Simplified)
```text
 ┌──────────────────────────────────────────────────────────┐
 |                      Android (Flutter)                   |
 |  UI (Riverpod/Provider)  •  Widgets (Glance)  • Overlays |
 |  ──────────────────────────────────────────────────────  |
 |  Local ASR (TFLite) → Summarizer → Action Extractor      |
 |  Notification Listener → Priority Model / Rules          |
 |  Storage Cache (SharedPreferences / Secure Storage)      |
 └──────────────┬───────────────────────────────┬──────────┘
                │                               │
        Firestore (structured tasks)     FCM (reactive refresh)
                │                               │
        Cloud Function: geminiProxy  (Gemini augmentation / fallback)
                │
        (Secret Manager / Admin SDK auto credentials; GEMINI_API_KEY server-only)
```

---
## Technology Stack
| Layer | Technology |
|-------|------------|
| Mobile Core | Flutter (Dart 3.6) |
| Native Enhancements | Kotlin (Glance widgets, overlay services) |
| State Mgmt | Riverpod + Provider hybrid |
| AI (on device) | Whisper/TFLite placeholder integration (future) |
| Cloud Augmentation | Firebase Cloud Function (`geminiProxy`, Node.js 18) |
| Backend Services | Firebase Auth, Firestore, Storage, FCM, Crashlytics, Analytics |
| Assets | Lottie, SVG, custom fonts, grayscale adaptive theming |

---
## Repository Structure (Key)
```
lib/                # Flutter application code
android/            # Native Android layer (widgets, services, platform code)
functions/          # Node.js Cloud Function (Gemini proxy)
assets/             # Images, animations, fonts, sounds
firebase.json       # Firebase multi-platform + functions config
SETUP.md            # Full environment + deployment guide
requirements.txt    # Optional Python tooling (not required for runtime)
```

---
## Cloud Function: geminiProxy
Purpose: Optional augmentation (advanced summarization / semantic expansion) while keeping primary UX functional offline.

Minimal pattern:
```js
const functions = require('firebase-functions');
const admin = require('firebase-admin');
admin.initializeApp();

exports.geminiProxy = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Login required');
  return { refined: `Summary(v1): ${data?.draft?.slice(0,120)}...` };
});
```
Secrets: `GEMINI_API_KEY` is never embedded in the client; only loaded via Secret Manager on the server.

---
## Configuration & Setup
See `SETUP.md` for: prerequisites, Firebase activation, secrets strategy, running & building, CI suggestions.

> **Crashlytics & offline builds:** Release builds try to upload a mapping file. If you're offline or behind a firewall, set `SKIP_CRASHLYTICS_UPLOAD=true` (or pass `-PskipCrashlyticsUpload`) before running `flutter build apk --release` so the build can finish, then unset it for CI/production.

Fast start:
```powershell
flutter pub get
flutter run --debug
```

---
## Theming & AMOLED Strategy
- Widgets and overlays use near‑black `#121212` base + restrained grayscale spectrum
- Minimizes OLED power + visual noise
- Accent color reserved for semantic emphasis (task status, active capture state)

---
## Roadmap (Working)
- On‑device summarizer refinement pipeline
- Offline embeddings for semantic recall (vector store local)
- Adaptive priority model (temporal + behavioral signals)
- Accessibility speech command palette
- End‑to‑end encrypted transcript blob option

---
## Contributing
1. Branch: `feature/<slug>`
2. Run: `flutter analyze && flutter test`
3. Provide screenshot / screen recording for UI changes
4. Avoid committing service account / secret files (enforced via `.gitignore`)

---
## Security Notes
- Service account JSONs are ignored; if exposed rotate immediately
- Only distilled structured data leaves device by default
- GEMINI_API_KEY accessed only within Cloud Function runtime

---
## License / Attribution
Samsung PRISM research context + third‑party OSS under respective licenses.

---
## Support
Open an issue with: environment, reproduction steps, logs (sanitized). For sensitive disclosures, use private channel.

---
*Focused. Local-first. Assistive.*
