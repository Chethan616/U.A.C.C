import 'dart:math';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'calendar_service.dart';

class CookieCalendarWidgetBridge {
  CookieCalendarWidgetBridge._();

  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/cookie_calendar_widget');

  /// Refreshes the native cookie calendar widget using events for the current day.
  static Future<void> updateFromTodaySchedule() async {
    final today = DateTime.now();
    final events = await CalendarService.getTodayEvents();
    await updateWithEvents(referenceDate: today, events: events);
  }

  /// Refreshes the native widget with a specific event snapshot.
  ///
  /// [referenceDate] controls the day rendered in the widget.
  static Future<void> updateWithEvents({
    required DateTime referenceDate,
    required List<CalendarEvent> events,
  }) async {
    try {
      final todaysEvents = events
          .where((event) => _isSameDay(event.startTime, referenceDate))
          .toList();

      final progress = _calculateProgress(referenceDate, todaysEvents);
      final monthLabel = DateFormat('MMM').format(referenceDate);

      await _channel.invokeMethod('updateCookieCalendar', {
        'day': referenceDate.day,
        'monthName': monthLabel,
        'year': referenceDate.year,
        'progress': progress,
      });
    } on PlatformException catch (error) {
      // Surface in debug logs but keep the app resilient.
      // ignore: avoid_print
      print('❌ CookieCalendarWidgetBridge: ${error.message}');
    } catch (error) {
      // ignore: avoid_print
      print('❌ CookieCalendarWidgetBridge: $error');
    }
  }

  /// Clears any persisted state from the native widget.
  static Future<void> clear() async {
    try {
      await _channel.invokeMethod('clearCookieCalendar');
    } on PlatformException catch (error) {
      // ignore: avoid_print
      print('❌ CookieCalendarWidgetBridge.clear: ${error.message}');
    } catch (error) {
      // ignore: avoid_print
      print('❌ CookieCalendarWidgetBridge.clear: $error');
    }
  }

  static bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  static double _calculateProgress(
    DateTime now,
    List<CalendarEvent> todaysEvents,
  ) {
    if (todaysEvents.isEmpty) {
      final minutesSinceMidnight = now.hour * 60 + now.minute;
      return (minutesSinceMidnight / (24 * 60)).clamp(0.0, 1.0);
    }

    final startMs = todaysEvents
        .map((event) => event.isAllDay
            ? DateTime(now.year, now.month, now.day).millisecondsSinceEpoch
            : event.startTime.millisecondsSinceEpoch)
        .reduce(min);

    final endMs = todaysEvents
        .map((event) => event.isAllDay
            ? DateTime(now.year, now.month, now.day, 23, 59, 59)
                .millisecondsSinceEpoch
            : event.endTime.millisecondsSinceEpoch)
        .reduce(max);

    if (endMs <= startMs) {
      return now.millisecondsSinceEpoch >= endMs ? 1.0 : 0.0;
    }

    final clampedNow =
        now.millisecondsSinceEpoch.clamp(startMs, endMs).toDouble();
    final progress = (clampedNow - startMs) / (endMs - startMs);
    return progress.clamp(0.0, 1.0).toDouble();
  }
}
