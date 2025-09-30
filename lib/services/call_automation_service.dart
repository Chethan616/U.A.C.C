import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/automation_models.dart';
import 'api_config_service.dart';

class CallAutomationService {
  static const _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  final AudioRecorder _recorder = AudioRecorder();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Call Recording & Analysis
  Future<String?> startCallRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        throw Exception('Recording permission denied');
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/call_recording_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: path,
      );

      return path;
    } catch (e) {
      print('Error starting recording: $e');
      return null;
    }
  }

  Future<CallAnalysis?> stopRecordingAndAnalyze() async {
    try {
      final recordingPath = await _recorder.stop();
      if (recordingPath == null) return null;

      // Convert audio to text using device speech recognition or cloud service
      final transcript = await _transcribeAudio(recordingPath);
      if (transcript == null) return null;

      // Analyze transcript with Gemini
      final analysis = await _analyzeTranscriptWithGemini(transcript);
      if (analysis == null) return null;

      // Save to Firestore
      await _saveCallAnalysis(analysis, recordingPath);

      return analysis;
    } catch (e) {
      print('Error analyzing call: $e');
      return null;
    }
  }

  Future<String?> _transcribeAudio(String audioPath) async {
    // For MVP, using mock transcription
    // TODO: Integrate with device STT or cloud speech-to-text
    return '''
    John: Hi Sarah, thanks for taking this call. I wanted to discuss the project timeline.
    Sarah: Of course! I've been reviewing the requirements. When do we need to deliver?
    John: The client is expecting the first milestone by next Friday, December 1st.
    Sarah: That's tight. Can we schedule a team meeting for tomorrow at 2 PM to plan?
    John: Perfect. Also, please remember to update the project documentation.
    Sarah: Will do. I'll send the meeting invite right after this call.
    ''';
  }

  Future<CallAnalysis?> _analyzeTranscriptWithGemini(String transcript) async {
    try {
      final apiKey = await ApiConfigService.getGeminiApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('Gemini API key not found');
      }

      final prompt = '''
      Analyze this call transcript and return ONLY valid JSON with the following structure:
      {
        "summary": "Brief summary of the call",
        "keyPoints": ["Important point 1", "Important point 2"],
        "actionItems": [
          {
            "task": "Task description",
            "assignee": "Person responsible",
            "priority": "High/Medium/Low",
            "dueDate": "2024-12-01"
          }
        ],
        "scheduledMeetings": [
          {
            "title": "Meeting title",
            "date": "2024-12-01",
            "time": "14:00",
            "participants": ["John", "Sarah"]
          }
        ],
        "sentiment": "Positive/Neutral/Negative",
        "followUpRequired": true
      }

      Transcript:
      $transcript
      ''';

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 2048,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['candidates'][0]['content']['parts'][0]['text'];

        // Extract JSON from response
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(text);
        if (jsonMatch != null) {
          final analysisJson = jsonDecode(jsonMatch.group(0)!);
          return CallAnalysis.fromJson(analysisJson);
        }
      }

      return null;
    } catch (e) {
      print('Error analyzing with Gemini: $e');
      return null;
    }
  }

  Future<void> _saveCallAnalysis(
      CallAnalysis analysis, String recordingPath) async {
    try {
      await _firestore.collection('call_analyses').add({
        'timestamp': FieldValue.serverTimestamp(),
        'summary': analysis.summary,
        'keyPoints': analysis.keyPoints,
        'actionItems':
            analysis.actionItems.map((item) => item.toJson()).toList(),
        'scheduledMeetings': analysis.scheduledMeetings
            .map((meeting) => meeting.toJson())
            .toList(),
        'sentiment': analysis.sentiment,
        'followUpRequired': analysis.followUpRequired,
        'recordingPath': recordingPath,
      });
    } catch (e) {
      print('Error saving call analysis: $e');
    }
  }

  // Automatic Task & Meeting Scheduling
  Future<bool> scheduleTasksAndMeetings(CallAnalysis analysis) async {
    try {
      // Schedule meetings in Google Calendar and in-app calendar
      for (final meeting in analysis.scheduledMeetings) {
        await _scheduleGoogleCalendarEvent(meeting);
        await _scheduleInAppEvent(meeting);
      }

      // Create tasks in app
      for (final task in analysis.actionItems) {
        await _createInAppTask(task);
      }

      return true;
    } catch (e) {
      print('Error scheduling tasks and meetings: $e');
      return false;
    }
  }

  Future<void> _scheduleGoogleCalendarEvent(ScheduledMeeting meeting) async {
    // TODO: Implement Google Calendar API integration
    // This would use Google Calendar API to create events
    print('Scheduling Google Calendar event: ${meeting.title}');
  }

  Future<void> _scheduleInAppEvent(ScheduledMeeting meeting) async {
    try {
      await _firestore.collection('calendar_events').add({
        'title': meeting.title,
        'date': meeting.date,
        'time': meeting.time,
        'participants': meeting.participants,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'call_analysis',
      });
    } catch (e) {
      print('Error creating in-app event: $e');
    }
  }

  Future<void> _createInAppTask(ActionItem task) async {
    try {
      await _firestore.collection('tasks').add({
        'task': task.task,
        'assignee': task.assignee,
        'priority': task.priority,
        'dueDate': task.dueDate,
        'completed': false,
        'createdAt': FieldValue.serverTimestamp(),
        'source': 'call_analysis',
      });
    } catch (e) {
      print('Error creating task: $e');
    }
  }

  // Cleanup
  void dispose() {
    _recorder.dispose();
  }
}
