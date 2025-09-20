import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/automation_models.dart';
import 'api_config_service.dart';

class NotificationAutomationService {
  static const _storage = FlutterSecureStorage();
  static const _geminiApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';
  static const _platform = MethodChannel('com.uacc.notification_automation');

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Initialize notification automation
  Future<bool> initialize() async {
    try {
      // Initialize local notifications
      const initializationSettingsAndroid =
          AndroidInitializationSettings('@drawable/ic_notification');
      const initializationSettingsIOS = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await _localNotifications.initialize(initializationSettings);

      // Set up notification listener for Android
      _platform.setMethodCallHandler(_handleNotificationInterception);

      return true;
    } catch (e) {
      print('Error initializing notification automation: $e');
      return false;
    }
  }

  // Handle intercepted notifications from messaging apps
  Future<void> _handleNotificationInterception(MethodCall call) async {
    if (call.method == 'onNotificationReceived') {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(call.arguments);
      await _processIncomingNotification(data);
    }
  }

  // Process and analyze incoming notifications
  Future<void> _processIncomingNotification(
      Map<String, dynamic> notificationData) async {
    try {
      final packageName = notificationData['packageName'] as String?;
      final title = notificationData['title'] as String?;
      final text = notificationData['text'] as String?;
      final timestamp = notificationData['timestamp'] as int?;

      if (!_isMessagingApp(packageName)) return;

      // Analyze notification with Gemini
      final analysis =
          await _analyzeNotificationWithGemini(title, text, packageName);
      if (analysis == null) return;

      // Generate smart reply if needed
      if (analysis.shouldReply) {
        final reply = await _generateSmartReply(text, analysis);
        if (reply != null) {
          await _sendReplyToApp(packageName, reply);
        }
      }

      // Create summary if important
      if (analysis.isImportant) {
        await _createNotificationSummary(analysis, notificationData);
      }

      // Schedule task if action required
      if (analysis.actionRequired) {
        await _scheduleTaskFromNotification(analysis);
      }

      // Save to history
      await _saveNotificationAnalysis(notificationData, analysis);
    } catch (e) {
      print('Error processing notification: $e');
    }
  }

  bool _isMessagingApp(String? packageName) {
    const messagingApps = [
      'com.whatsapp',
      'com.telegram',
      'com.facebook.orca', // Messenger
      'com.instagram.android',
      'com.slack',
      'com.discord',
      'com.microsoft.teams',
      'com.google.android.apps.messaging', // Messages
    ];
    return packageName != null && messagingApps.contains(packageName);
  }

