import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AlertType {
  call,
  message,
  email,
  social,
  delivery,
  reminder,
  emergency,
  system
}

enum AlertPriority { low, medium, high, critical }

class LiveAlert {
  final String id;
  final String title;
  final String message;
  final AlertType type;
  final AlertPriority priority;
  final DateTime timestamp;
  final String? imageUrl;
  final Map<String, dynamic>? data;
  final Duration? duration;
  final List<AlertAction>? actions;

  LiveAlert({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.priority = AlertPriority.medium,
    DateTime? timestamp,
    this.imageUrl,
    this.data,
    this.duration,
    this.actions,
  }) : timestamp = timestamp ?? DateTime.now();

  factory LiveAlert.fromMap(Map<String, dynamic> map) {
    return LiveAlert(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: AlertType.values[map['type'] ?? 0],
      priority: AlertPriority.values[map['priority'] ?? 1],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      imageUrl: map['imageUrl'],
      data: map['data'],
      duration: map['duration'] != null
          ? Duration(milliseconds: map['duration'])
          : null,
      actions: map['actions']
          ?.map<AlertAction>((a) => AlertAction.fromMap(a))
          ?.toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type.index,
      'priority': priority.index,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'imageUrl': imageUrl,
      'data': data,
      'duration': duration?.inMilliseconds,
      'actions': actions?.map((a) => a.toMap()).toList(),
    };
  }
}

class AlertAction {
  final String id;
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isDismiss;

  AlertAction({
    required this.id,
    required this.label,
    this.icon,
    this.onTap,
    this.isDismiss = false,
  });

  factory AlertAction.fromMap(Map<String, dynamic> map) {
    return AlertAction(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      icon: map['iconCodePoint'] != null
          ? IconData(map['iconCodePoint'], fontFamily: 'MaterialIcons')
          : null,
      isDismiss: map['isDismiss'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'iconCodePoint': icon?.codePoint,
      'isDismiss': isDismiss,
    };
  }
}

class LiveAlertsService extends StateNotifier<List<LiveAlert>> {
  LiveAlertsService() : super([]) {
    _initializeService();
  }

  static const MethodChannel _channel = MethodChannel('live_alerts');
  Timer? _cleanupTimer;
  final Map<String, Timer> _autoRemoveTimers = {};

  Future<void> _initializeService() async {
    // Start cleanup timer for expired alerts
    _cleanupTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _cleanupExpiredAlerts();
    });

