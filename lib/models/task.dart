// lib/models/task.dart
class Task {
  final String taskId;
  final String title;
  final String description;
  final DateTime? dueDate;
  final bool completed;
  final TaskSource source;
  final String sourceRef;
  final TaskPriority priority;
  final String category;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<String> tags;
  final String? assignedTo;
  final Map<String, dynamic> metadata;

  Task({
    required this.taskId,
    required this.title,
    required this.description,
    this.dueDate,
    this.completed = false,
    required this.source,
    required this.sourceRef,
    required this.priority,
    required this.category,
    required this.createdAt,
    this.completedAt,
    this.tags = const [],
    this.assignedTo,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'title': title,
      'description': description,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'completed': completed,
      'source': source.toString(),
      'sourceRef': sourceRef,
      'priority': priority.toString(),
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
      'tags': tags,
      'assignedTo': assignedTo,
      'metadata': metadata,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map, String documentId) {
    return Task(
      taskId: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dueDate: map['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['dueDate'])
          : null,
      completed: map['completed'] ?? false,
      source: TaskSource.values.firstWhere(
        (e) => e.toString() == map['source'],
        orElse: () => TaskSource.manual,
      ),
      sourceRef: map['sourceRef'] ?? '',
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == map['priority'],
        orElse: () => TaskPriority.medium,
      ),
      category: map['category'] ?? 'general',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      completedAt: map['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['completedAt'])
          : null,
      tags: List<String>.from(map['tags'] ?? []),
      assignedTo: map['assignedTo'],
      metadata: Map<String, dynamic>.from(map['metadata'] ?? {}),
    );
  }

  Task copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? completed,
    TaskPriority? priority,
    String? category,
    DateTime? completedAt,
    List<String>? tags,
    String? assignedTo,
    Map<String, dynamic>? metadata,
  }) {
    return Task(
      taskId: taskId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      source: source,
      sourceRef: sourceRef,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      tags: tags ?? this.tags,
      assignedTo: assignedTo ?? this.assignedTo,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isOverdue {
    if (dueDate == null || completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final now = DateTime.now();
    final due = dueDate!;
    return now.year == due.year && now.month == due.month && now.day == due.day;
  }
}

enum TaskSource {
  call,
  notification,
  manual,
  ai_generated,
  calendar,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class TaskCategory {
  static const String personal = 'personal';
  static const String work = 'work';
  static const String finance = 'finance';
  static const String health = 'health';
  static const String shopping = 'shopping';
  static const String travel = 'travel';
  static const String communication = 'communication';
  static const String general = 'general';
}
