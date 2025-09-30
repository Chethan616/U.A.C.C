import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/tasks_service.dart';
import 'firebase_export_service.dart';

/// Task Export Service
/// Handles exporting task data to Firebase for web dashboard
class TaskExportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Export all tasks to Firebase
  static Future<void> exportAllTasks() async {
    try {
      print('🔄 Starting task export...');

      // Get tasks from Google Tasks service
      final tasksService = TasksService();
      await tasksService.initialize();
      final googleTasks = await tasksService.getAllTasks();

      if (googleTasks.isEmpty) {
        print('ℹ️ No tasks to export');
        return;
      }

      int exportedCount = 0;

      for (final task in googleTasks) {
        final success = await FirebaseExportService.exportTask(task);
        if (success) exportedCount++;
      }

      // Update dashboard metadata
      await FirebaseExportService.updateDashboardMetadata(
        taskCount: exportedCount,
      );

      print(
          '✅ Exported $exportedCount/${googleTasks.length} tasks to Firebase');
    } catch (e) {
      print('❌ Error exporting tasks: $e');
    }
  }

  /// Export a single task (real-time)
  static Future<void> exportSingleTask(TaskItem taskItem) async {
    try {
      await FirebaseExportService.exportTask(taskItem);
      print('✅ Exported task: ${taskItem.title}');
    } catch (e) {
      print('❌ Error exporting single task: $e');
    }
  }

  /// Export tasks by completion status
  static Future<void> exportTasksByStatus({required bool isCompleted}) async {
    try {
      final tasksService = TasksService();
      await tasksService.initialize();
      final allTasks = await tasksService.getAllTasks();
      final filteredTasks =
          allTasks.where((task) => task.isCompleted == isCompleted).toList();

      if (filteredTasks.isEmpty) {
        final status = isCompleted ? 'completed' : 'pending';
        print('ℹ️ No $status tasks found');
        return;
      }

      int exportedCount = 0;
      for (final task in filteredTasks) {
        final success = await FirebaseExportService.exportTask(task);
        if (success) exportedCount++;
      }

      final status = isCompleted ? 'completed' : 'pending';
      print('✅ Exported $exportedCount $status tasks');
    } catch (e) {
      print('❌ Error exporting tasks by status: $e');
    }
  }

  /// Export tasks due within N days
  static Future<void> exportTasksDueSoon({int days = 7}) async {
    try {
      final futureDate = DateTime.now().add(Duration(days: days));
      final tasksService = TasksService();
      await tasksService.initialize();
      final allTasks = await tasksService.getAllTasks();

      final dueSoonTasks = allTasks.where((task) {
        if (task.dueDate == null) return false;
        return task.dueDate!.isBefore(futureDate) && !task.isCompleted;
      }).toList();

      if (dueSoonTasks.isEmpty) {
        print('ℹ️ No tasks due in next $days days');
        return;
      }

      int exportedCount = 0;
      for (final task in dueSoonTasks) {
        final success = await FirebaseExportService.exportTask(task);
        if (success) exportedCount++;
      }

      print('✅ Exported $exportedCount tasks due within $days days');
    } catch (e) {
      print('❌ Error exporting tasks due soon: $e');
    }
  }

  /// Get task export statistics
  static Future<Map<String, dynamic>> getTaskExportStats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('❌ No authenticated user for task export stats');
        return {
          'total_tasks': 0,
          'completed_tasks': 0,
          'pending_tasks': 0,
          'overdue_tasks': 0,
          'error': 'No authenticated user',
        };
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(FirebaseExportService.tasksCollection)
          .get();

      final docs = snapshot.docs;
      final totalCount = docs.length;

      int completedCount = 0;
      int pendingCount = 0;
      int overdueCount = 0;
      final now = DateTime.now();

      for (final doc in docs) {
        final data = doc.data();
        final isCompleted = data['is_completed'] as bool? ?? false;
        final dueDateTimestamp = data['due_date'] as Timestamp?;

        if (isCompleted) {
          completedCount++;
        } else {
          pendingCount++;
          if (dueDateTimestamp != null) {
            final dueDate = dueDateTimestamp.toDate();
            if (dueDate.isBefore(now)) {
              overdueCount++;
            }
          }
        }
      }

      return {
        'total_tasks': totalCount,
        'completed_tasks': completedCount,
        'pending_tasks': pendingCount,
        'overdue_tasks': overdueCount,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting task export stats: $e');
      return {
        'total_tasks': 0,
        'completed_tasks': 0,
        'pending_tasks': 0,
        'overdue_tasks': 0,
        'error': e.toString(),
      };
    }
  }
}
