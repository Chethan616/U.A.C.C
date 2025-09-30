import 'package:googleapis/tasks/v1.dart' as tasks;
import 'google_auth_service.dart';

class TasksService {
  static final TasksService _instance = TasksService._internal();
  factory TasksService() => _instance;
  TasksService._internal();

  tasks.TasksApi? _tasksApi;
  final GoogleAuthService _authService = GoogleAuthService();

  Future<void> initialize() async {
    try {
      // Initialize the auth service first
      _authService.initialize();

      // Ensure user is signed in first
      if (!_authService.isSignedIn) {
        print("User not signed in, attempting to sign in for Tasks API...");
        final success = await _authService.signIn();
        if (!success) {
          print("Failed to sign in user for Tasks API");
          return;
        }
      }

      final client = await _authService.getAuthenticatedClient();
      if (client != null) {
        _tasksApi = tasks.TasksApi(client);
        print("Tasks API initialized successfully");
      } else {
        print("Failed to get authenticated client for Tasks API");
      }
    } catch (e) {
      print("Error initializing Tasks API: $e");
      _tasksApi = null;
    }
  }

  Future<List<TaskItem>> getAllTasks() async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) return [];

    try {
      // Get all task lists
      final taskLists = await _tasksApi!.tasklists.list();
      print("📋 Found ${taskLists.items?.length ?? 0} task lists");

      List<TaskItem> allTasks = [];

      for (final taskList in taskLists.items ?? []) {
        if (taskList.id != null) {
          final listId = taskList.id!;
          final listTitle = taskList.title ?? 'Default';
          print("📋 Processing task list: $listTitle (ID: $listId)");

          final tasksInList = await _tasksApi!.tasks.list(listId);
          print(
              "   📝 Found ${tasksInList.items?.length ?? 0} tasks in this list");

          for (final task in tasksInList.items ?? []) {
            print("   📝 Task: '${task.title}' (ID: ${task.id})");
            allTasks.add(TaskItem.fromGoogleTask(task, listId, listTitle));
          }
        }
      }

      print("✅ Total tasks loaded: ${allTasks.length}");
      return allTasks;
    } catch (e) {
      print("❌ Error fetching all tasks: $e");
      return [];
    }
  }

  Future<List<TaskItem>> getDueTodayTasks() async {
    final allTasks = await getAllTasks();
    final today = DateTime.now();

    return allTasks.where((task) {
      if (task.dueDate == null) return false;

      final dueDate = task.dueDate!;
      return dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day;
    }).toList();
  }

  Future<List<TaskItem>> getOverdueTasks() async {
    final allTasks = await getAllTasks();
    final today = DateTime.now();

    return allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      return task.dueDate!.isBefore(today);
    }).toList();
  }

  Future<List<TaskItem>> getUpcomingTasks({int days = 7}) async {
    final allTasks = await getAllTasks();
    final today = DateTime.now();
    final futureDate = today.add(Duration(days: days));

    return allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      return task.dueDate!.isAfter(today) && task.dueDate!.isBefore(futureDate);
    }).toList();
  }

  Future<List<TaskItem>> getHighPriorityTasks() async {
    final allTasks = await getAllTasks();

    return allTasks.where((task) {
      if (task.isCompleted) return false;

      // Check if task title/description contains urgency keywords
      final text = '${task.title} ${task.description}'.toLowerCase();
      final urgentKeywords = [
        'urgent',
        'asap',
        'critical',
        'important',
        'priority',
        'deadline'
      ];

      return urgentKeywords.any((keyword) => text.contains(keyword));
    }).toList();
  }

  Future<TaskStats> getTaskStats() async {
    final allTasks = await getAllTasks();
    final today = DateTime.now();

    int completed = allTasks.where((task) => task.isCompleted).length;
    int pending = allTasks.where((task) => !task.isCompleted).length;
    int dueToday = allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      final dueDate = task.dueDate!;
      return dueDate.year == today.year &&
          dueDate.month == today.month &&
          dueDate.day == today.day;
    }).length;

    int overdue = allTasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      return task.dueDate!.isBefore(today);
    }).length;

    return TaskStats(
      totalTasks: allTasks.length,
      completedTasks: completed,
      pendingTasks: pending,
      dueTodayTasks: dueToday,
      overdueTasks: overdue,
    );
  }

  Future<bool> markTaskCompleted(String taskListId, String taskId) async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) return false;

    try {
      // Debug: Print the IDs being used
      print("🔍 Attempting to mark task completed:");
      print("   Task List ID: $taskListId");
      print("   Task ID: $taskId");

      // First, get the existing task to verify it exists
      final existingTask = await _tasksApi!.tasks.get(taskListId, taskId);
      print("✅ Found existing task: ${existingTask.title}");

      // Create UTC DateTime properly for Google Tasks API
      final utcNow = DateTime.now().toUtc();

      final updatedTask = tasks.Task()
        ..status = 'completed'
        ..completed = utcNow.toIso8601String();

      await _tasksApi!.tasks.patch(updatedTask, taskListId, taskId);
      print("✅ Task marked as completed successfully");
      return true;
    } catch (e) {
      print("❌ Error marking task completed: $e");
      print("   Task List ID: $taskListId");
      print("   Task ID: $taskId");
      return false;
    }
  }

  Future<bool> markTaskNeedsAction(String taskListId, String taskId) async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) return false;

    try {
      // Debug: Print the IDs being used
      print("🔍 Attempting to mark task as needs action:");
      print("   Task List ID: $taskListId");
      print("   Task ID: $taskId");

      // First, get the existing task to verify it exists
      final existingTask = await _tasksApi!.tasks.get(taskListId, taskId);
      print("✅ Found existing task: ${existingTask.title}");

      final updatedTask = tasks.Task()
        ..status = 'needsAction'
        ..completed = null;

      await _tasksApi!.tasks.patch(updatedTask, taskListId, taskId);
      print("✅ Task marked as needs action successfully");
      return true;
    } catch (e) {
      print("❌ Error reverting task to needsAction: $e");
      print("   Task List ID: $taskListId");
      print("   Task ID: $taskId");
      return false;
    }
  }

  Future<bool> updateTask({
    required String taskListId,
    required String taskId,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) return false;

    try {
      final task = tasks.Task();

      if (title != null) {
        task.title = title;
      }
      if (description != null) {
        task.notes = description;
      }
      if (dueDate != null) {
        task.due = dueDate.toUtc().toIso8601String();
      }
      if (isCompleted != null) {
        task.status = isCompleted ? 'completed' : 'needsAction';
        task.completed =
            isCompleted ? DateTime.now().toUtc().toIso8601String() : null;
      }

      await _tasksApi!.tasks.patch(task, taskListId, taskId);
      return true;
    } catch (e) {
      print("Error updating task: $e");
      return false;
    }
  }

  Future<bool> deleteTask(String taskListId, String taskId) async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) return false;

    try {
      await _tasksApi!.tasks.delete(taskListId, taskId);
      return true;
    } catch (e) {
      print("Error deleting task: $e");
      return false;
    }
  }

  /// Create a new task
  Future<String?> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    String? taskListId,
  }) async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) return null;

    try {
      // Get the default task list if none specified
      String? targetListId = taskListId;
      if (targetListId == null) {
        targetListId = await getDefaultTaskListId();
        if (targetListId == null) {
          print("❌ No task lists available for creating task");
          return null;
        }
      }

      print("📝 Creating task in list ID: $targetListId");
      print("   Title: $title");
      print("   Description: $description");
      print("   Due Date: $dueDate");

      final task = tasks.Task()
        ..title = title
        ..notes = description;

      // Handle due date with proper UTC conversion
      if (dueDate != null) {
        // Convert to UTC and format as RFC 3339 string
        final utcDueDate = dueDate.toUtc();
        task.due = utcDueDate.toIso8601String();
      }

      final createdTask = await _tasksApi!.tasks.insert(task, targetListId);
      print("✅ Task created successfully with ID: ${createdTask.id}");
      return createdTask.id;
    } catch (e) {
      print("❌ Error creating task: $e");
      return null;
    }
  }

  /// Get the default task list ID
  Future<String?> getDefaultTaskListId() async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) return null;

    try {
      final taskLists = await _tasksApi!.tasklists.list();

      // Look for a default task list or take the first one
      for (final taskList in taskLists.items ?? []) {
        if (taskList.title?.toLowerCase().contains('my tasks') == true ||
            taskList.title?.toLowerCase().contains('default') == true) {
          print(
              "📋 Found default task list: '${taskList.title}' (ID: ${taskList.id})");
          return taskList.id;
        }
      }

      // If no default found, use the first one
      if (taskLists.items?.isNotEmpty == true) {
        final firstList = taskLists.items!.first;
        print(
            "📋 Using first task list as default: '${firstList.title}' (ID: ${firstList.id})");
        return firstList.id;
      }

      print("❌ No task lists found");
      return null;
    } catch (e) {
      print("❌ Error getting default task list: $e");
      return null;
    }
  }

  /// Debug method to list all task lists and their tasks with IDs
  Future<void> debugListAllTasksWithIds() async {
    if (_tasksApi == null) await initialize();
    if (_tasksApi == null) {
      print("❌ TasksApi not initialized");
      return;
    }

    try {
      print("\n📋 === DEBUG: All Task Lists and Tasks ===");

      final taskLists = await _tasksApi!.tasklists.list();
      print("📋 Found ${taskLists.items?.length ?? 0} task lists:");

      for (final taskList in taskLists.items ?? []) {
        print("\n📋 Task List: '${taskList.title}' (ID: ${taskList.id})");

        if (taskList.id != null) {
          final tasksInList = await _tasksApi!.tasks.list(taskList.id!);
          print("   📝 Tasks in this list: ${tasksInList.items?.length ?? 0}");

          for (final task in tasksInList.items ?? []) {
            print(
                "   📝 Task: '${task.title}' (ID: ${task.id}) [Status: ${task.status}]");
          }
        }
      }
      print("📋 === End Debug List ===\n");
    } catch (e) {
      print("❌ Error in debug list: $e");
    }
  }

  bool get isInitialized => _tasksApi != null;
}

