import '../services/tasks_service.dart';
import '../services/calendar_service.dart';
import '../services/ai_analysis_service.dart';

/// Service for intelligent task and event creation from notifications
class IntelligentSchedulingService {
  static final IntelligentSchedulingService _instance =
      IntelligentSchedulingService._internal();
  factory IntelligentSchedulingService() => _instance;
  IntelligentSchedulingService._internal();

  final TasksService _tasksService = TasksService();
  final AIAnalysisService _aiService = AIAnalysisService();

  /// Analyze notification content and auto-create tasks/events based on urgency and content
  Future<AutoSchedulingResult> analyzeAndSchedule({
    required String appName,
    required String title,
    required String body,
    required String bigText,
    String? subText,
    required String urgency,
    required bool requiresAction,
  }) async {
    try {
      final content = '''
App: $appName
Title: $title
Body: $body
SubText: ${subText ?? 'None'}
Additional: $bigText
Urgency: $urgency
Requires Action: $requiresAction
''';

      // Check if we should auto-create task based on urgency
      final shouldCreateTask = _shouldAutoCreateTask(urgency, requiresAction);

      // Check if content suggests an event/calendar item
      final eventSuggestion = await _analyzeForEventCreation(content);

      final result = AutoSchedulingResult();

      // Auto-create task for medium+ urgency
      if (shouldCreateTask) {
        final taskSuggestion = await _generateTaskFromNotification(content);
        if (taskSuggestion != null) {
          final createdTaskId = await _createTask(taskSuggestion);
          if (createdTaskId != null) {
            result.taskCreated = true;
            result.taskId = createdTaskId;
            result.taskTitle = taskSuggestion.title;
          }
        }
      }

      // Auto-create calendar event if detected
      if (eventSuggestion != null) {
        final createdEvent = await _createCalendarEvent(eventSuggestion);
        if (createdEvent != null) {
          result.eventCreated = true;
          result.eventId = createdEvent.id;
          result.eventTitle = createdEvent.title;
          result.eventDateTime = createdEvent.startTime;
        }
      }

      return result;
    } catch (e) {
      print('Error in intelligent scheduling: $e');
      return AutoSchedulingResult();
    }
  }

  /// Check if task should be auto-created based on urgency
  bool _shouldAutoCreateTask(String urgency, bool requiresAction) {
    final urgencyLower = urgency.toLowerCase();
    // Only create tasks for medium or high urgency, not low
    return (urgencyLower == 'medium' || urgencyLower == 'high');
  }

  /// Analyze content for potential calendar events
  Future<EventSuggestion?> _analyzeForEventCreation(String content) async {
    try {
      final prompt = '''
Analyze this notification content and determine if it mentions any calendar events, appointments, or time-sensitive activities that should be added to a calendar:

$content

Look for:
- Specific dates and times (tomorrow, next week, specific dates)
- Events like birthdays, meetings, appointments, deadlines
- Reminders about upcoming activities
- Time-sensitive commitments

If you find a potential calendar event, respond with JSON:
{
  "hasEvent": true,
  "title": "Event title",
  "description": "Event description",
  "startDate": "YYYY-MM-DD",
  "startTime": "HH:MM",
  "isAllDay": true|false,
  "category": "birthday|meeting|appointment|deadline|reminder|other"
}

If no calendar event is detected, respond with:
{
  "hasEvent": false
}
''';

      final response = await _aiService.makeRequest(prompt);

      if (response is Map<String, dynamic> && response['hasEvent'] == true) {
        return EventSuggestion.fromJson(response);
      }

      return null;
    } catch (e) {
      print('Error analyzing for event creation: $e');
      return null;
    }
  }

  /// Generate task suggestion from notification
  Future<TaskSuggestion?> _generateTaskFromNotification(String content) async {
    try {
      final prompt = '''
Create a task based on this notification content:

$content

Generate a task with:
- Clear, actionable title (max 60 characters)
- Detailed description explaining what needs to be done
- Priority level (high, medium, low)
- Due date if time-sensitive (YYYY-MM-DD format)

Respond in JSON format:
{
  "title": "Task title",
  "description": "Detailed task description",
  "priority": "high|medium|low",
  "dueDate": "YYYY-MM-DD" (optional),
  "category": "follow-up|response|payment|reminder|other"
}
''';

      final response = await _aiService.makeRequest(prompt);

      if (response is Map<String, dynamic>) {
        return TaskSuggestion.fromJson(response);
      }

      return null;
    } catch (e) {
      print('Error generating task: $e');
      return null;
    }
  }