    // Listen to system notifications (if permission granted)
    try {
      _channel.setMethodCallHandler(_handleMethodCall);
    } catch (e) {
      print('Error setting up live alerts channel: $e');
    }
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onNotificationReceived':
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(call.arguments);
        _handleSystemNotification(data);
        break;
      case 'onCallStateChanged':
        final Map<String, dynamic> data =
            Map<String, dynamic>.from(call.arguments);
        _handleCallStateChange(data);
        break;
      default:
        print('Unknown method call: ${call.method}');
    }
  }

  void _handleSystemNotification(Map<String, dynamic> data) {
    final alert = LiveAlert(
      id: data['id'] ?? _generateId(),
      title: data['title'] ?? 'Notification',
      message: data['text'] ?? '',
      type: _getAlertTypeFromPackage(data['packageName']),
      priority: AlertPriority.medium,
      imageUrl: data['largeIcon'],
      data: data,
      duration: const Duration(seconds: 10),
      actions: [
        AlertAction(
          id: 'view',
          label: 'View',
          icon: Icons.visibility,
          onTap: () => _openApp(data['packageName']),
        ),
        AlertAction(
          id: 'dismiss',
          label: 'Dismiss',
          icon: Icons.close,
          isDismiss: true,
        ),
      ],
    );

    addAlert(alert);
  }

  void _handleCallStateChange(Map<String, dynamic> data) {
    final String state = data['state'] ?? '';
    final String number = data['number'] ?? '';
    final String name = data['name'] ?? number;

    if (state == 'RINGING') {
      final alert = LiveAlert(
        id: 'call_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Incoming Call',
        message: 'From $name',
        type: AlertType.call,
        priority: AlertPriority.critical,
        duration: const Duration(seconds: 30),
        actions: [
          AlertAction(
            id: 'answer',
            label: 'Answer',
            icon: Icons.call,
            onTap: () => _answerCall(),
          ),
          AlertAction(
            id: 'decline',
            label: 'Decline',
            icon: Icons.call_end,
            onTap: () => _declineCall(),
          ),
        ],
      );

      addAlert(alert);
    }
  }

  AlertType _getAlertTypeFromPackage(String? packageName) {
    if (packageName == null) return AlertType.system;

    if (packageName.contains('phone') || packageName.contains('call')) {
      return AlertType.call;
    } else if (packageName.contains('sms') || packageName.contains('message')) {
      return AlertType.message;
    } else if (packageName.contains('mail') || packageName.contains('gmail')) {
      return AlertType.email;
    } else if (packageName.contains('whatsapp') ||
        packageName.contains('telegram') ||
        packageName.contains('facebook') ||
        packageName.contains('instagram')) {
      return AlertType.social;
    } else if (packageName.contains('zomato') ||
        packageName.contains('swiggy') ||
        packageName.contains('amazon') ||
        packageName.contains('flipkart')) {
      return AlertType.delivery;
    }

    return AlertType.system;
  }

  void addAlert(LiveAlert alert) {
    // Remove any existing alert with same ID
    state = state.where((a) => a.id != alert.id).toList();

    // Add new alert at the beginning (most recent first)
    state = [alert, ...state];

    // Limit to maximum 10 alerts
    if (state.length > 10) {
      state = state.take(10).toList();
    }

    // Set auto-remove timer if duration is specified
    if (alert.duration != null) {
      _autoRemoveTimers[alert.id] = Timer(alert.duration!, () {
        removeAlert(alert.id);
      });
    }

    // Trigger haptic feedback for high priority alerts
    if (alert.priority == AlertPriority.high ||
        alert.priority == AlertPriority.critical) {
      HapticFeedback.mediumImpact();
    }
  }

  void removeAlert(String id) {
    state = state.where((alert) => alert.id != id).toList();
    _autoRemoveTimers[id]?.cancel();
    _autoRemoveTimers.remove(id);
  }

  void clearAllAlerts() {
    for (final timer in _autoRemoveTimers.values) {
      timer.cancel();
    }
    _autoRemoveTimers.clear();
    state = [];
  }

  void _cleanupExpiredAlerts() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final alert in state) {
      if (alert.duration != null) {
        final expiredTime = alert.timestamp.add(alert.duration!);
        if (now.isAfter(expiredTime)) {
          expiredIds.add(alert.id);
        }
      }
    }

    for (final id in expiredIds) {
      removeAlert(id);
    }
  }

  // Demo methods for testing
  void addDemoDeliveryAlert() {
    final alert = LiveAlert(
      id: _generateId(),
      title: 'Order Delivered!',
      message: 'Your food order has been delivered. Enjoy your meal!',
      type: AlertType.delivery,
      priority: AlertPriority.high,
      duration: const Duration(seconds: 15),
      actions: [
        AlertAction(
          id: 'rate',
          label: 'Rate',
          icon: Icons.star,
        ),
        AlertAction(
          id: 'dismiss',
          label: 'OK',
          icon: Icons.check,
          isDismiss: true,
        ),
      ],
    );
    addAlert(alert);
  }

  void addDemoCallAlert() {
    final alert = LiveAlert(
      id: _generateId(),
      title: 'Missed Call',
      message: 'You missed a call from John Doe (+91 98765 43210)',
      type: AlertType.call,
      priority: AlertPriority.medium,
      duration: const Duration(seconds: 10),
      actions: [
        AlertAction(
          id: 'callback',
          label: 'Call Back',
          icon: Icons.call,
        ),
        AlertAction(
          id: 'message',
          label: 'Message',
          icon: Icons.message,
        ),
      ],
    );
    addAlert(alert);
  }

  void addDemoSocialAlert() {
    final alert = LiveAlert(
      id: _generateId(),
      title: 'New Message',
      message: 'Sarah: Hey, are we still meeting at 6?',
      type: AlertType.social,
      priority: AlertPriority.medium,
      duration: const Duration(seconds: 12),
      actions: [
        AlertAction(
          id: 'reply',
          label: 'Reply',
          icon: Icons.reply,
        ),
        AlertAction(
          id: 'dismiss',
          label: 'Later',
          icon: Icons.schedule,
          isDismiss: true,
        ),
      ],
    );
    addAlert(alert);
  }

  String _generateId() {
    return 'alert_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1000)}';
  }

  Future<void> _openApp(String? packageName) async {
    if (packageName != null) {
      try {
        await _channel.invokeMethod('openApp', {'packageName': packageName});
      } catch (e) {
        print('Error opening app: $e');
      }
    }
  }

  Future<void> _answerCall() async {
    try {
      await _channel.invokeMethod('answerCall');
    } catch (e) {
      print('Error answering call: $e');
    }
  }

  Future<void> _declineCall() async {
    try {
      await _channel.invokeMethod('declineCall');
    } catch (e) {
      print('Error declining call: $e');
    }
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    for (final timer in _autoRemoveTimers.values) {
      timer.cancel();
    }
    super.dispose();
  }
}

// Riverpod provider
final liveAlertsProvider =
    StateNotifierProvider<LiveAlertsService, List<LiveAlert>>((ref) {
  return LiveAlertsService();
});

// Helper providers
final hasAlertsProvider = Provider<bool>((ref) {
  final alerts = ref.watch(liveAlertsProvider);
  return alerts.isNotEmpty;
});

final criticalAlertsProvider = Provider<List<LiveAlert>>((ref) {
  final alerts = ref.watch(liveAlertsProvider);
  return alerts
      .where((alert) => alert.priority == AlertPriority.critical)
      .toList();
});

final alertsByTypeProvider =
    Provider.family<List<LiveAlert>, AlertType>((ref, type) {
  final alerts = ref.watch(liveAlertsProvider);
  return alerts.where((alert) => alert.type == type).toList();
});