class TaskItem {
  final String id;
  final String taskListId;
  final String taskListName;
  final String title;
  final String description;
  final DateTime? dueDate;
  final DateTime? completedDate;
  final bool isCompleted;
  final DateTime? updatedDate;
  final String? notes;
  final List<TaskLink> links;

  TaskItem({
    required this.id,
    required this.taskListId,
    required this.taskListName,
    required this.title,
    required this.description,
    this.dueDate,
    this.completedDate,
    required this.isCompleted,
    this.updatedDate,
    this.notes,
    required this.links,
  });

  factory TaskItem.fromGoogleTask(
      tasks.Task task, String taskListId, String taskListName) {
    // Helper method to safely parse DateTime from Google API strings
    DateTime? safeParseDatetime(String? dateTimeString) {
      if (dateTimeString == null || dateTimeString.isEmpty) return null;
      try {
        // Parse and ensure we handle UTC properly
        final parsed = DateTime.tryParse(dateTimeString);
        return parsed?.toLocal(); // Convert to local timezone for display
      } catch (e) {
        print("Error parsing datetime '$dateTimeString': $e");
        return null;
      }
    }

    return TaskItem(
      id: task.id ?? '',
      taskListId: taskListId,
      taskListName: taskListName,
      title: task.title ?? 'Untitled Task',
      description: task.notes ?? '',
      dueDate: safeParseDatetime(task.due),
      completedDate: safeParseDatetime(task.completed),
      isCompleted: task.status == 'completed',
      updatedDate: safeParseDatetime(task.updated),
      notes: task.notes,
      links: (task.links ?? [])
          .map((link) => TaskLink.fromGoogleLink(link))
          .toList(),
    );
  }

