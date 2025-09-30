import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification.dart' as model;
import '../services/notification_service.dart' as service;
import 'firebase_export_service.dart';

/// Notification Export Service
/// Handles exporting notification data to Firebase for web dashboard
class NotificationExportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Convert AppNotification to NotificationModel for export
  static model.NotificationModel _convertToNotificationModel(
      service.AppNotification appNotification) {
    return model.NotificationModel(
      notificationId: appNotification.id,
      title: appNotification.title,
      body: appNotification.content,
      app: appNotification.appName,
      priority: _convertPriority(appNotification.priority),
      summary: 'Auto-generated from ${appNotification.appName}',
      timestamp: appNotification.timestamp,
      isRead: appNotification.isRead,
      category: _getCategoryFromPackage(appNotification.packageName),
      sentiment: 'Neutral',
      requiresAction: false,
      containsPersonalInfo: _hasPersonalInfo(appNotification.appName),
      packageName: appNotification.packageName,
      bigText: appNotification.bigText,
      subText: appNotification.subText,
    );
  }

  /// Export all notifications to Firebase
  static Future<void> exportAllNotifications() async {
    try {
      print('🔄 Starting notification export...');

      // Get all notifications from the local service
      final notifications =
          await service.NotificationService.getNotifications();

      if (notifications.isEmpty) {
        print('ℹ️ No notifications to export');
        return;
      }

      int exportedCount = 0;

      for (final appNotification in notifications) {
        final notificationModel = _convertToNotificationModel(appNotification);
        final success =
            await FirebaseExportService.exportNotification(notificationModel);
        if (success) exportedCount++;
      }

      // Update dashboard metadata
      await FirebaseExportService.updateDashboardMetadata(
        notificationCount: exportedCount,
      );

      print(
          '✅ Exported $exportedCount/${notifications.length} notifications to Firebase');
    } catch (e) {
      print('❌ Error exporting notifications: $e');
    }
  }

  /// Export a single notification (real-time)
  static Future<void> exportSingleNotification(
      service.AppNotification appNotification) async {
    final notificationModel = _convertToNotificationModel(appNotification);
    await FirebaseExportService.exportNotification(notificationModel);
  }

  /// Export notifications by category
  static Future<void> exportNotificationsByCategory(String category) async {
    try {
      final notifications =
          await service.NotificationService.getNotifications();
      final categoryNotifications = notifications
          .where((n) =>
              _getCategoryFromPackage(n.packageName).toLowerCase() ==
              category.toLowerCase())
          .toList();

      if (categoryNotifications.isEmpty) {
        print('ℹ️ No notifications found for category: $category');
        return;
      }

      final notificationModelList = categoryNotifications
          .map((n) => _convertToNotificationModel(n))
          .toList();

      await FirebaseExportService.batchExportNotifications(
          notificationModelList);
      print(
          '✅ Exported ${categoryNotifications.length} notifications for category: $category');
    } catch (e) {
      print('❌ Error exporting notifications by category: $e');
    }
  }

  /// Export notifications from last N days
  static Future<void> exportRecentNotifications({int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final allNotifications =
          await service.NotificationService.getNotifications();

      final recentNotifications = allNotifications
          .where((n) => n.timestamp.isAfter(cutoffDate))
          .toList();

      if (recentNotifications.isEmpty) {
        print('ℹ️ No recent notifications found from last $days days');
        return;
      }

      final notificationModelList = recentNotifications
          .map((n) => _convertToNotificationModel(n))
          .toList();

      await FirebaseExportService.batchExportNotifications(
          notificationModelList);
      print(
          '✅ Exported ${recentNotifications.length} notifications from last $days days');
    } catch (e) {
      print('❌ Error exporting recent notifications: $e');
    }
  }

  /// Get notification export statistics
  static Future<Map<String, dynamic>> getExportStats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('❌ No authenticated user for notification export stats');
        return {
          'total_notifications': 0,
          'categories': {},
          'error': 'No authenticated user',
        };
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(FirebaseExportService.notificationsCollection)
          .get();

      final docs = snapshot.docs;
      final totalCount = docs.length;

      // Count by category
      final categoryCount = <String, int>{};
      for (final doc in docs) {
        final category = doc.data()['category'] as String? ?? 'Unknown';
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;
      }

      return {
        'total_notifications': totalCount,
        'categories': categoryCount,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting export stats: $e');
      return {
        'total_notifications': 0,
        'categories': {},
        'error': e.toString(),
      };
    }
  }

  /// Setup real-time notification export
  static void setupRealtimeExport() {
    print('🔄 Setting up real-time notification export...');

    // This would be called whenever a new notification is received
    // You can integrate this with your existing notification listener
    service.NotificationService.notificationStream.listen((notification) {
      exportSingleNotification(notification);
    });
  }

  // Helper methods

  /// Get category from package name
  static String _getCategoryFromPackage(String packageName) {
    final package = packageName.toLowerCase();

    if (package.contains('whatsapp') ||
        package.contains('telegram') ||
        package.contains('signal') ||
        package.contains('discord')) {
      return 'Social';
    } else if (package.contains('gmail') ||
        package.contains('outlook') ||
        package.contains('email')) {
      return 'Productivity';
    } else if (package.contains('bank') ||
        package.contains('pay') ||
        package.contains('wallet')) {
      return 'Financial';
    } else if (package.contains('youtube') ||
        package.contains('netflix') ||
        package.contains('spotify')) {
      return 'Entertainment';
    } else if (package.contains('amazon') ||
        package.contains('shop') ||
        package.contains('cart')) {
      return 'Shopping';
    } else {
      return 'General';
    }
  }

  /// Convert notification priority
  static model.NotificationPriority _convertPriority(
      service.NotificationPriority servicesPriority) {
    switch (servicesPriority) {
      case service.NotificationPriority.high:
        return model.NotificationPriority.high;
      case service.NotificationPriority.urgent:
        return model.NotificationPriority.urgent;
      case service.NotificationPriority.low:
        return model.NotificationPriority.low;
      case service.NotificationPriority.normal:
        return model.NotificationPriority.medium;
    }
  }

  /// Check if app contains personal info
  static bool _hasPersonalInfo(String appName) {
    final app = appName.toLowerCase();
    return app.contains('bank') ||
        app.contains('pay') ||
        app.contains('mail') ||
        app.contains('message') ||
        app.contains('sms') ||
        app.contains('call');
  }
}
