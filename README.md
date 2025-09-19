# U.A.C.C  
## Unified AI Communication Companion  
*Revolutionizing mobile communication with AI – Samsung PRISM project*  

---

## Overview
The **Unified AI Communication Companion (U.A.C.C.)** is a **multi-platform communication intelligence system**.  
It integrates **real-time speech processing**, **notification orchestration**, and a **unified task dashboard** into one secure workflow.  

Core principle: **Reduce cognitive overload** by converting unstructured communication (calls + notifications) into **actionable, prioritized data streams**.  

Target device: **Samsung Android ecosystem** (PRISM research program).  

---

## Functional Capabilities
### 1. AI Call Companion
- **Input:** Call audio (via Samsung Speech SDK / Android Telephony APIs).  
- **Processing:**
  - On-device ASR (Whisper, TensorFlow Lite model) or offloaded to n8n pipeline.  
  - Post-processing with transformer summarizer (LLaMA/Mistral/BERT).  
  - Contextual semantic search → "What was said in my last meeting?"  
- **Output:** Transcript JSON + summary string + extracted `actions[]`.  

### 2. Notification Companion
- **Input:** Android Notification Listener Service stream.  
- **Processing:**  
  - Rule-based + ML priority classification.  
  - Deduplication + grouping.  
  - Summarization pipeline (n8n + LLM).  
- **Output:** Prioritized notification digests.  

### 3. Unified Dashboard
- **Mobile (Flutter):**
  - Card-based summaries (calls, notifications, calendar).  
  - Offline cache + Firestore sync.  
- **Web (Next.js):**
  - Historical digests + search.  
  - Task list & calendar integration.  
  - Visualization widgets (charts, heatmaps).  

### 4. Security & Privacy
- **On-device:** Initial ASR + priority classification → reduces external data exposure.  
- **Transport:** HTTPS + Firebase Auth tokens.  
- **Storage:** Firestore per-user namespace + security rules.  
- **E2E Encryption (optional):** Audio blob encryption before upload.  

---

## System Architecture

```text
+--------------------+         +--------------------+         +--------------------+
|   Flutter Client   |         |        n8n         |         |     Next.js Web    |
| (Samsung Device)   |         | (Workflow Engine)  |         |     Dashboard      |
|--------------------|         |--------------------|         |--------------------|
| - Call capture     | POST -->| - Webhook ingest   |---> API | - Summaries view   |
| - Notif capture    |         | - ASR (Whisper)    |         | - Task mgmt        |
| - Local TFLite     |         | - Summarizer (LLM) |         | - Analytics        |
| - Push UI          |         | - Action extractor |         | - Calendar sync    |
+--------------------+         +--------------------+         +--------------------+
          |                                |                               |
          v                                v                               v
                        +-----------------------------------+
                        |             Firebase              |
                        |  Auth | Firestore | Storage | FCM |
                        +-----------------------------------+

```
## Deployment Targets

Mobile (Flutter): Android APK → Samsung Galaxy devices.

Web (Next.js): Vercel deployment → auto CI/CD from GitHub.

Automation (n8n): Docker Compose / n8n.cloud → connected via service account.

Firebase: Managed (Auth, Firestore, Storage, FCM)
