import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'call_automation_service.dart';
import 'notification_automation_service.dart';
import 'google_workspace_service.dart';
import '../models/automation_models.dart';

class AutomationCoordinator {
  static const _storage = FlutterSecureStorage();

  final CallAutomationService _callService;
  final NotificationAutomationService _notificationService;
  final GoogleWorkspaceService _workspaceService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AutomationCoordinator({
    CallAutomationService? callService,
    NotificationAutomationService? notificationService,
    GoogleWorkspaceService? workspaceService,
  })  : _callService = callService ?? CallAutomationService(),
        _notificationService =
            notificationService ?? NotificationAutomationService(),
        _workspaceService = workspaceService ?? GoogleWorkspaceService();

  // Initialize all automation services
  Future<bool> initializeAllServices() async {
    try {
      final results = await Future.wait([
        _notificationService.initialize(),
        _workspaceService.initialize(),
      ]);

      final allSuccessful = results.every((result) => result);

      if (allSuccessful) {
        await _schedulePeriodicTasks();
      }

      return allSuccessful;
    } catch (e) {
      print('Error initializing automation services: $e');
      return false;
    }
  }

  // Complete call automation workflow
  Future<AutomationResult> processCallRecording() async {
    try {
      // Step 1: Analyze call
      final callAnalysis = await _callService.stopRecordingAndAnalyze();
      if (callAnalysis == null) {
        return AutomationResult.failure('Failed to analyze call recording');
      }

      // Step 2: Schedule meetings and tasks
      final schedulingSuccess =
          await _callService.scheduleTasksAndMeetings(callAnalysis);
      if (!schedulingSuccess) {
        return AutomationResult.failure(
            'Failed to schedule meetings and tasks locally');
      }

      // Step 3: Sync with Google Workspace
      await _workspaceService.createMeetingsAndTasksFromAnalysis(
        callAnalysis.scheduledMeetings,
        callAnalysis.actionItems,
      );

      // Step 4: Generate summary notification
      await _createCallSummaryNotification(callAnalysis);

      return AutomationResult.success(
        'Call processed successfully: ${callAnalysis.summary}',
        callAnalysis,
      );
    } catch (e) {
      return AutomationResult.failure('Error processing call: $e');
    }
  }

  // Start call recording
  Future<bool> startCallRecording() async {
    final path = await _callService.startCallRecording();
    return path != null;
  }

  // Smart meeting scheduling
  Future<AutomationResult> scheduleSmartMeeting({
    required String title,
    required List<String> participantEmails,
    required Duration duration,
    DateTime? preferredDateTime,
  }) async {
    try {
      // Find optimal time
      final optimalTime = await _workspaceService.findOptimalMeetingTime(
        duration: duration,
        attendeeEmails: participantEmails,
        preferredDate: preferredDateTime,
      );

      if (optimalTime == null) {
        return AutomationResult.failure('No suitable meeting time found');
      }

      // Create the meeting
      final eventId = await _workspaceService.createCalendarEvent(
        title: title,
        description: 'Smart-scheduled meeting via UACC',
        startTime: optimalTime,
        endTime: optimalTime.add(duration),
        attendeeEmails: participantEmails,
      );

      if (eventId == null) {
        return AutomationResult.failure('Failed to create calendar event');
      }

      return AutomationResult.success(
        'Meeting scheduled for ${_formatDateTime(optimalTime)}',
        {'eventId': eventId, 'scheduledTime': optimalTime},
      );
    } catch (e) {
      return AutomationResult.failure('Error scheduling meeting: $e');
    }
  }

  // Get today's schedule with AI insights
  Future<DailySchedule> getTodaysScheduleWithInsights() async {
    try {
      final events = await _workspaceService.getTodaysEvents();
      final tasks = await _workspaceService.getTodaysTasks();

      // Get local calendar events and tasks
      final localEvents = await _getLocalEvents();
      final localTasks = await _getLocalTasks();

      // Generate AI insights about the schedule
      final insights = await _generateScheduleInsights(
          events, tasks, localEvents, localTasks);

      return DailySchedule(
        googleEvents: events,
        googleTasks: tasks,
        localEvents: localEvents,
        localTasks: localTasks,
        aiInsights: insights,
      );
    } catch (e) {
      print('Error getting daily schedule: $e');
      return DailySchedule.empty();
    }
  }

  // Automation settings management
  Future<void> updateAutomationSettings(AutomationSettings settings) async {
    try {
      await _storage.write(
          key: 'automation_settings', value: settings.toJson());

      // Apply settings
      if (settings.enableCallRecording) {
        // Enable call recording automation
      }

      if (settings.enableSmartReplies) {
        // Enable notification automation
      }

      if (settings.enableSmartScheduling) {
        // Enable calendar automation
      }
    } catch (e) {
      print('Error updating automation settings: $e');
    }
  }

  Future<AutomationSettings> getAutomationSettings() async {
    try {
      final settingsJson = await _storage.read(key: 'automation_settings');
      if (settingsJson != null) {
        return AutomationSettings.fromJson(settingsJson);
      }
    } catch (e) {
      print('Error getting automation settings: $e');
    }
    return AutomationSettings.defaultSettings();
  }

  // Private helper methods
  Future<void> _createCallSummaryNotification(CallAnalysis analysis) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'call_summary',
        'title': 'Call Analysis Complete',
        'body': analysis.summary,
        'data': {
          'keyPoints': analysis.keyPoints,
          'actionItems':
              analysis.actionItems.map((item) => item.toJson()).toList(),
          'sentiment': analysis.sentiment,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
    } catch (e) {
      print('Error creating call summary notification: $e');
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalEvents() async {
    try {
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final query = await _firestore
          .collection('calendar_events')
          .where('startTime',
              isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('startTime', isLessThan: endOfDay.toIso8601String())
          .orderBy('startTime')
          .get();

      return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      print('Error getting local events: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _getLocalTasks() async {
    try {
      final today = DateTime.now();
      final todayString =
          "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}";

      final query = await _firestore
          .collection('tasks')
          .where('dueDate', isGreaterThanOrEqualTo: todayString)
          .where('dueDate', isLessThan: todayString + "T23:59:59")
          .where('completed', isEqualTo: false)
          .orderBy('dueDate')
          .get();

      return query.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      print('Error getting local tasks: $e');
      return [];
    }
  }

  Future<List<String>> _generateScheduleInsights(
    List<dynamic> googleEvents,
    List<dynamic> googleTasks,
    List<Map<String, dynamic>> localEvents,
    List<Map<String, dynamic>> localTasks,
  ) async {
    // This would use Gemini API to generate insights
    // For now, returning mock insights
    return [
      'You have ${googleEvents.length + localEvents.length} meetings today',
      'Peak meeting time: 2-4 PM',
      '${googleTasks.length + localTasks.length} tasks pending',
      'Recommended: Block 1 hour for focused work',
    ];
  }

  Future<void> _schedulePeriodicTasks() async {
    // Schedule daily notification summary
    // Schedule weekly automation report
    // Schedule monthly optimization suggestions
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void dispose() {
    _callService.dispose();
    _workspaceService.dispose();
  }
}