  /// Create actual task in Google Tasks
  Future<String?> _createTask(TaskSuggestion suggestion) async {
    try {
      await _tasksService.initialize();

      DateTime? dueDate;
      if (suggestion.dueDate != null) {
        dueDate = DateTime.tryParse(suggestion.dueDate!);
      } else {
        // Default to today's date so tasks show up in the tasks screen
        dueDate = DateTime.now();
      }

      final taskId = await _tasksService.createTask(
        title: suggestion.title,
        description: suggestion.description,
        dueDate: dueDate,
      );

      return taskId;
    } catch (e) {
      print('Error creating task: $e');
      return null;
    }
  }

  /// Create calendar event
  Future<CalendarEvent?> _createCalendarEvent(
      EventSuggestion suggestion) async {
    try {
      DateTime startDate;
      DateTime endDate;

      // Parse the suggested date
      try {
        startDate = DateTime.parse(suggestion.startDate);
      } catch (e) {
        // Fallback to tomorrow if date parsing fails
        startDate = DateTime.now().add(const Duration(days: 1));
      }

      if (suggestion.isAllDay) {
        endDate = startDate.add(const Duration(days: 1));
      } else {
        // Parse time if provided
        if (suggestion.startTime != null) {
          final timeParts = suggestion.startTime!.split(':');
          if (timeParts.length == 2) {
            final hour = int.tryParse(timeParts[0]) ?? 9;
            final minute = int.tryParse(timeParts[1]) ?? 0;
            startDate = DateTime(
                startDate.year, startDate.month, startDate.day, hour, minute);
          }
        }
        endDate = startDate.add(const Duration(hours: 1));
      }

      final event = await CalendarService.createEvent(
        title: suggestion.title,
        description: suggestion.description,
        startTime: startDate,
        endTime: endDate,
        isAllDay: suggestion.isAllDay,
        priority: EventPriority.normal,
      );

      return event;
    } catch (e) {
      print('Error creating calendar event: $e');
      return null;
    }
  }

  /// Manually create task from notification details
  Future<String?> createManualTask({
    required String title,
    required String description,
    String priority = 'medium',
    DateTime? dueDate,
  }) async {
    try {
      await _tasksService.initialize();

      final taskId = await _tasksService.createTask(
        title: title,
        description: description,
        dueDate: dueDate,
      );

      return taskId;
    } catch (e) {
      print('Error creating manual task: $e');
      return null;
    }
  }
}

/// Result of auto-scheduling analysis
class AutoSchedulingResult {
  bool taskCreated = false;
  String? taskId;
  String? taskTitle;

  bool eventCreated = false;
  String? eventId;
  String? eventTitle;
  DateTime? eventDateTime;

  bool get hasAnyCreated => taskCreated || eventCreated;

  String get summary {
    final items = <String>[];
    if (taskCreated && taskTitle != null) {
      items.add('Task: $taskTitle');
    }
    if (eventCreated && eventTitle != null) {
      items.add('Event: $eventTitle');
    }
    return items.isEmpty ? 'No items created' : items.join(', ');
  }
}

/// Task suggestion from AI analysis
class TaskSuggestion {
  final String title;
  final String description;
  final String priority;
  final String? dueDate;
  final String category;

  TaskSuggestion({
    required this.title,
    required this.description,
    required this.priority,
    this.dueDate,
    required this.category,
  });

  factory TaskSuggestion.fromJson(Map<String, dynamic> json) {
    return TaskSuggestion(
      title: json['title']?.toString() ?? 'Task',
      description: json['description']?.toString() ?? 'Follow up required',
      priority: json['priority']?.toString() ?? 'medium',
      dueDate: json['dueDate']?.toString(),
      category: json['category']?.toString() ?? 'other',
    );
  }
}

/// Event suggestion from AI analysis
class EventSuggestion {
  final String title;
  final String description;
  final String startDate;
  final String? startTime;
  final bool isAllDay;
  final String category;

  EventSuggestion({
    required this.title,
    required this.description,
    required this.startDate,
    this.startTime,
    required this.isAllDay,
    required this.category,
  });

  factory EventSuggestion.fromJson(Map<String, dynamic> json) {
    return EventSuggestion(
      title: json['title']?.toString() ?? 'Event',
      description:
          json['description']?.toString() ?? 'Auto-created from notification',
      startDate: json['startDate']?.toString() ??
          DateTime.now()
              .add(const Duration(days: 1))
              .toIso8601String()
              .split('T')[0],
      startTime: json['startTime']?.toString(),
      isAllDay: json['isAllDay'] as bool? ?? false,
      category: json['category']?.toString() ?? 'other',
    );
  }
}
