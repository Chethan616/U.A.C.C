import 'package:flutter/services.dart';
import 'dart:async';

class LiveActivityService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.uacc/live_activity');
  static const EventChannel _eventChannel =
      EventChannel('com.example.uacc/live_activity_events');

  static Stream<Map<String, dynamic>>? _eventStream;
  static StreamSubscription? _eventSubscription;

  /// Get the event stream for live activity events
  static Stream<Map<String, dynamic>> get eventStream {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .cast<Map<dynamic, dynamic>>()
        .map((event) => Map<String, dynamic>.from(event));
    return _eventStream!;
  }

  /// Start the native live activity service (like Zomato/Screen recording)
  static Future<bool> startLiveActivity({
    String type = 'general',
    String title = 'Live Activity',
    String content = '',
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('startLiveActivity', {
        'type': type,
        'title': title,
        'content': content,
      });
      return result == true;
    } catch (e) {
      print('Error starting live activity: $e');
      return false;
    }
  }

  /// Update existing live activity
  static Future<bool> updateLiveActivity({
    required String title,
    required String content,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('updateLiveActivity', {
        'title': title,
        'content': content,
      });
      return result == true;
    } catch (e) {
      print('Error updating live activity: $e');
      return false;
    }
  }

  /// Stop the native live activity service
  static Future<bool> stopLiveActivity() async {
    try {
      final result = await _methodChannel.invokeMethod('stopLiveActivity');
      return result == true;
    } catch (e) {
      print('Error stopping live activity: $e');
      return false;
    }
  }

  /// Show call overlay with caller information
  static Future<bool> showCallOverlay({
    required String callerName,
    required String phoneNumber,
    required String callType,
  }) async {
    try {
      final result = await _methodChannel.invokeMethod('showCallOverlay', {
        'callerName': callerName,
        'phoneNumber': phoneNumber,
        'callType': callType,
      });
      return result == true;
    } catch (e) {
      print('Error showing call overlay: $e');
      return false;
    }
  }

  /// Hide call overlay
  static Future<bool> hideCallOverlay() async {
    try {
      final result = await _methodChannel.invokeMethod('hideCallOverlay');
      return result == true;
    } catch (e) {
      print('Error hiding call overlay: $e');
      return false;
    }
  }

  /// Check if live activity service is running
  static Future<bool> isLiveActivityRunning() async {
    try {
      final result = await _methodChannel.invokeMethod('isLiveActivityRunning');
      return result == true;
    } catch (e) {
      print('Error checking live activity status: $e');
      return false;
    }
  }

  /// Start listening to live activity events
  static void startListening(Function(Map<String, dynamic>) onEvent) {
    _eventSubscription = eventStream.listen(
      onEvent,
      onError: (error) {
        print('Live Activity Event Stream Error: $error');
      },
    );
  }

  /// Stop listening to live activity events
  static void stopListening() {
    _eventSubscription?.cancel();
    _eventSubscription = null;
  }

  /// Show live activity for ongoing call
  static Future<void> showOngoingCallActivity({
    required String callerName,
    required String phoneNumber,
    required String callType,
    required Duration callDuration,
  }) async {
    final durationText = _formatCallDuration(callDuration);
    
    await startLiveActivity(
      type: 'call',
      title: '$callType Call',
      content: '$callerName ($phoneNumber) • $durationText',
    );

    // Also show call overlay
    await showCallOverlay(
      callerName: callerName,
      phoneNumber: phoneNumber,
      callType: callType,
    );
  }

  /// Update ongoing call activity with new duration
  static Future<void> updateOngoingCallActivity({
    required String callerName,
    required String phoneNumber,
    required String callType,
    required Duration callDuration,
  }) async {
    final durationText = _formatCallDuration(callDuration);
    
    await updateLiveActivity(
      title: '$callType Call',
      content: '$callerName ($phoneNumber) • $durationText',
    );
  }

  /// End ongoing call activity
  static Future<void> endOngoingCallActivity() async {
    await stopLiveActivity();
    await hideCallOverlay();
  }

  /// Format call duration for display
  static String _formatCallDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Show delivery/task activity like Zomato
  static Future<void> showDeliveryActivity({
    required String title,
    required String restaurantName,
    required String estimatedTime,
    required String orderStatus,
  }) async {
    await startLiveActivity(
      type: 'delivery',
      title: title,
      content: '$restaurantName • $orderStatus • ETA: $estimatedTime',
    );
  }

  /// Show task reminder activity
  static Future<void> showTaskReminderActivity({
    required String taskTitle,
    required String dueTime,
    required String priority,
  }) async {
    await startLiveActivity(
      type: 'task',
      title: 'Task Reminder',
      content: '$taskTitle • Due: $dueTime • Priority: $priority',
    );
  }

  /// Show notification summary activity
  static Future<void> showNotificationSummaryActivity({
    required int notificationCount,
    required String topApp,
    required String summary,
  }) async {
    await startLiveActivity(
      type: 'notifications',
      title: '$notificationCount New Notifications',
      content: 'Top: $topApp • $summary',
    );
  }
}

class LiveActivityType {
  static const String call = 'call';
  static const String delivery = 'delivery';
  static const String task = 'task';
  static const String notifications = 'notifications';
  static const String general = 'general';
}

class CallType {
  static const String incoming = 'incoming';
  static const String outgoing = 'outgoing';
  static const String ongoing = 'ongoing';
}
