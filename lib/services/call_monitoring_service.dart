import 'package:flutter/services.dart';
import 'dart:async';
// Removed live activity service import
import 'enhanced_call_transcript_service.dart';

class CallMonitoringService {
  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/call_monitoring');
  static const EventChannel _eventChannel = EventChannel(
      'com.example.uacc/call_overlay_events'); // Updated to match CallOverlayChannel

  static StreamSubscription? _callStateSubscription;
  static Timer? _callDurationTimer;
  static DateTime? _callStartTime;
  static String? _currentCallerName;
  static String? _currentPhoneNumber;
  static String? _currentCallType;
  static String? _currentActivityId;

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
    print('🔄 Flutter received call state event: $event');

    final eventType = event['type'] as String?;
    if (eventType != 'callStateChanged') {
      print('🔄 Ignoring non-call event: $eventType');
      return;
    }

    final callState = event['callState'] as String?;
    final phoneNumber = event['phoneNumber'] as String?;
    final callerName = event['callerName'] as String?;

    print(
        '📞 Flutter processing call state: $callState, Number: $phoneNumber, Name: $callerName');

    switch (callState) {
      case 'RINGING':
        print('📱 Incoming call ringing - preparing service');
        _handleIncomingCall(phoneNumber, callerName);
        break;
      case 'OFFHOOK':
        print(
            '🟢 Call active - starting Flutter Enhanced Call Transcript Service');
        _handleCallStarted(phoneNumber, callerName);
        break;
      case 'IDLE':
        print(
            '📴 Call ended - stopping Flutter Enhanced Call Transcript Service');
        _handleCallEnded();
        break;
      default:
        print('❓ Unknown call state: $callState');
        break;
    }
  }

  /// Handle incoming call
  static void _handleIncomingCall(
      String? phoneNumber, String? callerName) async {
    _currentPhoneNumber = phoneNumber ?? 'Unknown';
    _currentCallerName = callerName ?? _currentPhoneNumber;
    _currentCallType = 'Incoming';

    print('Incoming call from: $_currentCallerName ($_currentPhoneNumber)');
  }

  /// Handle call started (answered)
  static void _handleCallStarted(
      String? phoneNumber, String? callerName) async {
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

    // Start transcript service for real-time speech recognition
    try {
      bool isIncomingCall = _currentCallType == 'Ongoing';
      print('🎤 Starting Flutter Enhanced Call Transcript Service...');
      print('   - Caller: $_currentCallerName');
      print('   - Number: $_currentPhoneNumber');
      print('   - Type: $_currentCallType (incoming: $isIncomingCall)');

      final success = await EnhancedCallTranscriptService.startCallTranscript(
        isIncomingCall: isIncomingCall,
      );

      if (success) {
        print(
            '✅ Flutter Enhanced Call Transcript Service started successfully!');
      } else {
        print('❌ Failed to start Flutter Enhanced Call Transcript Service');
      }
    } catch (e) {
      print(
          '💥 Exception starting Flutter Enhanced Call Transcript Service: $e');
      print('🔍 Stack trace: ${StackTrace.current}');
    }
  }

  /// Handle call ended
  static void _handleCallEnded() async {
    // Stop call duration timer
    _callDurationTimer?.cancel();
    _callDurationTimer = null;

    // Stop transcript service
    try {
      await EnhancedCallTranscriptService.stopCallTranscript();
      print('🏝️ Dynamic Island transcript service stopped');
    } catch (e) {
      print('Failed to stop transcript service: $e');
    }

    // Reset call state
    _callStartTime = null;
    _currentCallerName = null;
    _currentPhoneNumber = null;
    _currentCallType = null;
    _currentActivityId = null;
  }

  /// Start timer to update call duration
  static void _startCallDurationTimer() {
    _callDurationTimer?.cancel();
    _callDurationTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (_callStartTime != null && _currentCallerName != null) {
        final duration = DateTime.now().difference(_callStartTime!);
        // Duration tracking (for future use if needed)
        print('Call duration: ${duration.inSeconds}s');
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
