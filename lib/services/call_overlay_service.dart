import 'package:flutter/services.dart';
import 'dart:async';

class CallOverlayService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.uacc/call_overlay');
  static const EventChannel _eventChannel =
      EventChannel('com.example.uacc/call_overlay_events');

  static Stream<Map<String, dynamic>>? _eventStream;

  /// Get the event stream for overlay events
  static Stream<Map<String, dynamic>> get eventStream {
    _eventStream ??= _eventChannel
        .receiveBroadcastStream()
        .cast<Map<dynamic, dynamic>>()
        .map((event) => Map<String, dynamic>.from(event));
    return _eventStream!;
  }

  /// Start the overlay service
  static Future<bool> startService() async {
    try {
      final result = await _methodChannel.invokeMethod('startOverlayService');
      return result == true;
    } catch (e) {
      print('Error starting overlay service: $e');
      return false;
    }
  }

  /// Stop the overlay service
  static Future<bool> stopService() async {
    try {
      final result = await _methodChannel.invokeMethod('stopOverlayService');
      return result == true;
    } catch (e) {
      print('Error stopping overlay service: $e');
      return false;
    }
  }

  /// Check if overlay permission is granted
  static Future<bool> checkOverlayPermission() async {
    try {
      final result =
          await _methodChannel.invokeMethod('checkOverlayPermission');
      return result == true;
    } catch (e) {
      print('Error checking overlay permission: $e');
      return false;
    }
  }

  /// Request overlay permission
  static Future<bool> requestOverlayPermission() async {
    try {
      final result =
          await _methodChannel.invokeMethod('requestOverlayPermission');
      return result == true;
    } catch (e) {
      print('Error requesting overlay permission: $e');
      return false;
    }
  }

  /// Expand the Dynamic Island
  static Future<void> expandDynamicIsland() async {
    try {
      await _methodChannel.invokeMethod('expandDynamicIsland');
    } catch (e) {
      print('Error expanding Dynamic Island: $e');
    }
  }

  /// Collapse the Dynamic Island
  static Future<void> collapseDynamicIsland() async {
    try {
      await _methodChannel.invokeMethod('collapseDynamicIsland');
    } catch (e) {
      print('Error collapsing Dynamic Island: $e');
    }
  }

  /// Update transcript
  static Future<void> updateTranscript(String transcript) async {
    try {
      await _methodChannel.invokeMethod('updateTranscript', {
        'transcript': transcript,
      });
    } catch (e) {
      print('Error updating transcript: $e');
    }
  }

  /// Clear transcript
  static Future<void> clearTranscript() async {
    try {
      await _methodChannel.invokeMethod('clearTranscript');
    } catch (e) {
      print('Error clearing transcript: $e');
    }
  }

  /// Get service status
  static Future<Map<String, dynamic>?> getServiceStatus() async {
    try {
      final result = await _methodChannel.invokeMethod('getServiceStatus');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      print('Error getting service status: $e');
      return null;
    }
  }
}
