ML Kit / On-Device Speech Integration (Flutter)

Goal
----
Perform speech-to-text on the device (Android/iOS) and send only the resulting transcript to the server function. Avoid sending raw audio to protect privacy and reduce network usage.

Options
-------
- Android: ML Kit on-device Speech (Speech-to-Text) or Android SpeechRecognizer API.
- iOS: Speech framework (SFSpeechRecognizer) for on-device where available.
- Cross-platform: Use platform channels or use packages like `speech_to_text` (works offline depending on device) or `flutter_speech`.

Recommended Flutter package (simple integration)
- `speech_to_text` (https://pub.dev/packages/speech_to_text) — works cross-platform and falls back to platform STT.

Basic flow (Dart)
-----------------
1. Request microphone and speech permissions.
2. Start listening and collect partial/final results.
3. When final transcript obtained, call Firebase Function with ID token.

Pseudocode (Dart)
------------------
// ...existing code...
// import 'package:speech_to_text/speech_to_text.dart' as stt;

final stt.SpeechToText _speech = stt.SpeechToText();

Future<void> initSpeech() async {
  bool available = await _speech.initialize();
  if (!available) throw 'Speech not available on this device';
}

Future<void> startListening() async {
  await _speech.listen(onResult: (result) {
    if (result.finalResult) {
      final transcript = result.recognizedWords;
      // send transcript to function (see functions/README.md)
    }
  });
}

Privacy & performance notes
---------------------------
- Prefer on-device models when available. If using cloud STT for better accuracy, ensure consent and send only audio when necessary.
- Batch or debounce short pauses to avoid spamming the function.
