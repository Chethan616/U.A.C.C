import 'package:flutter/services.dart';
import 'dart:async';

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
}

enum NotificationPriority {
  low,
  normal,
  high,
  urgent,
}

class NotificationService {
  static const MethodChannel _channel = MethodChannel('com.example.uacc/notifications');
  
  /// Get all notifications from various apps
  static Future<List<AppNotification>> getNotifications({int limit = 100}) async {
    try {
      final List<dynamic> notifications = await _channel.invokeMethod('getNotifications', {'limit': limit});
      
      return notifications.map((notification) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(notification);
        
        return AppNotification(
          id: data['id'] ?? '',
          packageName: data['packageName'] ?? '',
          appName: data['appName'] ?? '',
          appIcon: data['appIcon'],
          title: data['title'] ?? '',
          content: data['content'] ?? '',
          timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp'] ?? 0),
          isRead: data['isRead'] ?? false,
          bigText: data['bigText'],
          subText: data['subText'],
          priority: _parsePriority(data['priority']),
        );
      }).toList();
    } catch (e) {
      print('Error getting notifications: $e');
      return _getMockNotifications();
    }
  }
  
  /// Get notification statistics for dashboard
  static Future<Map<String, int>> getNotificationStats() async {
    try {
      final Map<dynamic, dynamic> stats = await _channel.invokeMethod('getNotificationStats');
      return Map<String, int>.from(stats);
    } catch (e) {
      print('Error getting notification stats: $e');
      return {
        'todayNotifications': 28,
        'totalNotifications': 156,
        'unreadNotifications': 12,
        'importantNotifications': 5,
      };
    }
  }
  
  /// Summarize notifications using AI
  static Future<String> summarizeNotifications(List<AppNotification> notifications) async {
    try {
      final notificationData = notifications.map((n) => {
        'appName': n.appName,
        'title': n.title,
        'content': n.displayContent,
        'timestamp': n.timestamp.toIso8601String(),
        'priority': n.priority.name,
      }).toList();
      
      final Map<dynamic, dynamic> result = await _channel.invokeMethod('summarizeNotifications', {
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
      await _channel.invokeMethod('markNotificationAsRead', {'notificationId': notificationId});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }
  
  /// Request notification listener permission
  static Future<bool> requestNotificationPermission() async {
    try {
      final bool granted = await _channel.invokeMethod('requestNotificationPermission');
      return granted;
    } catch (e) {
      print('Error requesting notification permission: $e');
      return false;
    }
  }
  
  /// Check if notification listener permission is granted
  static Future<bool> hasNotificationPermission() async {
    try {
      final bool hasPermission = await _channel.invokeMethod('hasNotificationPermission');
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
  
  // Mock data for fallback
  static List<AppNotification> _getMockNotifications() {
    final now = DateTime.now();
    return [
      AppNotification(
        id: '1',
        packageName: 'com.google.android.gms',
        appName: 'Gmail',
        title: 'New email from John Doe',
        content: 'Meeting scheduled for tomorrow at 10 AM',
        timestamp: now.subtract(const Duration(minutes: 15)),
        priority: NotificationPriority.high,
      ),
      AppNotification(
        id: '2',
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        title: 'Mom',
        content: 'Don\'t forget to call me tonight!',
        timestamp: now.subtract(const Duration(hours: 1)),
        priority: NotificationPriority.normal,
      ),
      AppNotification(
        id: '3',
        packageName: 'com.zomato.app',
        appName: 'Zomato',
        title: 'Order Update',
        content: 'Your order is being prepared and will be delivered in 25 minutes',
        timestamp: now.subtract(const Duration(hours: 2)),
        priority: NotificationPriority.high,
      ),
      AppNotification(
        id: '4',
        packageName: 'com.paytm',
        appName: 'Paytm',
        title: 'Payment Reminder',
        content: 'Your electricity bill of ₹2,450 is due tomorrow',
        timestamp: now.subtract(const Duration(hours: 3)),
        priority: NotificationPriority.urgent,
      ),
      AppNotification(
        id: '5',
        packageName: 'com.google.android.calendar',
        appName: 'Calendar',
        title: 'Meeting in 30 minutes',
        content: 'Team standup meeting with Alex, Sarah, and Mike',
        timestamp: now.subtract(const Duration(minutes: 30)),
        priority: NotificationPriority.high,
      ),
    ];
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