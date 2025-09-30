import 'package:flutter/foundation.dart';
import 'firebase_export_service.dart';
import 'notification_export_service.dart';
import 'call_transcript_export_service.dart';
import 'task_export_service.dart';
import 'event_export_service.dart';

/// Main Firebase Export Coordinator
/// Handles coordinated export of all app data to Firebase for web dashboard access
class FirebaseExportCoordinator {
  static bool _isInitialized = false;
  static bool _isExporting = false;

  /// Initialize the Firebase export system
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('⚠️ Firebase Export System already initialized');
      return;
    }

    try {
      print('🔄 FirebaseExportCoordinator: Starting initialization...');

      // Initialize Firebase collections
      print(
          '🔄 FirebaseExportCoordinator: Initializing Firebase collections...');
      await FirebaseExportService.initializeCollections();
      print('✅ FirebaseExportCoordinator: Firebase collections initialized');

      // Setup real-time exports
      print('🔄 FirebaseExportCoordinator: Setting up real-time exports...');
      _setupRealtimeExports();
      print('✅ FirebaseExportCoordinator: Real-time exports setup complete');

      _isInitialized = true;
      print('✅ Firebase Export System initialized successfully');

      // Ready for manual export when user clicks cloud icon
      print(
          '🔄 FirebaseExportCoordinator: Ready for manual backup when requested');
    } catch (e) {
      print('❌ Error initializing Firebase Export System: $e');
      print('❌ Stack trace: ${e.toString()}');
      throw e;
    }
  }

  /// Export all data to Firebase (full sync)
  static Future<void> exportAllData({bool showProgress = true}) async {
    if (!_isInitialized) {
      print(
          '🔄 FirebaseExportCoordinator: Not initialized, initializing first...');
      await initialize();
    }

    if (_isExporting) {
      print('⚠️ Export already in progress, skipping...');
      return;
    }

    _isExporting = true;

    try {
      print(
          '🚀 FirebaseExportCoordinator: Starting full data export to Firebase...');
      final startTime = DateTime.now();

      // Export all data types in parallel for better performance
      await Future.wait([
        _exportNotificationsWithProgress(showProgress),
        _exportCallTranscriptsWithProgress(showProgress),
        _exportTasksWithProgress(showProgress),
        _exportEventsWithProgress(showProgress),
      ]);

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      print('✅ Full export completed in ${duration.inSeconds}s');

      // Update global metadata
      await _updateGlobalMetadata();
    } catch (e) {
      print('❌ Error during full export: $e');
      throw e;
    } finally {
      _isExporting = false;
    }
  }

  /// Export only recent data (last 7 days)
  static Future<void> exportRecentData() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      print('🔄 Exporting recent data (last 7 days)...');

      await Future.wait([
        NotificationExportService.exportRecentNotifications(days: 7),
        CallTranscriptExportService.exportRecentCalls(days: 7),
        TaskExportService.exportTasksDueSoon(days: 7),
        EventExportService.exportUpcomingEvents(days: 7),
      ]);

      print('✅ Recent data export completed');
    } catch (e) {
      print('❌ Error exporting recent data: $e');
    }
  }

  /// Get comprehensive export statistics for dashboard
  static Future<Map<String, dynamic>> getExportStatistics() async {
    try {
      final stats = await Future.wait([
        NotificationExportService.getExportStats(),
        CallTranscriptExportService.getCallExportStats(),
        TaskExportService.getTaskExportStats(),
        EventExportService.getEventExportStats(),
      ]);

      return {
        'notifications': stats[0],
        'call_transcripts': stats[1],
        'tasks': stats[2],
        'events': stats[3],
        'last_sync': DateTime.now().toIso8601String(),
        'export_status': _isExporting ? 'in_progress' : 'idle',
      };
    } catch (e) {
      print('❌ Error getting export statistics: $e');
      return {
        'error': e.toString(),
        'export_status': 'error',
      };
    }
  }

  /// Clean up old exported data
  static Future<void> cleanupOldData({int daysToKeep = 30}) async {
    try {
      print('🧹 Cleaning up old exported data...');
      await FirebaseExportService.cleanupOldData(daysToKeep: daysToKeep);
      print('✅ Cleanup completed');
    } catch (e) {
      print('❌ Error during cleanup: $e');
    }
  }

  /// Schedule automatic exports
  static void scheduleAutoExport({
    Duration fullExportInterval = const Duration(hours: 24),
    Duration recentExportInterval = const Duration(hours: 1),
  }) {
    print('⏰ Scheduling automatic exports...');

    // Schedule full export (daily)
    Stream.periodic(fullExportInterval, (i) => i).listen((_) {
      exportAllData(showProgress: false);
    });

    // Schedule recent export (hourly)
    Stream.periodic(recentExportInterval, (i) => i).listen((_) {
      exportRecentData();
    });

    print('✅ Automatic export scheduling setup');
  }

  // Private helper methods

  static Future<void> _exportNotificationsWithProgress(
      bool showProgress) async {
    try {
      if (showProgress) print('📱 Exporting notifications...');
      await NotificationExportService.exportAllNotifications();
      if (showProgress) print('✅ Notifications exported');
    } catch (e) {
      print('❌ Error exporting notifications: $e');
    }
  }

  static Future<void> _exportCallTranscriptsWithProgress(
      bool showProgress) async {
    try {
      if (showProgress) print('📞 Exporting call transcripts...');
      await CallTranscriptExportService.exportAllCallTranscripts();
      if (showProgress) print('✅ Call transcripts exported');
    } catch (e) {
      print('❌ Error exporting call transcripts: $e');
    }
  }

  static Future<void> _exportTasksWithProgress(bool showProgress) async {
    try {
      if (showProgress) print('📋 Exporting tasks...');
      await TaskExportService.exportAllTasks();
      if (showProgress) print('✅ Tasks exported');
    } catch (e) {
      print('❌ Error exporting tasks: $e');
    }
  }

  static Future<void> _exportEventsWithProgress(bool showProgress) async {
    try {
      if (showProgress) print('📅 Exporting calendar events...');
      await EventExportService.exportAllEvents();
      if (showProgress) print('✅ Calendar events exported');
    } catch (e) {
      print('❌ Error exporting calendar events: $e');
    }
  }

  static void _setupRealtimeExports() {
    print('🔄 Setting up real-time data exports...');

    try {
      // Setup real-time notification export
      NotificationExportService.setupRealtimeExport();

      // Setup real-time event export
      EventExportService.setupRealtimeEventExport();

      print('✅ Real-time exports configured');
    } catch (e) {
      print('⚠️ Error setting up real-time exports: $e');
    }
  }

  static Future<void> _updateGlobalMetadata() async {
    try {
      final stats = await getExportStatistics();
      await FirebaseExportService.updateDashboardMetadata(
        notificationCount: stats['notifications']?['total_notifications'] ?? 0,
        callCount: stats['call_transcripts']?['total_calls'] ?? 0,
        taskCount: stats['tasks']?['total_tasks'] ?? 0,
        eventCount: stats['events']?['total_events'] ?? 0,
      );
    } catch (e) {
      print('❌ Error updating global metadata: $e');
    }
  }

  /// Get export status
  static bool get isExporting => _isExporting;
  static bool get isInitialized => _isInitialized;
}
