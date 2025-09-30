import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/call.dart' as call_model;
import '../services/call_log_service.dart';
import 'firebase_export_service.dart';

/// Call Transcript Export Service
/// Handles exporting call data and transcripts to Firebase for web dashboard
class CallTranscriptExportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Export all call logs to Firebase
  static Future<void> exportAllCallTranscripts() async {
    try {
      print('🔄 Starting call transcript export...');

      // Get call logs from the service
      final callLogs = await CallLogService.getCallLogs();

      if (callLogs.isEmpty) {
        print('ℹ️ No call logs to export');
        return;
      }

      int exportedCount = 0;

      for (final callLog in callLogs) {
        final callData = _convertToCallData(callLog);
        final success =
            await FirebaseExportService.exportCallTranscript(callData);
        if (success) exportedCount++;
      }

      // Update dashboard metadata
      await FirebaseExportService.updateDashboardMetadata(
        callCount: exportedCount,
      );

      print(
          '✅ Exported $exportedCount/${callLogs.length} call transcripts to Firebase');
    } catch (e) {
      print('❌ Error exporting call transcripts: $e');
    }
  }

  /// Export a single call transcript (real-time)
  static Future<void> exportSingleCallTranscript(CallLog callLog) async {
    try {
      final callData = _convertToCallData(callLog);
      await FirebaseExportService.exportCallTranscript(callData);
      print('✅ Exported call transcript for: ${callLog.displayName}');
    } catch (e) {
      print('❌ Error exporting single call transcript: $e');
    }
  }

  /// Export recent calls from last N days
  static Future<void> exportRecentCalls({int days = 7}) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: days));
      final allCallLogs = await CallLogService.getCallLogs();

      final recentCalls = allCallLogs
          .where((call) => call.timestamp.isAfter(cutoffDate))
          .toList();

      if (recentCalls.isEmpty) {
        print('ℹ️ No recent calls found from last $days days');
        return;
      }

      int exportedCount = 0;
      for (final callLog in recentCalls) {
        final callData = _convertToCallData(callLog);
        final success =
            await FirebaseExportService.exportCallTranscript(callData);
        if (success) exportedCount++;
      }

      print('✅ Exported $exportedCount recent calls from last $days days');
    } catch (e) {
      print('❌ Error exporting recent calls: $e');
    }
  }

  /// Export calls by type (incoming/outgoing)
  static Future<void> exportCallsByType({required bool isIncoming}) async {
    try {
      final allCallLogs = await CallLogService.getCallLogs();
      final filteredCalls = allCallLogs
          .where((call) => (call.type.name == 'incoming') == isIncoming)
          .toList();

      if (filteredCalls.isEmpty) {
        final type = isIncoming ? 'incoming' : 'outgoing';
        print('ℹ️ No $type calls found');
        return;
      }

      int exportedCount = 0;
      for (final callLog in filteredCalls) {
        final callData = _convertToCallData(callLog);
        final success =
            await FirebaseExportService.exportCallTranscript(callData);
        if (success) exportedCount++;
      }

      final type = isIncoming ? 'incoming' : 'outgoing';
      print('✅ Exported $exportedCount $type calls');
    } catch (e) {
      print('❌ Error exporting calls by type: $e');
    }
  }

  /// Get call export statistics
  static Future<Map<String, dynamic>> getCallExportStats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('❌ No authenticated user for call export stats');
        return {
          'total_calls': 0,
          'incoming_calls': 0,
          'outgoing_calls': 0,
          'error': 'No authenticated user',
        };
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(FirebaseExportService.callTranscriptsCollection)
          .get();

      final docs = snapshot.docs;
      final totalCount = docs.length;

      int incomingCount = 0;
      int outgoingCount = 0;

      for (final doc in docs) {
        final callType = doc.data()['call_type'] as String? ?? 'incoming';
        final isIncoming = callType == 'incoming';
        if (isIncoming) {
          incomingCount++;
        } else {
          outgoingCount++;
        }
      }

      return {
        'total_calls': totalCount,
        'incoming_calls': incomingCount,
        'outgoing_calls': outgoingCount,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting call export stats: $e');
      return {
        'total_calls': 0,
        'incoming_calls': 0,
        'outgoing_calls': 0,
        'error': e.toString(),
      };
    }
  }

  /// Convert CallLog to Call for export
  static call_model.Call _convertToCallData(CallLog callLog) {
    return call_model.Call(
      callId: callLog.id,
      transcript: _generateCallSummary(callLog),
      summary: _generateCallSummary(callLog),
      participants: [
        callLog.displayName.isNotEmpty
            ? callLog.displayName
            : callLog.phoneNumber
      ],
      durationSecs: callLog.duration,
      timestamp: callLog.timestamp,
      processedBy: 'mobile_app',
      actionIds: [],
      audioStoragePath: null,
      callType: call_model.CallType.values.firstWhere(
          (t) => t.name == callLog.type.name,
          orElse: () => call_model.CallType.incoming),
      contactName: callLog.displayName.isNotEmpty ? callLog.displayName : null,
      priority: call_model.CallPriority.medium,
      sentiment: 'Neutral',
      category: _getCallCategory(callLog),
      keyPoints: _generateKeyPoints(callLog),
      status: call_model.CallStatus.processed,
      metadata: {},
    );
  }

  /// Generate call summary
  static String _generateCallSummary(CallLog callLog) {
    final type = callLog.type.name.toUpperCase();
    final contact = callLog.displayName.isNotEmpty
        ? callLog.displayName
        : 'Unknown Contact';
    final duration = Duration(seconds: callLog.duration);

    return '$type call with $contact lasting ${_formatDuration(duration)}';
  }

  /// Generate key points
  static List<String> _generateKeyPoints(CallLog callLog) {
    return [
      'Call duration: ${_formatDuration(Duration(seconds: callLog.duration))}',
      'Contact: ${callLog.displayName.isNotEmpty ? callLog.displayName : callLog.phoneNumber}',
      'Type: ${callLog.type.name.toUpperCase()}',
    ];
  }

  /// Get call category based on contact info
  static String _getCallCategory(CallLog callLog) {
    final name = (callLog.contactName ?? callLog.displayName).toLowerCase();
    final number = callLog.phoneNumber;

    if (name.contains('work') ||
        name.contains('office') ||
        name.contains('business')) {
      return 'Business';
    } else if (name.contains('doctor') ||
        name.contains('hospital') ||
        name.contains('clinic')) {
      return 'Healthcare';
    } else if (name.contains('family') ||
        name.contains('mom') ||
        name.contains('dad')) {
      return 'Family';
    } else if (number.startsWith('1800') || number.startsWith('800')) {
      return 'Customer Service';
    } else {
      return 'Personal';
    }
  }

  /// Format duration helper
  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }
}
