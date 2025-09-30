import 'dart:async';
import 'package:flutter/services.dart';

import 'google_auth_service.dart';
import 'calendar_service.dart';
import 'tasks_service.dart';
import '../models/floating_pill_data.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;

class GoogleWorkspaceService {
  static final GoogleWorkspaceService _instance =
      GoogleWorkspaceService._internal();
  factory GoogleWorkspaceService() => _instance;
  GoogleWorkspaceService._internal();

  // Method channel for communication with Android
  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/google_workspace');

  final GoogleAuthService _authService = GoogleAuthService();
  final TasksService _tasksService = TasksService();

  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _authService.initialize();
      await _tasksService.initialize();
      _isInitialized = true;
      print("Google Workspace Service initialized successfully");
      return true;
    } catch (e) {
      print("Error initializing Google Workspace Service: $e");
      _isInitialized = false;
      return false;
    }
  }

  /// Sign in to Google and initialize services
  Future<bool> signIn() async {
    try {
      final success = await _authService.signIn();
      if (success) {
        await _tasksService.initialize();

        // Notify Android service that user signed in
        await _channel.invokeMethod('onGoogleSignIn', {
          'userEmail': _authService.userEmail,
          'userName': _authService.userName,
          'userPhotoUrl': _authService.userPhotoUrl,
        });
      }
      return success;
    } catch (e) {
      print("Error signing in to Google: $e");
      return false;
    }
  }

  /// Sign out from Google
  Future<bool> signOut() async {
    try {
      final success = await _authService.signOut();
      if (success) {
        // Notify Android service that user signed out
        await _channel.invokeMethod('onGoogleSignOut');
      }
      return success;
    } catch (e) {
      print("Error signing out from Google: $e");
      return false;
    }
  }

  /// Get comprehensive floating pill data
  Future<FloatingPillData> getFloatingPillData() async {
    if (!_authService.isSignedIn) {
      print(
          "🔒 GoogleWorkspaceService: User not signed in, returning empty data");
      return FloatingPillData.empty();
    }

    try {
      print(
          "🏢 GoogleWorkspaceService: Getting floating pill data for ${_authService.userEmail}");

      // Use existing CalendarService methods
      print("🏢 GoogleWorkspaceService: Fetching today's events...");
      final currentMeetings = await CalendarService.getTodayEvents();
      print(
          "🏢 GoogleWorkspaceService: Got ${currentMeetings.length} today's events");

      print("🏢 GoogleWorkspaceService: Fetching upcoming events...");
      final upcomingEvents = await CalendarService.getUpcomingEvents();
      print(
          "🏢 GoogleWorkspaceService: Got ${upcomingEvents.length} upcoming events");

      // Use TasksService methods
      final dueTodayTasks = await _tasksService.getDueTodayTasks();
      final overdueTasks = await _tasksService.getOverdueTasks();

      // Filter calendar events for current meetings
      final now = DateTime.now();
      final actualCurrentMeetings = currentMeetings.where((event) {
        return now.isAfter(event.startTime) && now.isBefore(event.endTime);
      }).toList();

      // Filter for upcoming events (next 5)
      final actualUpcomingEvents = upcomingEvents.take(5).toList();

      final userInfo = UserInfo(
        name: _authService.userName,
        email: _authService.userEmail,
        photoUrl: _authService.userPhotoUrl,
        isSignedIn: true,
      );

      final data = FloatingPillData(
        userInfo: userInfo,
        currentMeetings: actualCurrentMeetings,
        upcomingEvents: actualUpcomingEvents,
        dueTodayTasks: dueTodayTasks,
        overdueTasks: overdueTasks,
        lastUpdated: DateTime.now(),
      );

      // Send data to Android service
      await _sendDataToAndroid(data);

      return data;
    } catch (e) {
      print("Error getting floating pill data: $e");
      return FloatingPillData.error("Failed to fetch Google data: $e");
    }
  }

  /// Get specific data for current call context
  Future<FloatingPillData> getCallContextData() async {
    if (!_authService.isSignedIn) {
      return FloatingPillData.empty();
    }

    try {
      // Focus on immediate relevant data during a call
      final todayEvents = await CalendarService.getTodayEvents();
      final dueTodayTasks = await _tasksService.getDueTodayTasks();
      final overdueTasks = await _tasksService.getOverdueTasks();

      // Filter for current meetings
      final now = DateTime.now();
      final currentMeetings = todayEvents.where((event) {
        return now.isAfter(event.startTime) && now.isBefore(event.endTime);
      }).toList();

      // Get only the next 2 upcoming events to keep display minimal
      final upcomingEvents =
          (await CalendarService.getUpcomingEvents()).take(2).toList();

      final userInfo = UserInfo(
        name: _authService.userName,
        email: _authService.userEmail,
        photoUrl: _authService.userPhotoUrl,
        isSignedIn: true,
      );

      final data = FloatingPillData(
        userInfo: userInfo,
        currentMeetings: currentMeetings,
        upcomingEvents: upcomingEvents,
        dueTodayTasks:
            dueTodayTasks.take(3).toList(), // Limit to 3 most important
        overdueTasks: overdueTasks.take(2).toList(), // Limit to 2 most urgent
        lastUpdated: DateTime.now(),
      );

      await _sendDataToAndroid(data);
      return data;
    } catch (e) {
      print("Error getting call context data: $e");
      return FloatingPillData.error("Failed to fetch call context data: $e");
    }
  }

  /// Get task statistics
  Future<TaskStats> getTaskStats() async {
    if (!_authService.isSignedIn) {
      return TaskStats(
        totalTasks: 0,
        completedTasks: 0,
        pendingTasks: 0,
        dueTodayTasks: 0,
        overdueTasks: 0,
      );
    }

    try {
      return await _tasksService.getTaskStats();
    } catch (e) {
      print("Error getting task stats: $e");
      return TaskStats(
        totalTasks: 0,
        completedTasks: 0,
        pendingTasks: 0,
        dueTodayTasks: 0,
        overdueTasks: 0,
      );
    }
  }

  /// Mark a task as completed
  Future<bool> markTaskCompleted(String taskListId, String taskId) async {
    if (!_authService.isSignedIn) return false;

    try {
      return await _tasksService.markTaskCompleted(taskListId, taskId);
    } catch (e) {
      print("Error marking task completed: $e");
      return false;
    }
  }

  /// Send updated data to Android TranscriptService
  Future<void> _sendDataToAndroid(FloatingPillData data) async {
    try {
      await _channel.invokeMethod('updateFloatingPillData', data.toJson());
    } catch (e) {
      print("Error sending data to Android: $e");
      // Don't throw here, as this is not critical
    }
  }

  /// Start periodic data refresh
  void startDataRefresh({Duration interval = const Duration(minutes: 2)}) {
    Timer.periodic(interval, (timer) async {
      if (_authService.isSignedIn) {
        await getFloatingPillData();
      }
    });
  }

  /// Handle method calls from Android
  Future<dynamic> handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'refreshData':
        return (await getFloatingPillData()).toJson();

      case 'getCallContextData':
        return (await getCallContextData()).toJson();

      case 'getTaskStats':
        return (await getTaskStats()).toString();

      case 'markTaskCompleted':
        final args = call.arguments as Map<String, dynamic>;
        return await markTaskCompleted(args['taskListId'], args['taskId']);

      case 'signIn':
        return await signIn();

      case 'signOut':
        return await signOut();

      case 'isSignedIn':
        return _authService.isSignedIn;

      default:
        throw PlatformException(
          code: 'UNIMPLEMENTED',
          message: 'Method ${call.method} not implemented',
        );
    }
  }

  /// Get today's events from Google Calendar
  Future<List<CalendarEvent>> getTodaysEvents() async {
    if (!_authService.isSignedIn) return [];
    return await CalendarService.getTodayEvents();
  }

  /// Get today's tasks from Google Tasks
  Future<List<TaskItem>> getTodaysTasks() async {
    if (!_authService.isSignedIn) return [];
    return await _tasksService.getDueTodayTasks();
  }

  /// Create calendar event
  Future<String?> createCalendarEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? attendeeEmails,
    String? location,
  }) async {
    if (!_authService.isSignedIn) return null;

    try {
      // For now, return a mock event ID since we don't have full Google Calendar API integration
      print("Creating calendar event: $title at $startTime");

      // You would implement actual Google Calendar API creation here
      // For now, we'll create a local event and return mock ID
      final eventId = 'event_${DateTime.now().millisecondsSinceEpoch}';

      return eventId;
    } catch (e) {
      print("Error creating calendar event: $e");
      return null;
    }
  }

  /// Find optimal meeting time (placeholder implementation)
  Future<DateTime?> findOptimalMeetingTime({
    required Duration duration,
    required List<String> attendeeEmails,
    DateTime? preferredDate,
  }) async {
    if (!_authService.isSignedIn) return null;

    try {
      // Simple implementation: suggest next available slot
      final preferred =
          preferredDate ?? DateTime.now().add(const Duration(days: 1));

      // Round to next hour
      var suggestedTime = DateTime(
        preferred.year,
        preferred.month,
        preferred.day,
        preferred.hour + 1,
        0,
        0,
      );

      // Ensure it's during business hours (9 AM - 5 PM)
      if (suggestedTime.hour < 9) {
        suggestedTime = DateTime(suggestedTime.year, suggestedTime.month,
            suggestedTime.day, 9, 0, 0);
      } else if (suggestedTime.hour > 17) {
        suggestedTime = DateTime(suggestedTime.year, suggestedTime.month,
            suggestedTime.day + 1, 9, 0, 0);
      }

      return suggestedTime;
    } catch (e) {
      print("Error finding optimal meeting time: $e");
      return null;
    }
  }

  /// Create meetings and tasks from call analysis
  Future<bool> createMeetingsAndTasksFromAnalysis(
    List<dynamic> meetings,
    List<dynamic> tasks,
  ) async {
    if (!_authService.isSignedIn) return false;

    try {
      int createdCount = 0;

      // Create calendar events from meetings
      for (final meeting in meetings) {
        if (meeting.toString().contains('meeting') ||
            meeting.toString().contains('schedule')) {
          final eventId = await createCalendarEvent(
            title: 'Follow-up Meeting',
            description:
                'Auto-created from call analysis: ${meeting.toString()}',
            startTime: DateTime.now().add(const Duration(days: 1)),
            endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
          );
          if (eventId != null) createdCount++;
        }
      }

      // Create tasks from action items using the proper Tasks API
      for (final task in tasks) {
        final taskId = await _tasksService.createTask(
          title: 'Follow-up Action',
          description: 'Auto-created from call analysis: ${task.toString()}',
          dueDate: DateTime.now().add(const Duration(days: 3)), // Due in 3 days
        );
        if (taskId != null) createdCount++;
      }

      print("Created $createdCount items from call analysis");
      return createdCount > 0;
    } catch (e) {
      print("Error creating meetings and tasks from analysis: $e");
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    // Clean up any resources, timers, etc.
    print("Google Workspace Service disposed");
  }

  // Getters
  bool get isSignedIn => _authService.isSignedIn;
  String get userEmail => _authService.userEmail;
  String get userName => _authService.userName;
  String get userPhotoUrl => _authService.userPhotoUrl;
  bool get isInitialized => _isInitialized;

  /// Debug method to test Google Calendar API connectivity
  Future<void> testCalendarConnection() async {
    print("🧪 GoogleWorkspaceService: Testing Calendar API connection...");

    if (!_authService.isSignedIn) {
      print("❌ GoogleWorkspaceService: User not signed in");
      return;
    }

    try {
      print("🧪 GoogleWorkspaceService: Getting authenticated client...");
      final client = await _authService.getAuthenticatedClient();

      if (client == null) {
        print("❌ GoogleWorkspaceService: Failed to get authenticated client");
        return;
      }

      print("🧪 GoogleWorkspaceService: Creating Calendar API instance...");
      final calendarApi = calendar.CalendarApi(client);

      print("🧪 GoogleWorkspaceService: Testing calendar list access...");
      final calendarList = await calendarApi.calendarList.list();
      print(
          "✅ GoogleWorkspaceService: Calendar list success! Found ${calendarList.items?.length ?? 0} calendars");

      for (final cal in calendarList.items ?? []) {
        print(
            "📅 GoogleWorkspaceService: Calendar - ${cal.summary} (${cal.id})");
      }

      print(
          "🧪 GoogleWorkspaceService: Testing events access on primary calendar...");
      final events = await calendarApi.events.list(
        'primary',
        maxResults: 5,
      );
      print(
          "✅ GoogleWorkspaceService: Events access success! Found ${events.items?.length ?? 0} events");

      client.close();
    } catch (e) {
      print("❌ GoogleWorkspaceService: Calendar test failed - $e");
    }
  }
}
