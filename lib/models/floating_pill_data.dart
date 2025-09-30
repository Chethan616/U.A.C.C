import '../services/calendar_service.dart';
import '../services/tasks_service.dart';

/// Main data model for the floating pill overlay
class FloatingPillData {
  final UserInfo? userInfo;
  final List<CalendarEvent> currentMeetings;
  final List<CalendarEvent> upcomingEvents;
  final List<TaskItem> dueTodayTasks;
  final List<TaskItem> overdueTasks;
  final CallInfo? activeCall;
  final DateTime lastUpdated;
  final bool isLoading;
  final String? errorMessage;

  FloatingPillData({
    this.userInfo,
    required this.currentMeetings,
    required this.upcomingEvents,
    required this.dueTodayTasks,
    required this.overdueTasks,
    this.activeCall,
    required this.lastUpdated,
    this.isLoading = false,
    this.errorMessage,
  });

  factory FloatingPillData.loading() {
    return FloatingPillData(
      currentMeetings: [],
      upcomingEvents: [],
      dueTodayTasks: [],
      overdueTasks: [],
      lastUpdated: DateTime.now(),
      isLoading: true,
    );
  }

  factory FloatingPillData.error(String message) {
    return FloatingPillData(
      currentMeetings: [],
      upcomingEvents: [],
      dueTodayTasks: [],
      overdueTasks: [],
      lastUpdated: DateTime.now(),
      isLoading: false,
      errorMessage: message,
    );
  }

  factory FloatingPillData.empty() {
    return FloatingPillData(
      currentMeetings: [],
      upcomingEvents: [],
      dueTodayTasks: [],
      overdueTasks: [],
      lastUpdated: DateTime.now(),
      isLoading: false,
    );
  }

  FloatingPillData copyWith({
    UserInfo? userInfo,
    List<CalendarEvent>? currentMeetings,
    List<CalendarEvent>? upcomingEvents,
    List<TaskItem>? dueTodayTasks,
    List<TaskItem>? overdueTasks,
    CallInfo? activeCall,
    DateTime? lastUpdated,
    bool? isLoading,
    String? errorMessage,
  }) {
    return FloatingPillData(
      userInfo: userInfo ?? this.userInfo,
      currentMeetings: currentMeetings ?? this.currentMeetings,
      upcomingEvents: upcomingEvents ?? this.upcomingEvents,
      dueTodayTasks: dueTodayTasks ?? this.dueTodayTasks,
      overdueTasks: overdueTasks ?? this.overdueTasks,
      activeCall: activeCall ?? this.activeCall,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Get total count of urgent items (current meetings + overdue tasks)
  int get urgentItemsCount => currentMeetings.length + overdueTasks.length;

  /// Get total count of today's items (due today tasks + upcoming events)
  int get todayItemsCount => dueTodayTasks.length + upcomingEvents.length;

  /// Check if there are any active meetings happening right now
  bool get hasActiveMeeting => currentMeetings.isNotEmpty;

  /// Check if there are overdue tasks
  bool get hasOverdueTasks => overdueTasks.isNotEmpty;

  /// Check if user has any Google data
  bool get hasGoogleData =>
      userInfo != null &&
      (upcomingEvents.isNotEmpty || dueTodayTasks.isNotEmpty);

  /// Get the most important item to display first
  DisplayItem? get mostImportantItem {
    // Prioritize current meetings
    if (currentMeetings.isNotEmpty) {
      return DisplayItem.fromCalendarEvent(
          currentMeetings.first, ItemPriority.urgent);
    }

    // Then overdue tasks
    if (overdueTasks.isNotEmpty) {
      return DisplayItem.fromTask(overdueTasks.first, ItemPriority.urgent);
    }

    // Then due today tasks
    if (dueTodayTasks.isNotEmpty) {
      return DisplayItem.fromTask(dueTodayTasks.first, ItemPriority.high);
    }

    // Finally upcoming events
    if (upcomingEvents.isNotEmpty) {
      return DisplayItem.fromCalendarEvent(
          upcomingEvents.first, ItemPriority.normal);
    }

    return null;
  }

  /// Convert to JSON for method channel communication
  Map<String, dynamic> toJson() {
    return {
      'userInfo': userInfo?.toJson(),
      'currentMeetings': currentMeetings.map((e) => e.toJson()).toList(),
      'upcomingEvents': upcomingEvents.map((e) => e.toJson()).toList(),
      'dueTodayTasks': dueTodayTasks.map((t) => t.toJson()).toList(),
      'overdueTasks': overdueTasks.map((t) => t.toJson()).toList(),
      'activeCall': activeCall?.toJson(),
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      'isLoading': isLoading,
      'errorMessage': errorMessage,
      'urgentItemsCount': urgentItemsCount,
      'todayItemsCount': todayItemsCount,
      'hasActiveMeeting': hasActiveMeeting,
      'hasOverdueTasks': hasOverdueTasks,
      'hasGoogleData': hasGoogleData,
    };
  }

  @override
  String toString() {
    return 'FloatingPillData(meetings: ${currentMeetings.length}, events: ${upcomingEvents.length}, due today: ${dueTodayTasks.length}, overdue: ${overdueTasks.length})';
  }
}

/// User information for the floating pill
class UserInfo {
  final String name;
  final String email;
  final String? photoUrl;
  final bool isSignedIn;

  UserInfo({
    required this.name,
    required this.email,
    this.photoUrl,
    required this.isSignedIn,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'isSignedIn': isSignedIn,
    };
  }
}

/// Current call information
class CallInfo {
  final String? contactName;
  final String? contactNumber;
  final DateTime startTime;
  final CallType callType;

  CallInfo({
    this.contactName,
    this.contactNumber,
    required this.startTime,
    required this.callType,
  });

  Duration get duration => DateTime.now().difference(startTime);

  String get durationString {
    final duration = this.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h ${minutes}m ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'contactName': contactName,
      'contactNumber': contactNumber,
      'startTime': startTime.millisecondsSinceEpoch,
      'callType': callType.name,
      'duration': duration.inSeconds,
      'durationString': durationString,
    };
  }
}

enum CallType {
  incoming,
  outgoing,
}

/// Generic display item for the floating pill
class DisplayItem {
  final String id;
  final String title;
  final String subtitle;
  final DisplayItemType type;
  final ItemPriority priority;
  final DateTime? dateTime;
  final String? actionUrl;
  final IconData? iconData;

  DisplayItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    required this.priority,
    this.dateTime,
    this.actionUrl,
    this.iconData,
  });

  factory DisplayItem.fromCalendarEvent(
      CalendarEvent event, ItemPriority priority) {
    return DisplayItem(
      id: event.id,
      title: event.title,
      subtitle: _formatEventTime(event),
      type: DisplayItemType.meeting,
      priority: priority,
      dateTime: event.startTime,
      actionUrl: event.meetingLink,
    );
  }

  factory DisplayItem.fromTask(TaskItem task, ItemPriority priority) {
    return DisplayItem(
      id: task.id,
      title: task.title,
      subtitle: task.dueDateString,
      type: DisplayItemType.task,
      priority: priority,
      dateTime: task.dueDate,
    );
  }

  static String _formatEventTime(CalendarEvent event) {
    if (event.isAllDay) return 'All day';

    final start = event.startTime;
    final end = event.endTime;

    final startStr =
        '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr =
        '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return '$startStr - $endStr';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'subtitle': subtitle,
      'type': type.name,
      'priority': priority.name,
      'dateTime': dateTime?.millisecondsSinceEpoch,
      'actionUrl': actionUrl,
    };
  }
}

enum DisplayItemType {
  meeting,
  event,
  task,
  reminder,
}

enum ItemPriority {
  low,
  normal,
  high,
  urgent,
}

// Extensions to add JSON serialization to existing models
extension CalendarEventJson on CalendarEvent {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime.millisecondsSinceEpoch,
      'attendees': attendees,
      'location': location,
      'meetingLink': meetingLink,
      'isAllDay': isAllDay,
      'priority': priority.name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }
}

extension TaskItemJson on TaskItem {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'taskListId': taskListId,
      'taskListName': taskListName,
      'title': title,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'completedDate': completedDate?.millisecondsSinceEpoch,
      'isCompleted': isCompleted,
      'updatedDate': updatedDate?.millisecondsSinceEpoch,
      'notes': notes,
      'dueDateString': dueDateString,
      'isDueToday': isDueToday,
      'isOverdue': isOverdue,
      'isUpcoming': isUpcoming,
      'priority': priority.name,
    };
  }
}

// Import for IconData - you may need to adjust this import
class IconData {
  final int codePoint;
  final String? fontFamily;

  const IconData(this.codePoint, {this.fontFamily});
}
