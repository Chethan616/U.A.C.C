import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service for handling speech-to-text and Gemini API integration
class GeminiSpeechService {
  static const String _functionUrl =
      'https://us-central1-uacc-uacc.cloudfunctions.net/geminiProxy';

  final stt.SpeechToText _speech = stt.SpeechToText();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isListening = false;
  String _lastTranscript = '';

  // Getters
  bool get isListening => _isListening;
  String get lastTranscript => _lastTranscript;

  /// Initialize speech recognition
  Future<bool> initializeSpeech() async {
    try {
      bool available = await _speech.initialize(
        onStatus: (status) => print('Speech status: $status'),
        onError: (error) => print('Speech error: $error'),
        debugLogging: true,
      );

      if (!available) {
        throw Exception('Speech recognition not available on this device');
      }

      return true;
    } catch (e) {
      print('Failed to initialize speech: $e');
      return false;
    }
  }

  /// Start listening for speech
  Future<void> startListening({
    Function(String)? onPartialResult,
    Function(String)? onFinalResult,
    Function(String)? onError,
  }) async {
    if (!_speech.isAvailable) {
      onError?.call('Speech recognition not initialized');
      return;
    }

    if (_isListening) {
      await stopListening();
    }

    _isListening = true;
    _lastTranscript = '';

    await _speech.listen(
      onResult: (result) {
        _lastTranscript = result.recognizedWords;

        if (result.finalResult) {
          onFinalResult?.call(_lastTranscript);
        } else {
          onPartialResult?.call(_lastTranscript);
        }
      },
      listenFor: const Duration(minutes: 5),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      listenMode: stt.ListenMode.confirmation,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
    }
  }

  /// Process transcript with Gemini via Firebase Function
  Future<GeminiResponse> processTranscript(
    String transcript, {
    String? instructions,
  }) async {
    try {
      // Validate inputs
      if (transcript.trim().isEmpty) {
        throw Exception('Transcript cannot be empty');
      }

      if (transcript.length > 10000) {
        throw Exception('Transcript too long (max 10,000 characters)');
      }

      // Get current user and ID token
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final idToken = await user.getIdToken();

      // Prepare request
      final requestBody = {
        'transcript': transcript,
        if (instructions != null) 'instructions': instructions,
      };

      print('Sending request to Gemini proxy...');

      // Call Firebase Function
      final response = await http
          .post(
            Uri.parse(_functionUrl),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 60));

      // Handle response
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          return GeminiResponse.fromJson(responseData['data']);
        } else {
          throw Exception('Invalid response format from server');
        }
      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please try again in a minute.');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed. Please sign in again.');
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(
            errorData['error'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error processing transcript: $e');
      rethrow;
    }
  }

  /// Record audio and process in one call
  Future<GeminiResponse> recordAndProcess({
    String? instructions,
    Duration maxDuration = const Duration(minutes: 2),
    Function(String)? onTranscriptUpdate,
  }) async {
    final completer = Completer<GeminiResponse>();
    String finalTranscript = '';

    try {
      // Start listening
      await startListening(
        onPartialResult: (transcript) {
          onTranscriptUpdate?.call(transcript);
        },
        onFinalResult: (transcript) async {
          finalTranscript = transcript;

          if (finalTranscript.trim().isNotEmpty) {
            try {
              final result = await processTranscript(
                finalTranscript,
                instructions: instructions,
              );
              completer.complete(result);
            } catch (e) {
              completer.completeError(e);
            }
          } else {
            completer.completeError(Exception('No speech detected'));
          }
        },
        onError: (error) {
          completer
              .completeError(Exception('Speech recognition error: $error'));
        },
      );

      // Set timeout
      Timer(maxDuration, () {
        if (!completer.isCompleted) {
          stopListening();
          if (finalTranscript.trim().isNotEmpty) {
            processTranscript(finalTranscript, instructions: instructions)
                .then(completer.complete)
                .catchError(completer.completeError);
          } else {
            completer.completeError(
                Exception('Recording timeout - no speech detected'));
          }
        }
      });

      return await completer.future;
    } catch (e) {
      await stopListening();
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    stopListening();
  }
}

/// Data model for Gemini API response
class GeminiResponse {
  final String summary;
  final List<GeminiTask> tasks;
  final List<GeminiEvent> events;
  final String? rawResponse;

  GeminiResponse({
    required this.summary,
    required this.tasks,
    required this.events,
    this.rawResponse,
  });

  factory GeminiResponse.fromJson(Map<String, dynamic> json) {
    return GeminiResponse(
      summary: json['summary']?.toString() ?? 'No summary available',
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((task) => GeminiTask.fromJson(task))
              .toList() ??
          [],
      events: (json['events'] as List<dynamic>?)
              ?.map((event) => GeminiEvent.fromJson(event))
              .toList() ??
          [],
      rawResponse: json['raw']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'events': events.map((event) => event.toJson()).toList(),
      if (rawResponse != null) 'raw': rawResponse,
    };
  }
}

/// Data model for a task extracted from speech
class GeminiTask {
  final String title;
  final DateTime? dueDate;

  GeminiTask({
    required this.title,
    this.dueDate,
  });

  factory GeminiTask.fromJson(Map<String, dynamic> json) {
    DateTime? due;
    if (json['due'] != null && json['due'].toString() != 'null') {
      try {
        due = DateTime.parse(json['due'].toString());
      } catch (e) {
        print('Failed to parse due date: ${json['due']}');
      }
    }

    return GeminiTask(
      title: json['title']?.toString() ?? 'Untitled task',
      dueDate: due,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'due': dueDate?.toIso8601String(),
    };
  }
}

/// Data model for a calendar event extracted from speech
class GeminiEvent {
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;

  GeminiEvent({
    required this.title,
    this.startTime,
    this.endTime,
    this.description,
  });

  factory GeminiEvent.fromJson(Map<String, dynamic> json) {
    DateTime? start;
    DateTime? end;

    if (json['start'] != null) {
      try {
        start = DateTime.parse(json['start'].toString());
      } catch (e) {
        print('Failed to parse start time: ${json['start']}');
      }
    }

    if (json['end'] != null) {
      try {
        end = DateTime.parse(json['end'].toString());
      } catch (e) {
        print('Failed to parse end time: ${json['end']}');
      }
    }

    return GeminiEvent(
      title: json['title']?.toString() ?? 'Untitled event',
      startTime: start,
      endTime: end,
      description: json['description']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (startTime != null) 'start': startTime!.toIso8601String(),
      if (endTime != null) 'end': endTime!.toIso8601String(),
      if (description != null) 'description': description,
    };
  }
}

/// Exception for Gemini service errors
class GeminiServiceException implements Exception {
  final String message;
  final String? code;

  GeminiServiceException(this.message, {this.code});

  @override
  String toString() =>
      'GeminiServiceException: $message${code != null ? ' (Code: $code)' : ''}';
}
