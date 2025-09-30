import 'package:flutter/services.dart';
import 'dart:async';

class LiveTranscriptService {
  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/live_transcript');

  static StreamController<String>? _transcriptController;

  /// Get stream of live transcript updates
  static Stream<String> get transcriptStream {
    _transcriptController ??= StreamController<String>.broadcast();
    return _transcriptController!.stream;
  }

  /// Start live transcript service (will show Zomato-style capsule)
  static Future<bool> startLiveTranscript() async {
    try {
      final bool success = await _channel.invokeMethod('startLiveTranscript');
      return success;
    } catch (e) {
      print('Error starting live transcript: $e');
      return false;
    }
  }

  /// Update transcript with new text (from Flutter speech recognition or external source)
  static Future<bool> updateTranscript(String text) async {
    try {
      final bool success = await _channel.invokeMethod('updateTranscript', {
        'text': text,
      });

      // Also emit to local stream
      _transcriptController?.add(text);

      return success;
    } catch (e) {
      print('Error updating transcript: $e');
      return false;
    }
  }

  /// Stop live transcript service
  static Future<bool> stopLiveTranscript() async {
    try {
      final bool success = await _channel.invokeMethod('stopLiveTranscript');
      return success;
    } catch (e) {
      print('Error stopping live transcript: $e');
      return false;
    }
  }

  /// Check if transcript service is currently active
  static Future<bool> isTranscriptActive() async {
    try {
      final bool isActive = await _channel.invokeMethod('isTranscriptActive');
      return isActive;
    } catch (e) {
      print('Error checking transcript status: $e');
      return false;
    }
  }

  /// Dispose resources
  static void dispose() {
    _transcriptController?.close();
    _transcriptController = null;
  }
}

/// Model class for transcript entries
class TranscriptEntry {
  final String text;
  final DateTime timestamp;
  final String speaker;

  TranscriptEntry({
    required this.text,
    required this.timestamp,
    this.speaker = 'Unknown',
  });

  factory TranscriptEntry.fromJson(Map<String, dynamic> json) {
    return TranscriptEntry(
      text: json['text'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      speaker: json['speaker'] ?? 'Unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'speaker': speaker,
    };
  }
}

/// Live transcript manager with additional features
class LiveTranscriptManager {
  static final List<TranscriptEntry> _transcriptHistory = [];
  static bool _isRecording = false;

  static List<TranscriptEntry> get transcriptHistory =>
      List.unmodifiable(_transcriptHistory);

  static bool get isRecording => _isRecording;

  /// Start live transcript with Zomato-style live activity
  static Future<bool> startRecording() async {
    if (_isRecording) return true;

    final success = await LiveTranscriptService.startLiveTranscript();
    if (success) {
      _isRecording = true;
      _transcriptHistory.clear();
      print('Live transcript started with capsule notification');
    }
    return success;
  }

  /// Add new transcript line
  static Future<void> addTranscriptLine(String text,
      {String speaker = 'Unknown'}) async {
    if (!_isRecording) return;

    final entry = TranscriptEntry(
      text: text,
      timestamp: DateTime.now(),
      speaker: speaker,
    );

    _transcriptHistory.add(entry);

    // Update the live activity notification
    await LiveTranscriptService.updateTranscript(text);

    print('Added transcript: ${entry.text}');
  }

  /// Stop recording and live activity
  static Future<bool> stopRecording() async {
    if (!_isRecording) return true;

    final success = await LiveTranscriptService.stopLiveTranscript();
    if (success) {
      _isRecording = false;
      print('Live transcript stopped - capsule notification removed');
    }
    return success;
  }

  /// Get formatted transcript for export
  static String getFormattedTranscript() {
    if (_transcriptHistory.isEmpty) return 'No transcript available';

    final buffer = StringBuffer();
    buffer.writeln('Call Transcript - ${DateTime.now().toIso8601String()}');
    buffer.writeln('=' * 50);
    buffer.writeln();

    for (final entry in _transcriptHistory) {
      final timeStr = '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
          '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
          '${entry.timestamp.second.toString().padLeft(2, '0')}';

      buffer.writeln('[$timeStr] ${entry.speaker}: ${entry.text}');
    }

    return buffer.toString();
  }

  /// Clear transcript history
  static void clearHistory() {
    _transcriptHistory.clear();
  }
}
