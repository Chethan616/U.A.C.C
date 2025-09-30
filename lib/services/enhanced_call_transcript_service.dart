import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'dart:async';

/// Enhanced service for call transcript with speaker identification and color coding
class EnhancedCallTranscriptService {
  static final stt.SpeechToText _speech = stt.SpeechToText();
  static StreamController<TranscriptMessage>? _transcriptController;
  static bool _isListening = false;
  static bool _isInCall = false;
  static final List<TranscriptMessage> _transcriptHistory = [];

  /// Get stream of transcript messages with speaker identification
  static Stream<TranscriptMessage> get transcriptStream {
    _transcriptController ??= StreamController<TranscriptMessage>.broadcast();
    return _transcriptController!.stream;
  }

  /// Start call transcript with speaker detection
  static Future<bool> startCallTranscript({bool isIncomingCall = false}) async {
    try {
      print('🎤 Starting call transcript (isIncomingCall: $isIncomingCall)');

      // Initialize speech recognition optimized for call audio
      if (!_speech.isAvailable) {
        print('🎤 Initializing speech recognition for call audio...');
        final initialized = await _speech.initialize(
          onStatus: (status) {
            print('Speech status: $status');
            if (status == 'listening') {
              _isListening = true;
            } else if (status == 'notListening') {
              _isListening = false;
              // Auto-restart during calls if recognition stops
              if (_isInCall) {
                Future.delayed(Duration(milliseconds: 500), () {
                  if (_isInCall && !_isListening) _startListening();
                });
              }
            } else if (status == 'done' && _isInCall) {
              // Restart listening for continuous transcription during calls
              Future.delayed(Duration(milliseconds: 300), () {
                if (_isInCall) _startListening();
              });
            }
          },
          onError: (error) {
            print('Speech error: $error');
            _isListening = false;
            // Auto-restart on recoverable errors during calls
            if (_isInCall &&
                !error.errorMsg.toLowerCase().contains('no match')) {
              Future.delayed(Duration(seconds: 1), () {
                if (_isInCall) _startListening();
              });
            }
          },
          debugLogging: true, // Enable detailed logging for call debugging
        );

        if (!initialized) {
          throw Exception('Speech recognition not available');
        }
        print('✅ Speech recognition initialized for call transcription');
      }

      _isInCall = true;
      _transcriptHistory.clear();

      // Start call transcript in Android Dynamic Island only
      print('Starting Dynamic Island transcript...');
      final methodChannel =
          const MethodChannel('com.example.uacc/call_overlay');
      await methodChannel.invokeMethod('startCallTranscript');
      print('Dynamic Island transcript started');

      // Start listening for speech
      await _startListening();

      // Show initial system message
      await addTranscriptMessage(
          text: 'Call transcript started - Listening...',
          speakerType: SpeakerType.system);

      print('🎤 Call transcript setup completed successfully');
      return true;
    } catch (e) {
      print('❌ Error starting call transcript: $e');
      return false;
    }
  }

  /// Stop call transcript
  static Future<void> stopCallTranscript() async {
    try {
      _isInCall = false;
      await _stopListening();

      // Clear transcript and stop call transcript in Android Dynamic Island
      final methodChannel =
          const MethodChannel('com.example.uacc/call_overlay');

      // First clear the transcript content
      await methodChannel.invokeMethod('clearTranscript');

      // Then stop the transcript service (which removes the plugin)
      await methodChannel.invokeMethod('stopCallTranscript');

      // Send system message about transcript ending
      await addTranscriptMessage(
          text: 'Call transcript ended', speakerType: SpeakerType.system);

      print('🏝️ Dynamic Island transcript cleared and stopped');
    } catch (e) {
      print('Error stopping call transcript: $e');
    }
  }

  /// Start continuous listening for speech
  static Future<void> _startListening() async {
    if (!_speech.isAvailable || _isListening) {
      print(
          'Speech not available or already listening: available=${_speech.isAvailable}, listening=$_isListening');
      return;
    }

    print('🎤 Starting optimized speech recognition for call...');
    try {
      await _speech.listen(
        onResult: (result) {
          print(
              'Speech result: ${result.recognizedWords} (final: ${result.finalResult})');
          if (result.recognizedWords.isNotEmpty) {
            _handleSpeechResult(result.recognizedWords, result.finalResult);
          }
        },
        onSoundLevelChange: (level) {
          // Monitor sound level to detect speech activity during calls
          if (level > 0.1) {
            print('🎵 Audio detected (level: $level)');
          }
        },
        listenFor: const Duration(minutes: 45), // Extended for long calls
        pauseFor: const Duration(
            milliseconds: 1000), // Optimized pause for call speech
        partialResults: true,
        cancelOnError: false,
        listenMode:
            stt.ListenMode.dictation, // Best for continuous natural speech
        localeId: "en-US", // Explicit locale for consistency
      );
      print('✅ Optimized speech recognition active for call audio');
    } catch (e) {
      print('Error starting speech recognition: $e');
    }
  }

