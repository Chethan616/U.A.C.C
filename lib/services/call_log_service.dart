import 'package:flutter/services.dart';
import 'dart:async';

class CallLog {
  final String id;
  final String phoneNumber;
  final String? contactName;
  final String? photoUrl;
  final DateTime timestamp;
  final int duration; // in seconds
  final CallType type;
  final bool isRead;

  CallLog({
    required this.id,
    required this.phoneNumber,
    this.contactName,
    this.photoUrl,
    required this.timestamp,
    required this.duration,
    required this.type,
    this.isRead = false,
  });

  String get displayName => contactName ?? phoneNumber;

  String get formattedDuration {
    if (duration == 0) return '0:00';
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

enum CallType {
  incoming,
  outgoing,
  missed,
}

class CallLogService {
  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/call_logs');

  /// Get call logs from the device
  static Future<List<CallLog>> getCallLogs({int limit = 100}) async {
    try {
      final List<dynamic> logs =
          await _channel.invokeMethod('getCallLogs', {'limit': limit});

      return logs.map((log) {
        final Map<String, dynamic> logData = Map<String, dynamic>.from(log);

        return CallLog(
          id: logData['id']?.toString() ?? '',
          phoneNumber: logData['phoneNumber']?.toString() ?? '',
          contactName: logData['contactName']?.toString(),
          photoUrl: logData['photoUrl']?.toString(),
          timestamp: DateTime.fromMillisecondsSinceEpoch(
              logData['timestamp'] ?? DateTime.now().millisecondsSinceEpoch),
          duration: logData['duration'] ?? 0,
          type: _parseCallType(logData['type']),
          isRead: logData['isRead'] ?? true,
        );
      }).toList();
    } catch (e) {
      print('Error getting call logs: $e');
      return _getMockCallLogs();
    }
  }

  /// Get call statistics for dashboard
  static Future<Map<String, int>> getCallStats() async {
    try {
      final Map<dynamic, dynamic> stats =
          await _channel.invokeMethod('getCallStats');
      return Map<String, int>.from(stats);
    } catch (e) {
      print('Error getting call stats: $e');
      return {
        'todayCalls': 0,
        'totalCalls': 0,
        'missedCalls': 0,
        'totalDuration': 0,
      };
    }
  }

  /// Mark call log as read
  static Future<void> markAsRead(String callId) async {
    try {
      await _channel.invokeMethod('markCallAsRead', {'callId': callId});
    } catch (e) {
      print('Error marking call as read: $e');
    }
  }

  static CallType _parseCallType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'incoming':
        return CallType.incoming;
      case 'outgoing':
        return CallType.outgoing;
      case 'missed':
        return CallType.missed;
      default:
        return CallType.incoming;
    }
  }

  // Mock data for fallback when native call fails
  static List<CallLog> _getMockCallLogs() {
    final now = DateTime.now();
    return [
      CallLog(
        id: '1',
        phoneNumber: '+1234567890',
        contactName: 'John Doe',
        timestamp: now.subtract(const Duration(minutes: 15)),
        duration: 180,
        type: CallType.incoming,
      ),
      CallLog(
        id: '2',
        phoneNumber: '+0987654321',
        contactName: 'Sarah Wilson',
        timestamp: now.subtract(const Duration(hours: 2)),
        duration: 0,
        type: CallType.missed,
      ),
      CallLog(
        id: '3',
        phoneNumber: '+1122334455',
        contactName: 'Mike Johnson',
        timestamp: now.subtract(const Duration(hours: 4)),
        duration: 45,
        type: CallType.outgoing,
      ),
      CallLog(
        id: '4',
        phoneNumber: '+5566778899',
        contactName: 'Emma Davis',
        timestamp: now.subtract(const Duration(hours: 6)),
        duration: 120,
        type: CallType.incoming,
      ),
      CallLog(
        id: '5',
        phoneNumber: '+2233445566',
        contactName: 'Alex Brown',
        timestamp: now.subtract(const Duration(days: 1)),
        duration: 90,
        type: CallType.outgoing,
      ),
    ];
  }
}
