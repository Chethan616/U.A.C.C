import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:googleapis/calendar/v3.dart';
import 'package:googleapis/tasks/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/automation_models.dart';

class GoogleWorkspaceService {
  static const _storage = FlutterSecureStorage();
  static const _scopes = [
    CalendarApi.calendarScope,
    TasksApi.tasksScope,
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  AuthClient? _authenticatedClient;

  // Initialize Google Workspace integration
  Future<bool> initialize() async {
    try {
      final credentials = await _getStoredCredentials();
      if (credentials != null) {
        _authenticatedClient =
            await clientViaServiceAccount(credentials, _scopes);
        return true;
      }
      return false;
    } catch (e) {
      print('Error initializing Google Workspace: $e');
      return false;
    }
  }

  Future<ServiceAccountCredentials?> _getStoredCredentials() async {
    try {
      final credentialsJson =
          await _storage.read(key: 'google_service_account');
      if (credentialsJson != null) {
        final credentialsMap = jsonDecode(credentialsJson);
        return ServiceAccountCredentials.fromJson(credentialsMap);
      }
      return null;
    } catch (e) {
      print('Error getting stored credentials: $e');
      return null;
    }
  }

  // Google Calendar Integration
  Future<String?> createCalendarEvent({
    required String title,
    required String description,
    required DateTime startTime,
    required DateTime endTime,
    List<String>? attendeeEmails,
    String? location,
  }) async {
    try {
      if (_authenticatedClient == null) {
        throw Exception('Google Workspace not initialized');
      }

      final calendarApi = CalendarApi(_authenticatedClient!);

      final event = Event()
        ..summary = title
        ..description = description
        ..start = EventDateTime(dateTime: startTime, timeZone: 'UTC')
        ..end = EventDateTime(dateTime: endTime, timeZone: 'UTC')
        ..location = location;

      if (attendeeEmails != null && attendeeEmails.isNotEmpty) {
        event.attendees = attendeeEmails
            .map((email) => EventAttendee()..email = email)
            .toList();
      }

      final createdEvent = await calendarApi.events.insert(event, 'primary');

      // Save to local database as backup
      await _saveEventToLocal(createdEvent, 'google_calendar');

      return createdEvent.id;
    } catch (e) {
      print('Error creating calendar event: $e');
      return null;
    }
  }

  Future<List<Event>> getTodaysEvents() async {
    try {
      if (_authenticatedClient == null) {
        throw Exception('Google Workspace not initialized');
      }

      final calendarApi = CalendarApi(_authenticatedClient!);
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final events = await calendarApi.events.list(
        'primary',
        timeMin: startOfDay,
        timeMax: endOfDay,
        singleEvents: true,
        orderBy: 'startTime',
      );

      return events.items ?? [];
    } catch (e) {
      print('Error getting today\'s events: $e');
      return [];
    }
  }

  // Google Tasks Integration
  Future<String?> createTask({
    required String title,
    String? notes,
    DateTime? dueDate,
    String priority = 'normal',
  }) async {
    try {
      if (_authenticatedClient == null) {
        throw Exception('Google Workspace not initialized');
      }

      final tasksApi = TasksApi(_authenticatedClient!);

      final task = Task()
        ..title = title
        ..notes = notes;

      if (dueDate != null) {
        task.due = dueDate.toIso8601String();
      }

      final createdTask = await tasksApi.tasks.insert(task, '@default');

      // Save to local database as backup
      await _saveTaskToLocal(createdTask, priority);

      return createdTask.id;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  Future<List<Task>> getTodaysTasks() async {
    try {
      if (_authenticatedClient == null) {
        throw Exception('Google Workspace not initialized');
      }

      final tasksApi = TasksApi(_authenticatedClient!);
      final tasks = await tasksApi.tasks.list('@default');

      final today = DateTime.now();
      return (tasks.items ?? []).where((task) {
        if (task.due == null) return false;
        final dueDate = DateTime.parse(task.due!);
        return dueDate.year == today.year &&
            dueDate.month == today.month &&
            dueDate.day == today.day;
      }).toList();
    } catch (e) {
      print('Error getting today\'s tasks: $e');
      return [];
    }
  }

  Future<bool> markTaskCompleted(String taskId) async {
    try {
      if (_authenticatedClient == null) return false;

      final tasksApi = TasksApi(_authenticatedClient!);
      final task = Task()
        ..id = taskId
        ..status = 'completed'
        ..completed = DateTime.now().toIso8601String();

      await tasksApi.tasks.update(task, '@default', taskId);

      // Update local database
      await _updateLocalTaskStatus(taskId, true);

      return true;
    } catch (e) {
      print('Error marking task completed: $e');
      return false;
    }
  }

  // Bulk operations from call analysis
  Future<bool> createMeetingsAndTasksFromAnalysis(
    List<ScheduledMeeting> meetings,
    List<ActionItem> tasks,
  ) async {
    try {
      // Create calendar events
      for (final meeting in meetings) {
        final startTime = _parseDateTime(meeting.date, meeting.time);
        if (startTime != null) {
          final endTime =
              startTime.add(const Duration(hours: 1)); // Default 1 hour

          await createCalendarEvent(
            title: meeting.title,
            description: 'Auto-created from call analysis',
            startTime: startTime,
            endTime: endTime,
            attendeeEmails: _extractEmails(meeting.participants),
          );
        }
      }

      // Create tasks
      for (final task in tasks) {
        final dueDate = _parseDate(task.dueDate);
        await createTask(
          title: task.task,
          notes: 'Assignee: ${task.assignee}\nPriority: ${task.priority}',
          dueDate: dueDate,
          priority: task.priority.toLowerCase(),
        );
      }

      return true;
    } catch (e) {
      print('Error creating meetings and tasks from analysis: $e');
      return false;
    }
  }

  // Smart scheduling with conflict detection
  Future<DateTime?> findOptimalMeetingTime({
    required Duration duration,
    required List<String> attendeeEmails,
    DateTime? preferredDate,
  }) async {
    try {
      if (_authenticatedClient == null) return null;

      final calendarApi = CalendarApi(_authenticatedClient!);
      final targetDate =
          preferredDate ?? DateTime.now().add(const Duration(days: 1));

      // Get busy times for the target date
      final freeBusyQuery = FreeBusyRequest()
        ..timeMin =
            DateTime(targetDate.year, targetDate.month, targetDate.day, 9)
        ..timeMax =
            DateTime(targetDate.year, targetDate.month, targetDate.day, 17)
        ..items = attendeeEmails
            .map((email) => FreeBusyRequestItem()..id = email)
            .toList();

      final freeBusyResponse = await calendarApi.freebusy.query(freeBusyQuery);

      // Find free slots (simplified algorithm)
      final startTime =
          DateTime(targetDate.year, targetDate.month, targetDate.day, 9);
      var currentTime = startTime;
      final endOfDay =
          DateTime(targetDate.year, targetDate.month, targetDate.day, 17);

      while (currentTime.add(duration).isBefore(endOfDay)) {
        bool isSlotFree = true;

        // Check if slot conflicts with any attendee's busy time
        freeBusyResponse.calendars?.forEach((calendarId, calendar) {
          calendar.busy?.forEach((busyPeriod) {
            final busyStart = busyPeriod.start;
            final busyEnd = busyPeriod.end;

            if (busyStart != null && busyEnd != null) {
              final slotEnd = currentTime.add(duration);
              if (currentTime.isBefore(busyEnd) && slotEnd.isAfter(busyStart)) {
                isSlotFree = false;
              }
            }
          });
        });

        if (isSlotFree) {
          return currentTime;
        }

        currentTime =
            currentTime.add(const Duration(minutes: 30)); // 30-minute slots
      }

      return null; // No free slot found
    } catch (e) {
      print('Error finding optimal meeting time: $e');
      return null;
    }
  }

  // Local database operations
  Future<void> _saveEventToLocal(Event event, String source) async {
    try {
      await _firestore.collection('calendar_events').add({
        'googleEventId': event.id,
        'title': event.summary,
        'description': event.description,
        'startTime': event.start?.dateTime?.toIso8601String(),
        'endTime': event.end?.dateTime?.toIso8601String(),
        'location': event.location,
        'source': source,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving event to local: $e');
    }
  }

  Future<void> _saveTaskToLocal(Task task, String priority) async {
    try {
      await _firestore.collection('tasks').add({
        'googleTaskId': task.id,
        'title': task.title,
        'notes': task.notes,
        'dueDate': task.due,
        'priority': priority,
        'completed': task.status == 'completed',
        'source': 'google_tasks',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving task to local: $e');
    }
  }

  Future<void> _updateLocalTaskStatus(String taskId, bool completed) async {
    try {
      final query = await _firestore
          .collection('tasks')
          .where('googleTaskId', isEqualTo: taskId)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'completed': completed,
          'completedAt': completed ? FieldValue.serverTimestamp() : null,
        });
      }
    } catch (e) {
      print('Error updating local task status: $e');
    }
  }

  // Helper methods
  DateTime? _parseDateTime(String date, String time) {
    try {
      final dateParts = date.split('-');
      final timeParts = time.split(':');

      return DateTime(
        int.parse(dateParts[0]), // year
        int.parse(dateParts[1]), // month
        int.parse(dateParts[2]), // day
        int.parse(timeParts[0]), // hour
        int.parse(timeParts[1]), // minute
      );
    } catch (e) {
      return null;
    }
  }

  DateTime? _parseDate(String? dateString) {
    if (dateString == null) return null;
    try {
      return DateTime.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  List<String> _extractEmails(List<String> participants) {
    return participants.where((p) => p.contains('@')).toList();
  }

  void dispose() {
    _authenticatedClient?.close();
  }
}
