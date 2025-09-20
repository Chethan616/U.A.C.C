import 'dart:convert';

// Shared data models for automation services

class CallAnalysis {
  final String summary;
  final List<String> keyPoints;
  final List<ActionItem> actionItems;
  final List<ScheduledMeeting> scheduledMeetings;
  final String sentiment;
  final bool followUpRequired;

  CallAnalysis({
    required this.summary,
    required this.keyPoints,
    required this.actionItems,
    required this.scheduledMeetings,
    required this.sentiment,
    required this.followUpRequired,
  });

  factory CallAnalysis.fromJson(Map<String, dynamic> json) {
    return CallAnalysis(
      summary: json['summary'] ?? '',
      keyPoints: List<String>.from(json['keyPoints'] ?? []),
      actionItems: (json['actionItems'] as List?)
              ?.map((item) => ActionItem.fromJson(item))
              .toList() ??
          [],
      scheduledMeetings: (json['scheduledMeetings'] as List?)
              ?.map((meeting) => ScheduledMeeting.fromJson(meeting))
              .toList() ??
          [],
      sentiment: json['sentiment'] ?? 'Neutral',
      followUpRequired: json['followUpRequired'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'keyPoints': keyPoints,
      'actionItems': actionItems.map((item) => item.toJson()).toList(),
      'scheduledMeetings':
          scheduledMeetings.map((meeting) => meeting.toJson()).toList(),
      'sentiment': sentiment,
      'followUpRequired': followUpRequired,
    };
  }
}

class ActionItem {
  final String task;
  final String assignee;
  final String priority;
  final String dueDate;

  ActionItem({
    required this.task,
    required this.assignee,
    required this.priority,
    required this.dueDate,
  });

  factory ActionItem.fromJson(Map<String, dynamic> json) {
    return ActionItem(
      task: json['task'] ?? '',
      assignee: json['assignee'] ?? '',
      priority: json['priority'] ?? 'Medium',
      dueDate: json['dueDate'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'assignee': assignee,
      'priority': priority,
      'dueDate': dueDate,
    };
  }
}

class ScheduledMeeting {
  final String title;
  final String date;
  final String time;
  final List<String> participants;

  ScheduledMeeting({
    required this.title,
    required this.date,
    required this.time,
    required this.participants,
  });

  factory ScheduledMeeting.fromJson(Map<String, dynamic> json) {
    return ScheduledMeeting(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      participants: List<String>.from(json['participants'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'date': date,
      'time': time,
      'participants': participants,
    };
  }
}

class NotificationAnalysis {
  final bool isImportant;
  final String urgencyLevel;
  final bool shouldReply;
  final bool actionRequired;
  final String category;
  final String sentiment;
  final List<String> keyTopics;
  final String suggestedAction;
  final String summary;
  final String replyTone;

  NotificationAnalysis({
    required this.isImportant,
    required this.urgencyLevel,
    required this.shouldReply,
    required this.actionRequired,
    required this.category,
    required this.sentiment,
    required this.keyTopics,
    required this.suggestedAction,
    required this.summary,
    required this.replyTone,
  });

  factory NotificationAnalysis.fromJson(Map<String, dynamic> json) {
    return NotificationAnalysis(
      isImportant: json['isImportant'] ?? false,
      urgencyLevel: json['urgencyLevel'] ?? 'Low',
      shouldReply: json['shouldReply'] ?? false,
      actionRequired: json['actionRequired'] ?? false,
      category: json['category'] ?? 'Social',
      sentiment: json['sentiment'] ?? 'Neutral',
      keyTopics: List<String>.from(json['keyTopics'] ?? []),
      suggestedAction: json['suggestedAction'] ?? 'Ignore',
      summary: json['summary'] ?? '',
      replyTone: json['replyTone'] ?? 'Casual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isImportant': isImportant,
      'urgencyLevel': urgencyLevel,
      'shouldReply': shouldReply,
      'actionRequired': actionRequired,
      'category': category,
      'sentiment': sentiment,
      'keyTopics': keyTopics,
      'suggestedAction': suggestedAction,
      'summary': summary,
      'replyTone': replyTone,
    };
  }
}

class AutomationResult {
  final bool success;
  final String message;
  final dynamic data;

  AutomationResult({required this.success, required this.message, this.data});

  factory AutomationResult.success(String message, [dynamic data]) =>
      AutomationResult(success: true, message: message, data: data);

  factory AutomationResult.failure(String message) =>
      AutomationResult(success: false, message: message);
}

class DailySchedule {
  final List<dynamic> googleEvents;
  final List<dynamic> googleTasks;
  final List<Map<String, dynamic>> localEvents;
  final List<Map<String, dynamic>> localTasks;
  final List<String> aiInsights;

  DailySchedule({
    required this.googleEvents,
    required this.googleTasks,
    required this.localEvents,
    required this.localTasks,
    required this.aiInsights,
  });

  factory DailySchedule.empty() => DailySchedule(
        googleEvents: [],
        googleTasks: [],
        localEvents: [],
        localTasks: [],
        aiInsights: [],
      );

  int get totalEvents => googleEvents.length + localEvents.length;
  int get totalTasks => googleTasks.length + localTasks.length;
}

class AutomationSettings {
  final bool enableCallRecording;
  final bool enableSmartReplies;
  final bool enableSmartScheduling;
  final bool enableNotificationSummary;
  final bool enableAutoTaskCreation;
  final String replyTone;
  final List<String> priorityApps;

  AutomationSettings({
    required this.enableCallRecording,
    required this.enableSmartReplies,
    required this.enableSmartScheduling,
    required this.enableNotificationSummary,
    required this.enableAutoTaskCreation,
    required this.replyTone,
    required this.priorityApps,
  });

  factory AutomationSettings.defaultSettings() => AutomationSettings(
        enableCallRecording: true,
        enableSmartReplies: false,
        enableSmartScheduling: true,
        enableNotificationSummary: true,
        enableAutoTaskCreation: true,
        replyTone: 'Professional',
        priorityApps: ['com.whatsapp', 'com.slack', 'com.microsoft.teams'],
      );

  factory AutomationSettings.fromJson(String json) {
    final map = Map<String, dynamic>.from(jsonDecode(json));
    return AutomationSettings(
      enableCallRecording: map['enableCallRecording'] ?? true,
      enableSmartReplies: map['enableSmartReplies'] ?? false,
      enableSmartScheduling: map['enableSmartScheduling'] ?? true,
      enableNotificationSummary: map['enableNotificationSummary'] ?? true,
      enableAutoTaskCreation: map['enableAutoTaskCreation'] ?? true,
      replyTone: map['replyTone'] ?? 'Professional',
      priorityApps: List<String>.from(map['priorityApps'] ?? []),
    );
  }

  String toJson() => jsonEncode({
        'enableCallRecording': enableCallRecording,
        'enableSmartReplies': enableSmartReplies,
        'enableSmartScheduling': enableSmartScheduling,
        'enableNotificationSummary': enableNotificationSummary,
        'enableAutoTaskCreation': enableAutoTaskCreation,
        'replyTone': replyTone,
        'priorityApps': priorityApps,
      });
}
