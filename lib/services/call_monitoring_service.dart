import 'package:flutter/services.dart';
import 'dart:async';
import 'live_activity_service.dart';

class CallMonitoringService {
  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/call_monitoring');
  static const EventChannel _eventChannel =
      EventChannel('com.example.uacc/call_state_events');

  static StreamSubscription? _callStateSubscription;
  static Timer? _callDurationTimer;
  static DateTime? _callStartTime;
  static String? _currentCallerName;
  static String? _currentPhoneNumber;
  static String? _currentCallType;

  /// Start monitoring call state changes
  static Future<void> startMonitoring() async {
    try {
      // Request permissions
      await _channel.invokeMethod('requestPermissions');

      // Listen to call state events
      _callStateSubscription = _eventChannel
          .receiveBroadcastStream()
          .cast<Map<dynamic, dynamic>>()
          .map((event) => Map<String, dynamic>.from(event))
          .listen(
        _handleCallStateEvent,
        onError: (error) {
          print('Call monitoring error: $error');
        },
      );

      print('Call monitoring started');
    } catch (e) {
      print('Error starting call monitoring: $e');
    }
  }

  /// Stop monitoring call state changes
  static Future<void> stopMonitoring() async {
    await _callStateSubscription?.cancel();
    _callStateSubscription = null;
    _callDurationTimer?.cancel();
    _callDurationTimer = null;
    print('Call monitoring stopped');
  }

  /// Handle call state events from native side
  static void _handleCallStateEvent(Map<String, dynamic> event) {
    final callState = event['callState'] as String?;
    final phoneNumber = event['phoneNumber'] as String?;
    final callerName = event['callerName'] as String?;

    print(
        'Call state event: $callState, Number: $phoneNumber, Name: $callerName');

    switch (callState) {
      case 'RINGING':
        _handleIncomingCall(phoneNumber, callerName);
        break;
      case 'OFFHOOK':
        _handleCallStarted(phoneNumber, callerName);
        break;
      case 'IDLE':
        _handleCallEnded();
        break;
      default:
        break;
    }
  }

  /// Handle incoming call
  static void _handleIncomingCall(String? phoneNumber, String? callerName) {
    _currentPhoneNumber = phoneNumber ?? 'Unknown';
    _currentCallerName = callerName ?? _currentPhoneNumber;
    _currentCallType = 'Incoming';

    // Show live activity for incoming call
    LiveActivityService.showCallOverlay(
      callerName: _currentCallerName!,
      phoneNumber: _currentPhoneNumber!,
      callType: 'incoming',
    );

    LiveActivityService.startLiveActivity(
      type: 'call',
      title: 'Incoming Call',
      content: _currentCallerName!,
    );
  }

  /// Handle call started (answered)
  static void _handleCallStarted(String? phoneNumber, String? callerName) {
    _callStartTime = DateTime.now();
    _currentPhoneNumber = phoneNumber ?? _currentPhoneNumber ?? 'Unknown';
    _currentCallerName =
        callerName ?? _currentCallerName ?? _currentPhoneNumber;

    // Determine call type
    if (_currentCallType == null || _currentCallType == 'Incoming') {
      _currentCallType = 'Ongoing';
    } else {
      _currentCallType = 'Outgoing';
    }

    // Start call duration timer
    _startCallDurationTimer();

    // Show ongoing call activity
    LiveActivityService.showOngoingCallActivity(
      callerName: _currentCallerName!,
      phoneNumber: _currentPhoneNumber!,
      callType: _currentCallType!,
      callDuration: Duration.zero,
    );
  }

  /// Handle call ended
  static void _handleCallEnded() {
    // Stop call duration timer
    _callDurationTimer?.cancel();
    _callDurationTimer = null;

    // End live activity
    LiveActivityService.endOngoingCallActivity();

    // Reset call state
    _callStartTime = null;
    _currentCallerName = null;
    _currentPhoneNumber = null;
    _currentCallType = null;
  }

  /// Start timer to update call duration
  static void _startCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_callStartTime != null && _currentCallerName != null) {
        final duration = DateTime.now().difference(_callStartTime!);

        // Update live activity with current duration
        LiveActivityService.updateOngoingCallActivity(
          callerName: _currentCallerName!,
          phoneNumber: _currentPhoneNumber!,
          callType: _currentCallType!,
          callDuration: duration,
        );
      }
    });
  }

  /// Check if call monitoring permissions are granted
  static Future<bool> hasPermissions() async {
    try {
      final result = await _channel.invokeMethod('hasPermissions');
      return result == true;
    } catch (e) {
      print('Error checking permissions: $e');
      return false;
    }
  }

  /// Request call monitoring permissions
  static Future<bool> requestPermissions() async {
    try {
      final result = await _channel.invokeMethod('requestPermissions');
      return result == true;
    } catch (e) {
      print('Error requesting permissions: $e');
      return false;
    }
  }

  /// Simulate an incoming call for testing
  static Future<void> simulateIncomingCall({
    String callerName = 'John Doe',
    String phoneNumber = '+1234567890',
  }) async {
    _handleIncomingCall(phoneNumber, callerName);

    // Simulate answering after 3 seconds
    Timer(const Duration(seconds: 3), () {
      _handleCallStarted(phoneNumber, callerName);
    });

    // Simulate ending call after 10 seconds
    Timer(const Duration(seconds: 13), () {
      _handleCallEnded();
    });
  }

  /// Get current call state
  static Map<String, dynamic>? getCurrentCallState() {
    if (_callStartTime != null && _currentCallerName != null) {
      final duration = DateTime.now().difference(_callStartTime!);
      return {
        'callerName': _currentCallerName,
        'phoneNumber': _currentPhoneNumber,
        'callType': _currentCallType,
        'duration': duration.inSeconds,
        'isActive': true,
      };
    }
    return null;
  }
}
