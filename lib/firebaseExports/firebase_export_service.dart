import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart';
import '../models/call.dart';
import '../services/tasks_service.dart';
import '../services/calendar_service.dart';

/// Main Firebase Export Service
/// Coordinates all data exports to Firebase collections for web dashboard access
class FirebaseExportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection names (now used as subcollections under users/{userId})
  static const String notificationsCollection = 'notifications';
  static const String callTranscriptsCollection = 'call_transcripts';
  static const String tasksCollection = 'tasks';
  static const String eventsCollection = 'events';
  static const String userMetadataCollection = 'user_metadata';
  static const String usersCollection = 'users';

  /// Get current user ID
  static String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Initialize all collections with proper indexes and metadata
  static Future<void> initializeCollections() async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No authenticated user for collection initialization');
        return;
      }

      // Create metadata document for dashboard
      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(userMetadataCollection)
          .doc('dashboard_info')
          .set({
        'last_updated': FieldValue.serverTimestamp(),
        'collections': {
          'notifications': notificationsCollection,
          'call_transcripts': callTranscriptsCollection,
          'tasks': tasksCollection,
          'events': eventsCollection,
        },
        'app_version': '1.0.0',
        'initialized_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Firebase collections initialized for dashboard');
    } catch (e) {
      print('❌ Error initializing Firebase collections: $e');
    }
  }

  /// Export notification data to Firebase
  static Future<bool> exportNotification(NotificationModel notification) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No authenticated user for notification export');
        return false;
      }

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(notificationsCollection)
          .doc(notification.notificationId)
          .set({
        'id': notification.notificationId,
        'app_name': notification.app,
        'title': notification.title,
        'body': notification.body,
        'big_text': notification.bigText,
        'category': notification.category,
        'timestamp': Timestamp.fromDate(notification.timestamp),
        'is_read': notification.isRead,
        'priority': notification.priority.toString().split('.').last,
        'ai_summary': notification.summary,
        'sentiment': notification.sentiment,
        'requires_action': notification.requiresAction,
        'contains_personal_info': notification.containsPersonalInfo,
        'package_name': notification.packageName,
        'sub_text': notification.subText,
        'exported_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Exported notification: ${notification.title}');
      return true;
    } catch (e) {
      print('❌ Error exporting notification: $e');
      return false;
    }
  }

  /// Export call transcript data to Firebase
  static Future<bool> exportCallTranscript(Call callData) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No authenticated user for call transcript export');
        return false;
      }

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(callTranscriptsCollection)
          .doc('call_${callData.timestamp.millisecondsSinceEpoch}')
          .set({
        'contact_name': callData.contactName,
        'call_id': callData.callId,
        'timestamp': Timestamp.fromDate(callData.timestamp),
        'duration_seconds': callData.durationSecs,
        'call_type': callData.callType.toString().split('.').last,
        'transcript': callData.transcript,
        'summary': callData.summary,
        'key_points': callData.keyPoints,
        'sentiment': callData.sentiment,
        'category': callData.category,
        'priority': callData.priority.toString().split('.').last,
        'participants': callData.participants,
        'processed_by': callData.processedBy,
        'audio_storage_path': callData.audioStoragePath,
        'status': callData.status.toString().split('.').last,
        'exported_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Exported call transcript: ${callData.contactName}');
      return true;
    } catch (e) {
      print('❌ Error exporting call transcript: $e');
      return false;
    }
  }

  /// Export task data to Firebase
  static Future<bool> exportTask(TaskItem task) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No authenticated user for task export');
        return false;
      }

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(tasksCollection)
          .doc(task.id)
          .set({
        'id': task.id,
        'title': task.title,
        'description': task.description,
        'due_date':
            task.dueDate != null ? Timestamp.fromDate(task.dueDate!) : null,
        'is_completed': task.isCompleted,
        'priority': task.priority.toString().split('.').last,
        'task_list_id': task.taskListId,
        'task_list_name': task.taskListName,
        'updated_date': task.updatedDate != null
            ? Timestamp.fromDate(task.updatedDate!)
            : null,
        'completed_date': task.completedDate != null
            ? Timestamp.fromDate(task.completedDate!)
            : null,
        'source': 'mobile_app', // Identifier for mobile vs web
        'exported_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Exported task: ${task.title}');
      return true;
    } catch (e) {
      print('❌ Error exporting task: $e');
      return false;
    }
  }

  /// Export event/calendar data to Firebase
  static Future<bool> exportEvent(CalendarEvent event) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No authenticated user for event export');
        return false;
      }

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(eventsCollection)
          .doc(event.id)
          .set({
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'start_time': Timestamp.fromDate(event.startTime),
        'end_time': Timestamp.fromDate(event.endTime),
        'location': event.location,
        'attendees': event.attendees,
        'is_all_day': event.isAllDay,
        'priority': event.priority.toString().split('.').last,
        'meeting_link': event.meetingLink,
        'created_at': Timestamp.fromDate(event.createdAt),
        'updated_at': event.updatedAt != null
            ? Timestamp.fromDate(event.updatedAt!)
            : null,
        'source': 'mobile_app',
        'exported_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      print('✅ Exported event: ${event.title}');
      return true;
    } catch (e) {
      print('❌ Error exporting event: $e');
      return false;
    }
  }

  /// Batch export multiple items
  static Future<void> batchExportNotifications(
      List<NotificationModel> notifications) async {
    final userId = _currentUserId;
    if (userId == null) {
      print('❌ No authenticated user for batch notification export');
      return;
    }

    final batch = _firestore.batch();

    for (final notification in notifications) {
      final docRef = _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(notificationsCollection)
          .doc(notification.notificationId);
      batch.set(
          docRef,
          {
            'id': notification.notificationId,
            'app_name': notification.app,
            'title': notification.title,
            'body': notification.body,
            'timestamp': Timestamp.fromDate(notification.timestamp),
            'is_read': notification.isRead,
            'priority': notification.priority.toString().split('.').last,
            'ai_summary': notification.summary,
            'category': notification.category,
            'exported_at': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true));
    }

    try {
      await batch.commit();
      print('✅ Batch exported ${notifications.length} notifications');
    } catch (e) {
      print('❌ Error in batch export: $e');
    }
  }

  /// Update dashboard metadata with latest sync info
  static Future<void> updateDashboardMetadata({
    int? notificationCount,
    int? callCount,
    int? taskCount,
    int? eventCount,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No authenticated user for dashboard metadata update');
        return;
      }

      await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(userMetadataCollection)
          .doc('dashboard_stats')
          .set({
        'last_sync': FieldValue.serverTimestamp(),
        'notification_count': notificationCount,
        'call_transcript_count': callCount,
        'task_count': taskCount,
        'event_count': eventCount,
        'sync_version': '1.0',
      }, SetOptions(merge: true));
    } catch (e) {
      print('❌ Error updating dashboard metadata: $e');
    }
  }

  /// Delete old exported data (cleanup)
  static Future<void> cleanupOldData({int daysToKeep = 30}) async {
    try {
      final userId = _currentUserId;
      if (userId == null) {
        print('❌ No authenticated user for data cleanup');
        return;
      }

      final cutoffDate = Timestamp.fromDate(
          DateTime.now().subtract(Duration(days: daysToKeep)));

      // Clean up old notifications
      final oldNotifications = await _firestore
          .collection(usersCollection)
          .doc(userId)
          .collection(notificationsCollection)
          .where('exported_at', isLessThan: cutoffDate)
          .limit(100)
          .get();

      final batch = _firestore.batch();
      for (final doc in oldNotifications.docs) {
        batch.delete(doc.reference);
      }

      if (oldNotifications.docs.isNotEmpty) {
        await batch.commit();
        print(
            '🧹 Cleaned up ${oldNotifications.docs.length} old notifications');
      }
    } catch (e) {
      print('❌ Error cleaning up old data: $e');
    }
  }
}
