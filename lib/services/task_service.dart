import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' show Client;
import 'package:googleapis/tasks/v1.dart' as tasks;

class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool completed;
  final TaskPriority priority;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.completed = false,
    this.priority = TaskPriority.normal,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? dueDate,
    bool? completed,
    TaskPriority? priority,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      completed: completed ?? this.completed,
      priority: priority ?? this.priority,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum TaskPriority {
  low,
  normal,
  high,
  urgent,
}

class TaskService {
  static const MethodChannel _channel = MethodChannel('com.example.uacc/tasks');

  // Google Sign-In for Google Tasks integration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/tasks',
      'https://www.googleapis.com/auth/calendar',
    ],
  );

  /// Get all tasks from local storage and Google Tasks
  static Future<List<Task>> getTasks() async {
    try {
      // Try to get tasks from Google Tasks API first
      final googleTasks = await _getGoogleTasks();
      if (googleTasks.isNotEmpty) {
        return googleTasks;
      }

      // Fallback to local tasks
      final List<dynamic> tasksData = await _channel.invokeMethod('getTasks');

      return tasksData.map((taskData) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(taskData);

        return Task(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          description: data['description'],
          dueDate: data['dueDate'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['dueDate'])
              : null,
          completed: data['completed'] ?? false,
          priority: _parsePriority(data['priority']),
          notes: data['notes'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(
              data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
          updatedAt: data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error getting tasks: $e');
      return _getMockTasks();
    }
  }

  /// Create a new task
  static Future<Task> createTask({
    required String title,
    String? description,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.normal,
    String? notes,
  }) async {
    try {
      final taskData = {
        'title': title,
        'description': description,
        'dueDate': dueDate?.millisecondsSinceEpoch,
        'priority': priority.name,
        'notes': notes,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Try to create in Google Tasks first
      final googleTask = await _createGoogleTask(title, description, dueDate);
      if (googleTask != null) {
        return googleTask;
      }

      // Fallback to local storage
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('createTask', taskData);

      return Task(
        id: result['id'],
        title: result['title'],
        description: result['description'],
        dueDate: result['dueDate'] != null
            ? DateTime.fromMillisecondsSinceEpoch(result['dueDate'])
            : null,
        completed: result['completed'] ?? false,
        priority: _parsePriority(result['priority']),
        notes: result['notes'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(result['createdAt']),
        updatedAt: result['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(result['updatedAt'])
            : null,
      );
    } catch (e) {
      print('Error creating task: $e');
      throw Exception('Failed to create task');
    }
  }

  /// Update an existing task
  static Future<Task> updateTask(Task task) async {
    try {
      final taskData = {
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'dueDate': task.dueDate?.millisecondsSinceEpoch,
        'completed': task.completed,
        'priority': task.priority.name,
        'notes': task.notes,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _channel.invokeMethod('updateTask', taskData);

      return task.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      print('Error updating task: $e');
      throw Exception('Failed to update task');
    }
  }

  /// Delete a task
  static Future<void> deleteTask(String taskId) async {
    try {
      await _channel.invokeMethod('deleteTask', {'taskId': taskId});
    } catch (e) {
      print('Error deleting task: $e');
      throw Exception('Failed to delete task');
    }
  }

  /// Get task statistics
  static Future<Map<String, int>> getTaskStats() async {
    try {
      final Map<dynamic, dynamic> stats =
          await _channel.invokeMethod('getTaskStats');
      return Map<String, int>.from(stats);
    } catch (e) {
      print('Error getting task stats: $e');
      return {
        'totalTasks': 12,
        'completedTasks': 4,
        'pendingTasks': 8,
        'overdueTasks': 2,
        'todayTasks': 3,
      };
    }
  }

  /// Sign in to Google for Google Tasks/Calendar integration
  static Future<bool> signInToGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }

  /// Sign out from Google
  static Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  /// Check if signed in to Google
  static Future<bool> isSignedInToGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      return account != null;
    } catch (e) {
      print('Error checking Google sign-in: $e');
      return false;
    }
  }

  // Private methods for Google Tasks integration
  static Future<List<Task>> _getGoogleTasks() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) return [];

      final headers = await account.authHeaders;
      final client = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken(
              'Bearer',
              headers['Authorization']!.replaceAll('Bearer ', ''),
              DateTime.now().toUtc().add(const Duration(hours: 1))),
          null,
          ['https://www.googleapis.com/auth/tasks'],
        ),
      );

      final tasksApi = tasks.TasksApi(client);
      final taskLists = await tasksApi.tasklists.list();

      List<Task> allTasks = [];

      for (final taskList in taskLists.items ?? []) {
        final taskItems = await tasksApi.tasks.list(taskList.id!);

        for (final taskItem in taskItems.items ?? []) {
          allTasks.add(Task(
            id: taskItem.id!,
            title: taskItem.title ?? '',
            description: taskItem.notes,
            dueDate:
                taskItem.due != null ? DateTime.parse(taskItem.due!) : null,
            completed: taskItem.status == 'completed',
            priority: TaskPriority.normal, // Google Tasks doesn't have priority
            notes: taskItem.notes,
            createdAt: DateTime.now(), // Approximate
          ));
        }
      }

      client.close();
      return allTasks;
    } catch (e) {
      print('Error getting Google Tasks: $e');
      return [];
    }
  }

  static Future<Task?> _createGoogleTask(
      String title, String? description, DateTime? dueDate) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) return null;

      final headers = await account.authHeaders;
      final client = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken(
              'Bearer',
              headers['Authorization']!.replaceAll('Bearer ', ''),
              DateTime.now().toUtc().add(const Duration(hours: 1))),
          null,
          ['https://www.googleapis.com/auth/tasks'],
        ),
      );

      final tasksApi = tasks.TasksApi(client);
      final taskLists = await tasksApi.tasklists.list();

      if (taskLists.items != null && taskLists.items!.isNotEmpty) {
        final newTask = tasks.Task()
          ..title = title
          ..notes = description
          ..due = dueDate?.toIso8601String();

        final createdTask =
            await tasksApi.tasks.insert(newTask, taskLists.items!.first.id!);

        client.close();

        return Task(
          id: createdTask.id!,
          title: createdTask.title!,
          description: createdTask.notes,
          dueDate:
              createdTask.due != null ? DateTime.parse(createdTask.due!) : null,
          completed: createdTask.status == 'completed',
          priority: TaskPriority.normal,
          notes: createdTask.notes,
          createdAt: DateTime.now(),
        );
      }

      client.close();
      return null;
    } catch (e) {
      print('Error creating Google Task: $e');
      return null;
    }
  }

  static TaskPriority _parsePriority(dynamic priority) {
    switch (priority) {
      case 'low':
        return TaskPriority.low;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.normal;
    }
  }

  // Mock data for fallback
  static List<Task> _getMockTasks() {
    final now = DateTime.now();
    return [
      Task(
        id: '1',
        title: 'Call client about project update',
        description: 'Discuss the new requirements and timeline',
        dueDate: now.add(const Duration(hours: 2)),
        priority: TaskPriority.high,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      Task(
        id: '2',
        title: 'Review presentation slides',
        description: 'Check formatting and content for tomorrow\'s meeting',
        dueDate: now.add(const Duration(hours: 5)),
        priority: TaskPriority.normal,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: '3',
        title: 'Book flight tickets',
        description: 'For the business trip next month',
        dueDate: now.add(const Duration(days: 3)),
        priority: TaskPriority.normal,
        createdAt: now.subtract(const Duration(hours: 6)),
      ),
      Task(
        id: '4',
        title: 'Grocery shopping',
        description: 'Milk, bread, eggs, vegetables',
        dueDate: now.add(const Duration(days: 1)),
        priority: TaskPriority.low,
        createdAt: now.subtract(const Duration(hours: 3)),
      ),
      Task(
        id: '5',
        title: 'Pay electricity bill',
        description: 'Due amount: ₹2,450',
        dueDate: now.add(const Duration(hours: 12)),
        priority: TaskPriority.urgent,
        createdAt: now.subtract(const Duration(hours: 8)),
      ),
      Task(
        id: '6',
        title: 'Doctor appointment',
        description: 'Annual health checkup',
        dueDate: now.add(const Duration(days: 5)),
        priority: TaskPriority.high,
        createdAt: now.subtract(const Duration(days: 3)),
        completed: true,
      ),
      Task(
        id: '7',
        title: 'Finish project documentation',
        description: 'Complete API documentation and user guide',
        dueDate: now.add(const Duration(days: 7)),
        priority: TaskPriority.high,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
      Task(
        id: '8',
        title: 'Team meeting preparation',
        description: 'Prepare agenda and reports',
        dueDate: now.subtract(const Duration(hours: 2)), // Overdue
        priority: TaskPriority.urgent,
        createdAt: now.subtract(const Duration(days: 2)),
      ),
    ];
  }
}