  /// Stop listening
  static Future<void> _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Handle speech recognition results
  static Future<void> _handleSpeechResult(String text, bool isFinal) async {
    if (!_isInCall || text.trim().isEmpty) return;

    // Determine speaker type (this is a simplified detection - in reality you'd use more sophisticated methods)
    final speakerType = await _detectSpeaker(text);

    final transcriptMessage = TranscriptMessage(
      text: text.trim(),
      speaker: _getSpeakerName(speakerType),
      timestamp: DateTime.now().toIso8601String(),
      isUser: speakerType == SpeakerType.outgoing,
      speakerType: speakerType,
      isFinal: isFinal,
    );

    // Add to history if final
    if (isFinal) {
      _transcriptHistory.add(transcriptMessage);
    }

    // Emit to stream
    _transcriptController?.add(transcriptMessage);

    // Update dynamic island with color-coded text
    await _updateDynamicIslandWithMessage(transcriptMessage);
  }

  /// Simple speaker detection (in production, you'd use voice recognition or other methods)
  static Future<SpeakerType> _detectSpeaker(String text) async {
    // This is a placeholder implementation
    // In reality, you'd use:
    // 1. Voice recognition/biometrics
    // 2. Phone state detection (microphone vs speaker)
    // 3. Call direction analysis
    // 4. Machine learning models

    // For now, we'll use simple heuristics or assume outgoing
    // You could also use call state to determine direction
    return SpeakerType.outgoing; // Default to user speaking
  }

  /// Get speaker display name
  static String _getSpeakerName(SpeakerType speakerType) {
    switch (speakerType) {
      case SpeakerType.incoming:
        return 'Caller';
      case SpeakerType.outgoing:
        return 'You';
      case SpeakerType.system:
        return 'System';
    }
  }

  /// Update dynamic island with color-coded transcript message
  static Future<void> _updateDynamicIslandWithMessage(
      TranscriptMessage message) async {
    try {
      // Send transcript message to Android Dynamic Island with speaker type
      final methodChannel =
          const MethodChannel('com.example.uacc/call_overlay');
      await methodChannel.invokeMethod('addTranscriptMessage', {
        'text': message.text,
        'speakerType': message.speakerType.name.toUpperCase(),
        'isPartial': !message.isFinal,
      });

      // Note: Only using Android Dynamic Island now, no Flutter overlays
    } catch (e) {
      print('Error updating dynamic island with message: $e');
    }
  }

  /// Manually add a transcript message (for testing or external input)
  static Future<void> addTranscriptMessage({
    required String text,
    required SpeakerType speakerType,
    bool isFinal = true,
  }) async {
    print(
        '💬 Adding transcript message: [$speakerType] $text (final: $isFinal)');

    final message = TranscriptMessage(
      text: text,
      speaker: _getSpeakerName(speakerType),
      timestamp: DateTime.now().toIso8601String(),
      isUser: speakerType == SpeakerType.outgoing,
      speakerType: speakerType,
      isFinal: isFinal,
    );

    if (isFinal) {
      _transcriptHistory.add(message);
    }

    _transcriptController?.add(message);
    await _updateDynamicIslandWithMessage(message);
    print('💬 Transcript message sent to Dynamic Island');
  }

  /// Get full transcript history
  static List<TranscriptMessage> get transcriptHistory =>
      List.unmodifiable(_transcriptHistory);

  /// Get formatted transcript for export
  static String getFormattedTranscript() {
    if (_transcriptHistory.isEmpty) return 'No transcript available';

    final buffer = StringBuffer();
    buffer.writeln('Call Transcript - ${DateTime.now().toIso8601String()}');
    buffer.writeln('=' * 60);
    buffer.writeln();

    for (final message in _transcriptHistory) {
      final timestamp = DateTime.parse(message.timestamp);
      final timeStr = '${timestamp.hour.toString().padLeft(2, '0')}:'
          '${timestamp.minute.toString().padLeft(2, '0')}:'
          '${timestamp.second.toString().padLeft(2, '0')}';

      buffer.writeln('[$timeStr] ${message.speaker}: ${message.text}');
    }

    return buffer.toString();
  }

  /// Clear transcript history
  static void clearHistory() {
    _transcriptHistory.clear();
  }

  /// Check if currently in a call
  static bool get isInCall => _isInCall;

  /// Check if currently listening
  static bool get isListening => _isListening;

  /// Dispose resources
  static void dispose() {
    _transcriptController?.close();
    _transcriptController = null;
    stopCallTranscript();
  }
}

/// Enhanced transcript message with speaker identification
class TranscriptMessage {
  final String text;
  final String speaker;
  final String timestamp;
  final bool isUser;
  final SpeakerType speakerType;
  final bool isFinal;

  const TranscriptMessage({
    required this.text,
    required this.speaker,
    required this.timestamp,
    required this.isUser,
    required this.speakerType,
    this.isFinal = true,
  });

  factory TranscriptMessage.fromJson(Map<String, dynamic> json) {
    return TranscriptMessage(
      text: json['text'] ?? '',
      speaker: json['speaker'] ?? 'Unknown',
      timestamp: json['timestamp'] ?? DateTime.now().toIso8601String(),
      isUser: json['isUser'] ?? false,
      speakerType: SpeakerType.values.firstWhere(
        (type) => type.toString() == json['speakerType'],
        orElse: () => SpeakerType.outgoing,
      ),
      isFinal: json['isFinal'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'speaker': speaker,
      'timestamp': timestamp,
      'isUser': isUser,
      'speakerType': speakerType.toString(),
      'isFinal': isFinal,
    };
  }
}

/// Speaker types for color coding
enum SpeakerType {
  incoming, // Blue - incoming caller
  outgoing, // White - user/outgoing
  system, // Gray - system messages
}
