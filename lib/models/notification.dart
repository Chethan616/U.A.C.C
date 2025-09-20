// lib/models/notification.dart
class NotificationModel {
  final String notificationId;
  final String title;
  final String body;
  final String app;
  final NotificationPriority priority;
  final String summary;
  final DateTime timestamp;
  final bool isRead;
  final String category;
  final String sentiment;
  final bool requiresAction;
  final bool containsPersonalInfo;
  final Map<String, dynamic> rawData;
  final List<String> actionIds;
  final String? packageName;
  final String? bigText;
  final String? subText;
  final Map<String, dynamic> metadata;

  NotificationModel({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.app,
    required this.priority,
    required this.summary,
    required this.timestamp,
    this.isRead = false,
    required this.category,
    required this.sentiment,
    this.requiresAction = false,
    this.containsPersonalInfo = false,
    this.rawData = const {},
    this.actionIds = const [],
    this.packageName,
    this.bigText,
    this.subText,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'title': title,
      'body': body,
      'app': app,
      'priority': priority.toString(),
      'summary': summary,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isRead': isRead,
      'category': category,
      'sentiment': sentiment,
      'requiresAction': requiresAction,
      'containsPersonalInfo': containsPersonalInfo,
      'rawData': rawData,
      'actionIds': actionIds,
      'packageName': packageName,
      'bigText': bigText,
      'subText': subText,
      'metadata': metadata,
    };
  }

  factory NotificationModel.fromMap(
      Map<String, dynamic> map, String documentId) {
    return NotificationModel(
      notificationId: documentId,
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      app: map['app'] ?? '',
      priority: NotificationPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => NotificationPriority.medium,
      ),
      summary: map['summary'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      isRead: map['isRead'] ?? false,
      category: map['category'] ?? 'general',
      sentiment: map['sentiment'] ?? 'neutral',
      requiresAction: map['requiresAction'] ?? false,
      containsPersonalInfo: map['containsPersonalInfo'] ?? false,
      rawData: Map<String, dynamic>.from(map['rawData'] ?? {}),
      actionIds: List<String>.from(map['actionIds'] ?? []),
      packageName: map['packageName'],
      bigText: map['bigText'],
      subText: map['subText'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  NotificationModel copyWith({
    String? title,
    String? body,
    String? summary,
    bool? isRead,
    String? category,
    String? sentiment,
    bool? requiresAction,
    bool? containsPersonalInfo,
    List<String>? actionIds,
    Map<String, dynamic>? metadata,
  }) {
    return NotificationModel(
      notificationId: notificationId,
      title: title ?? this.title,
      body: body ?? this.body,
      app: app,
      priority: priority,
      summary: summary ?? this.summary,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      category: category ?? this.category,
      sentiment: sentiment ?? this.sentiment,
      requiresAction: requiresAction ?? this.requiresAction,
      containsPersonalInfo: containsPersonalInfo ?? this.containsPersonalInfo,
      rawData: rawData,
      actionIds: actionIds ?? this.actionIds,
      packageName: packageName,
      bigText: bigText,
      subText: subText,
      metadata: metadata ?? this.metadata,
    );
  }
}

enum NotificationPriority {
  low,
  medium,
  high,
  urgent,
}

class NotificationCategory {
  static const String social = 'social';
  static const String financial = 'financial';
  static const String communication = 'communication';
  static const String entertainment = 'entertainment';
  static const String productivity = 'productivity';
  static const String shopping = 'shopping';
  static const String travel = 'travel';
  static const String health = 'health';
  static const String news = 'news';
  static const String system = 'system';
  static const String other = 'other';
}

class NotificationSentiment {
  static const String positive = 'positive';
  static const String negative = 'negative';
  static const String neutral = 'neutral';
  static const String urgent = 'urgent';
}