  bool get isDueToday {
    if (dueDate == null) return false;
    final today = DateTime.now();
    return dueDate!.year == today.year &&
        dueDate!.month == today.month &&
        dueDate!.day == today.day;
  }

  bool get isOverdue {
    if (dueDate == null || isCompleted) return false;
    return dueDate!.isBefore(DateTime.now());
  }

  bool get isUpcoming {
    if (dueDate == null || isCompleted) return false;
    final today = DateTime.now();
    final nextWeek = today.add(Duration(days: 7));
    return dueDate!.isAfter(today) && dueDate!.isBefore(nextWeek);
  }

  String get dueDateString {
    if (dueDate == null) return 'No due date';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);

    final difference = taskDate.difference(today).inDays;

    if (difference == 0) return 'Due today';
    if (difference == 1) return 'Due tomorrow';
    if (difference == -1) return 'Due yesterday';
    if (difference < -1) return 'Overdue (${difference.abs()} days)';
    if (difference < 7) return 'Due in $difference days';

    return 'Due ${dueDate!.day}/${dueDate!.month}';
  }

  TaskPriority get priority {
    final text = '$title $description'.toLowerCase();

    if (text.contains('urgent') ||
        text.contains('asap') ||
        text.contains('critical')) {
      return TaskPriority.urgent;
    }
    if (text.contains('important') ||
        text.contains('priority') ||
        text.contains('deadline')) {
      return TaskPriority.high;
    }
    if (isOverdue) {
      return TaskPriority.high;
    }
    if (isDueToday) {
      return TaskPriority.normal;
    }

    return TaskPriority.low;
  }

  @override
  String toString() => '$title (${dueDateString})';
}

class TaskLink {
  final String type;
  final String description;
  final String link;

  TaskLink({
    required this.type,
    required this.description,
    required this.link,
  });

  factory TaskLink.fromGoogleLink(dynamic link) {
    return TaskLink(
      type: link.type ?? 'link',
      description: link.description ?? '',
      link: link.link ?? '',
    );
  }
}

enum TaskPriority {
  low,
  normal,
  high,
  urgent,
}

class TaskStats {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int dueTodayTasks;
  final int overdueTasks;

  TaskStats({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.dueTodayTasks,
    required this.overdueTasks,
  });

  double get completionRate =>
      totalTasks > 0 ? completedTasks / totalTasks : 0.0;

  @override
  String toString() {
    return 'TaskStats(total: $totalTasks, completed: $completedTasks, pending: $pendingTasks, due today: $dueTodayTasks, overdue: $overdueTasks)';
  }
}
