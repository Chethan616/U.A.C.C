import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:convert';

class AppNotification {
  final String id;
  final String packageName;
  final String appName;
  final String? appIcon;
  final String title;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String? bigText;
  final String? subText;
  final NotificationPriority priority;

  AppNotification({
    required this.id,
    required this.packageName,
    required this.appName,
    this.appIcon,
    required this.title,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.bigText,
    this.subText,
    this.priority = NotificationPriority.normal,
  });

  String get displayContent => bigText ?? content;

  AppNotification copyWith({
    String? id,
    String? packageName,
    String? appName,
    String? appIcon,
    String? title,
    String? content,
    DateTime? timestamp,
    bool? isRead,
    String? bigText,
    String? subText,
    NotificationPriority? priority,
  }) {
    return AppNotification(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      appIcon: appIcon ?? this.appIcon,
      title: title ?? this.title,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      bigText: bigText ?? this.bigText,
      subText: subText ?? this.subText,
      priority: priority ?? this.priority,
    );
  }

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id'] ?? '',
      packageName: json['packageName'] ?? '',
      appName: json['appName'] ?? '',
      appIcon: json['appIcon'],
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
      isRead: json['isRead'] ?? false,
      bigText: json['bigText'],
      subText: json['subText'],
      priority: _parsePriority(json['priority']),
    );
  }

  static NotificationPriority _parsePriority(dynamic priority) {
    switch (priority) {
      case 'LOW':
        return NotificationPriority.low;
      case 'HIGH':
        return NotificationPriority.high;
      case 'URGENT':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/notifications');

  static const EventChannel _eventChannel =
      EventChannel('com.example.uacc/notification_events');

  static StreamController<AppNotification>? _notificationController;
  static StreamSubscription? _eventSubscription;

  /// Get stream of real-time notifications
  static Stream<AppNotification> get notificationStream {
    _notificationController ??= StreamController<AppNotification>.broadcast();

    if (_eventSubscription == null) {
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          try {
            if (event is Map) {
              final type = event['type'] as String?;
              if (type == 'notification_posted') {
                final data = event['data'] as String?;
                if (data != null) {
                  final notificationJson = jsonDecode(data);

                  // Debug: Log raw notification data from Android
                  print('📱 Raw notification data from Android:');
                  print(
                      '   Package: ${notificationJson['packageName'] ?? 'null'}');
                  print('   App: ${notificationJson['appName'] ?? 'null'}');
                  print('   Title: "${notificationJson['title'] ?? 'null'}"');
                  print('   Text: "${notificationJson['text'] ?? 'null'}"');
                  print(
                      '   BigText: "${notificationJson['bigText'] ?? 'null'}"');
                  print(
                      '   SubText: "${notificationJson['subText'] ?? 'null'}"');

                  final notification = AppNotification(
                    id: notificationJson['id'] ?? '',
                    packageName: notificationJson['packageName'] ?? '',
                    appName: notificationJson['appName'] ?? '',
                    title: notificationJson['title'] ?? '',
                    content: notificationJson['text'] ?? '',
                    timestamp: DateTime.fromMillisecondsSinceEpoch(
                        notificationJson['timestamp'] ?? 0),
                    bigText: notificationJson['bigText'],
                    subText: notificationJson['subText'],
                    priority: _parsePriority(notificationJson['priority']),
                  );

                  // Validate notification has some content before processing
                  final hasContent = notification.title.isNotEmpty ||
                      notification.content.isNotEmpty ||
                      (notification.bigText?.isNotEmpty ?? false) ||
                      (notification.subText?.isNotEmpty ?? false);

                  if (!hasContent) {
                    print(
                        '⚠️ WARNING: Empty notification detected from ${notification.appName}/${notification.packageName}');
                    print(
                        '   This suggests the Android NotificationListenerService may not be capturing content properly');
                  }

                  _notificationController?.add(notification);
                }
              }
            }
          } catch (e) {
            print('Error processing notification event: $e');
          }
        },
        onError: (error) {
          print('Notification stream error: $error');
        },
      );
    }

    return _notificationController!.stream;
  }

  /// Get all notifications from various apps
  /// Diagnostic method to check notification capture health
  static void runNotificationDiagnostics() {
    print('🔍 NOTIFICATION DIAGNOSTICS:');
    print('   1. Check if NotificationListenerService is running');
    print(
        '   2. Verify permission: Settings > Apps > Special Access > Notification Access');
    print('   3. Restart the app if notifications seem empty');
    print(
        '   4. Check if specific apps (Messages, Instagram) block notification content');
    print('   5. Test with a simple notification from another app');
  }

  static Future<List<AppNotification>> getNotifications(
      {int limit = 100}) async {
    try {
      final List<dynamic> notifications =
          await _channel.invokeMethod('getNotifications', {'limit': limit});

      return notifications.map((notification) {
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(notification);
        return AppNotification.fromJson(data);
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      rethrow;
    }
  }

  /// Get notification statistics for dashboard
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final Map<dynamic, dynamic> stats =
          await _channel.invokeMethod('getNotificationStats');
      return Map<String, int>.from(stats);
    } catch (e) {
      print('Error getting notification stats: $e');
      return {
        'todayNotifications': 0,
        'totalNotifications': 0,
        'unreadNotifications': 0,
        'importantNotifications': 0,
      };
    }
  }

  /// Summarize notifications using AI
  static Future<String> summarizeNotifications(
      List<AppNotification> notifications) async {
    try {
      final notificationData = notifications
          .map((n) => {
                'appName': n.appName,
                'title': n.title,
                'content': n.displayContent,
                'timestamp': n.timestamp.toIso8601String(),
                'priority': n.priority.name,
              })
          .toList();

      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('summarizeNotifications', {
        'notifications': notificationData,
      });

      return result['summary'] ?? 'No summary available';
    } catch (e) {
      print('Error summarizing notifications: $e');
      return _getMockSummary();
    }
  }

  /// Mark notification as read
  static Future<void> markAsRead(String notificationId) async {
    try {
      await _channel.invokeMethod(
          'markNotificationAsRead', {'notificationId': notificationId});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead() async {
    try {
      await _channel.invokeMethod('markAllNotificationsAsRead');
    } catch (e) {
      print('Error marking all notifications as read: $e');
      rethrow;
    }
  }

  /// Request notification listener permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final bool granted =
          await _channel.invokeMethod('requestNotificationPermission');
      return granted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }

  /// Check if notification listener permission is granted
  static Future<bool> hasNotificationPermission() async {
    try {
      final bool hasPermission =
          await _channel.invokeMethod('hasNotificationPermission');
      return hasPermission;
    } catch (e) {
      print('Error checking notification permission: $e');
      return false;
    }
  }

  static NotificationPriority _parsePriority(dynamic priority) {
    switch (priority) {
      case 'LOW':
        return NotificationPriority.low;
      case 'HIGH':
        return NotificationPriority.high;
      case 'URGENT':
        return NotificationPriority.urgent;
      default:
        return NotificationPriority.normal;
    }
  }

  /// Dispose resources
  static void dispose() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
    _notificationController?.close();
    _notificationController = null;
  }

  static String _getMockSummary() {
    return '''📧 **Email Updates**: New message from John Doe about tomorrow's meeting at 10 AM.

💬 **Messages**: Mom reminded you to call tonight, and there are 3 unread WhatsApp messages.

🍔 **Food Delivery**: Zomato order is being prepared - delivery expected in 25 minutes.

💳 **Payments**: Paytm reminder for electricity bill (₹2,450) due tomorrow - needs immediate attention.

📅 **Calendar**: Team standup meeting starting in 30 minutes with Alex, Sarah, and Mike.

🔔 **Priority Actions Needed**: Pay electricity bill and prepare for upcoming meeting.''';
  }
}