  Future<NotificationAnalysis?> _analyzeNotificationWithGemini(
      String? title, String? text, String? packageName) async {
    try {
      final apiKey = await _storage.read(key: 'gemini_api_key');
      if (apiKey == null) return null;

      final prompt = '''
      Analyze this notification from a messaging app and return ONLY valid JSON:
      {
        "isImportant": boolean,
        "urgencyLevel": "High/Medium/Low",
        "shouldReply": boolean,
        "actionRequired": boolean,
        "category": "Meeting/Task/Social/Work/Emergency/Spam",
        "sentiment": "Positive/Neutral/Negative/Urgent",
        "keyTopics": ["topic1", "topic2"],
        "suggestedAction": "Reply/Schedule/Ignore/Archive",
        "summary": "Brief summary of the message",
        "replyTone": "Professional/Casual/Friendly/Formal"
      }

      App: $packageName
      Title: $title
      Message: $text
      ''';

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.2,
            'maxOutputTokens': 1024,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseText =
            data['candidates'][0]['content']['parts'][0]['text'];

        final jsonMatch =
            RegExp(r'\{.*\}', dotAll: true).firstMatch(responseText);
        if (jsonMatch != null) {
          final analysisJson = jsonDecode(jsonMatch.group(0)!);
          return NotificationAnalysis.fromJson(analysisJson);
        }
      }

      return null;
    } catch (e) {
      print('Error analyzing notification with Gemini: $e');
      return null;
    }
  }

  Future<String?> _generateSmartReply(
      String? originalMessage, NotificationAnalysis analysis) async {
    try {
      final apiKey = await _storage.read(key: 'gemini_api_key');
      if (apiKey == null) return null;

      final prompt = '''
      Generate a ${analysis.replyTone.toLowerCase()} reply to this message. Keep it concise and appropriate.
      Return ONLY the reply text, no quotes or formatting.

      Original message: $originalMessage
      Category: ${analysis.category}
      Tone: ${analysis.replyTone}
      ''';

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 150,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text']?.trim();
      }

      return null;
    } catch (e) {
      print('Error generating smart reply: $e');
      return null;
    }
  }

  Future<void> _sendReplyToApp(String? packageName, String reply) async {
    try {
      await _platform.invokeMethod('sendReply', {
        'packageName': packageName,
        'reply': reply,
      });
    } catch (e) {
      print('Error sending reply to app: $e');
    }
  }

  Future<void> _createNotificationSummary(NotificationAnalysis analysis,
      Map<String, dynamic> notificationData) async {
    try {
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'notification_summary',
          'Smart Summaries',
          channelDescription: 'AI-generated notification summaries',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        'Smart Summary - ${analysis.category}',
        analysis.summary,
        notificationDetails,
      );
    } catch (e) {
      print('Error creating notification summary: $e');
    }
  }

  Future<void> _scheduleTaskFromNotification(
      NotificationAnalysis analysis) async {
    try {
      if (analysis.actionRequired) {
        await _firestore.collection('tasks').add({
          'task': analysis.suggestedAction,
          'source': 'notification_analysis',
          'category': analysis.category,
          'priority': analysis.urgencyLevel,
          'createdAt': FieldValue.serverTimestamp(),
          'completed': false,
          'summary': analysis.summary,
        });
      }
    } catch (e) {
      print('Error scheduling task from notification: $e');
    }
  }

  Future<void> _saveNotificationAnalysis(Map<String, dynamic> notificationData,
      NotificationAnalysis analysis) async {
    try {
      await _firestore.collection('notification_analyses').add({
        'timestamp': FieldValue.serverTimestamp(),
        'packageName': notificationData['packageName'],
        'title': notificationData['title'],
        'text': notificationData['text'],
        'analysis': analysis.toJson(),
      });
    } catch (e) {
      print('Error saving notification analysis: $e');
    }
  }

  // Daily notification summary
  Future<void> generateDailyNotificationSummary() async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final notifications = await _firestore
          .collection('notification_analyses')
          .where('timestamp',
              isGreaterThanOrEqualTo: Timestamp.fromDate(yesterday))
          .get();

      if (notifications.docs.isEmpty) return;

      // Analyze daily patterns with Gemini
      final summaryText = await _generateDailySummary(notifications.docs);
      if (summaryText == null) return;

      // Show daily summary notification
      const notificationDetails = NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_summary',
          'Daily Summaries',
          channelDescription: 'Daily notification pattern analysis',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      );

      await _localNotifications.show(
        999999,
        'Daily Notification Summary',
        summaryText,
        notificationDetails,
      );
    } catch (e) {
      print('Error generating daily summary: $e');
    }
  }

  Future<String?> _generateDailySummary(
      List<QueryDocumentSnapshot> notifications) async {
    try {
      final apiKey = await _storage.read(key: 'gemini_api_key');
      if (apiKey == null) return null;

      final notificationTexts = notifications.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return '${data['packageName']}: ${data['title']} - ${data['text']}';
      }).join('\n');

      final prompt = '''
      Analyze these notifications from the past 24 hours and create a brief summary:
      - Most active apps
      - Important messages missed
      - Suggested actions
      - Communication patterns

      Keep it under 100 words and actionable.

      Notifications:
      $notificationTexts
      ''';

      final response = await http.post(
        Uri.parse('$_geminiApiUrl?key=$apiKey'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.3,
            'maxOutputTokens': 200,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text']?.trim();
      }

      return null;
    } catch (e) {
      print('Error generating daily summary with Gemini: $e');
      return null;
    }
  }
}
