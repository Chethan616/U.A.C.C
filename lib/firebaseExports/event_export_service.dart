import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/calendar_service.dart';
import 'firebase_export_service.dart';

/// Event Export Service
/// Handles exporting calendar event data to Firebase for web dashboard
class EventExportService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Export all calendar events to Firebase
  static Future<void> exportAllEvents() async {
    try {
      print('🔄 Starting calendar events export...');

      // Get events from calendar service
      final events = await CalendarService.getEvents(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 90)),
      );

      if (events.isEmpty) {
        print('ℹ️ No calendar events to export');
        return;
      }

      int exportedCount = 0;

      for (final event in events) {
        final success = await FirebaseExportService.exportEvent(event);
        if (success) exportedCount++;
      }

      // Update dashboard metadata
      await FirebaseExportService.updateDashboardMetadata(
        eventCount: exportedCount,
      );

      print(
          '✅ Exported $exportedCount/${events.length} calendar events to Firebase');
    } catch (e) {
      print('❌ Error exporting calendar events: $e');
    }
  }

  /// Export a single event (real-time)
  static Future<void> exportSingleEvent(CalendarEvent event) async {
    try {
      await FirebaseExportService.exportEvent(event);
      print('✅ Exported event: ${event.title}');
    } catch (e) {
      print('❌ Error exporting single event: $e');
    }
  }

  /// Export events for a specific date range
  static Future<void> exportEventsInRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final events = await CalendarService.getEvents(
        startDate: startDate,
        endDate: endDate,
      );

      if (events.isEmpty) {
        print('ℹ️ No events found in specified range');
        return;
      }

      int exportedCount = 0;
      for (final event in events) {
        final success = await FirebaseExportService.exportEvent(event);
        if (success) exportedCount++;
      }

      print(
          '✅ Exported $exportedCount events from ${startDate.toIso8601String().substring(0, 10)} to ${endDate.toIso8601String().substring(0, 10)}');
    } catch (e) {
      print('❌ Error exporting events in range: $e');
    }
  }

  /// Export upcoming events (next N days)
  static Future<void> exportUpcomingEvents({int days = 30}) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));

      await exportEventsInRange(startDate: now, endDate: futureDate);
    } catch (e) {
      print('❌ Error exporting upcoming events: $e');
    }
  }

  /// Export events by category
  static Future<void> exportEventsByCategory(String category) async {
    try {
      final allEvents = await CalendarService.getEvents(
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        endDate: DateTime.now().add(const Duration(days: 90)),
      );

      final categoryEvents = allEvents
          .where((event) =>
              event.title.toLowerCase().contains(category.toLowerCase()))
          .toList();

      if (categoryEvents.isEmpty) {
        print('ℹ️ No events found for category: $category');
        return;
      }

      int exportedCount = 0;
      for (final event in categoryEvents) {
        final success = await FirebaseExportService.exportEvent(event);
        if (success) exportedCount++;
      }

      print('✅ Exported $exportedCount events for category: $category');
    } catch (e) {
      print('❌ Error exporting events by category: $e');
    }
  }

  /// Get event export statistics
  static Future<Map<String, dynamic>> getEventExportStats() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print('❌ No authenticated user for event export stats');
        return {
          'total_events': 0,
          'upcoming_events': 0,
          'past_events': 0,
          'categories': {},
          'error': 'No authenticated user',
        };
      }

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection(FirebaseExportService.eventsCollection)
          .get();

      final docs = snapshot.docs;
      final totalCount = docs.length;

      // Count by category
      final categoryCount = <String, int>{};
      int upcomingCount = 0;
      int pastCount = 0;
      final now = DateTime.now();

      for (final doc in docs) {
        final data = doc.data();
        final title = data['title'] as String? ?? '';
        final category = _determineEventCategory(title);
        categoryCount[category] = (categoryCount[category] ?? 0) + 1;

        final startTimeTimestamp = data['start_time'] as Timestamp?;
        if (startTimeTimestamp != null) {
          final startTime = startTimeTimestamp.toDate();
          if (startTime.isAfter(now)) {
            upcomingCount++;
          } else {
            pastCount++;
          }
        }
      }

      return {
        'total_events': totalCount,
        'upcoming_events': upcomingCount,
        'past_events': pastCount,
        'categories': categoryCount,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error getting event export stats: $e');
      return {
        'total_events': 0,
        'upcoming_events': 0,
        'past_events': 0,
        'categories': {},
        'error': e.toString(),
      };
    }
  }

  /// Setup real-time event export
  static void setupRealtimeEventExport() {
    print('🔄 Setting up real-time event export...');

    // This would listen to calendar changes and export new/updated events
    // Implementation depends on your calendar service setup
  }

  /// Determine event category based on title/content
  static String _determineEventCategory(String title) {
    final content = title.toLowerCase();

    if (content.contains('meeting') ||
        content.contains('call') ||
        content.contains('interview')) {
      return 'Meeting';
    } else if (content.contains('appointment') ||
        content.contains('doctor') ||
        content.contains('clinic')) {
      return 'Appointment';
    } else if (content.contains('personal') ||
        content.contains('family') ||
        content.contains('birthday')) {
      return 'Personal';
    } else if (content.contains('work') ||
        content.contains('project') ||
        content.contains('conference')) {
      return 'Work';
    } else {
      return 'General';
    }
  }
}
