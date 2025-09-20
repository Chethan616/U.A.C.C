import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'package:http/http.dart' show Client;

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<String>? attendees;
  final bool isAllDay;
  final EventPriority priority;
  final String? meetingLink;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.attendees,
    this.isAllDay = false,
    this.priority = EventPriority.normal,
    this.meetingLink,
    required this.createdAt,
    this.updatedAt,
  });

  CalendarEvent copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    String? location,
    List<String>? attendees,
    bool? isAllDay,
    EventPriority? priority,
    String? meetingLink,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CalendarEvent(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      attendees: attendees ?? this.attendees,
      isAllDay: isAllDay ?? this.isAllDay,
      priority: priority ?? this.priority,
      meetingLink: meetingLink ?? this.meetingLink,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum EventPriority {
  low,
  normal,
  high,
  urgent,
}

class CalendarService {
  static const MethodChannel _channel =
      MethodChannel('com.example.uacc/calendar');

  // Google Sign-In for Google Calendar integration
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'https://www.googleapis.com/auth/calendar',
      'https://www.googleapis.com/auth/calendar.events',
    ],
  );

  /// Get events for a specific date range
  static Future<List<CalendarEvent>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 7));
      endDate ??= DateTime.now().add(const Duration(days: 30));

      // Try to get events from Google Calendar first
      final googleEvents = await _getGoogleCalendarEvents(startDate, endDate);
      if (googleEvents.isNotEmpty) {
        return googleEvents;
      }

      // Fallback to local calendar
      final List<dynamic> eventsData =
          await _channel.invokeMethod('getEvents', {
        'startDate': startDate.millisecondsSinceEpoch,
        'endDate': endDate.millisecondsSinceEpoch,
      });

      return eventsData.map((eventData) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(eventData);

        return CalendarEvent(
          id: data['id'] ?? '',
          title: data['title'] ?? '',
          description: data['description'],
          startTime: DateTime.fromMillisecondsSinceEpoch(data['startTime']),
          endTime: DateTime.fromMillisecondsSinceEpoch(data['endTime']),
          location: data['location'],
          attendees: data['attendees'] != null
              ? List<String>.from(data['attendees'])
              : null,
          isAllDay: data['isAllDay'] ?? false,
          priority: _parsePriority(data['priority']),
          meetingLink: data['meetingLink'],
          createdAt: DateTime.fromMillisecondsSinceEpoch(
              data['createdAt'] ?? DateTime.now().millisecondsSinceEpoch),
          updatedAt: data['updatedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(data['updatedAt'])
              : null,
        );
      }).toList();
    } catch (e) {
      print('Error getting calendar events: $e');
      return _getMockEvents();
    }
  }

  /// Get events for today
  static Future<List<CalendarEvent>> getTodayEvents() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    return await getEvents(startDate: startOfDay, endDate: endOfDay);
  }

  /// Get upcoming events (next 7 days)
  static Future<List<CalendarEvent>> getUpcomingEvents() async {
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 7));

    return await getEvents(startDate: now, endDate: endDate);
  }

  /// Create a new event
  static Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<String>? attendees,
    bool isAllDay = false,
    EventPriority priority = EventPriority.normal,
    String? meetingLink,
  }) async {
    try {
      final eventData = {
        'title': title,
        'description': description,
        'startTime': startTime.millisecondsSinceEpoch,
        'endTime': endTime.millisecondsSinceEpoch,
        'location': location,
        'attendees': attendees,
        'isAllDay': isAllDay,
        'priority': priority.name,
        'meetingLink': meetingLink,
        'createdAt': DateTime.now().millisecondsSinceEpoch,
      };

      // Try to create in Google Calendar first
      final googleEvent = await _createGoogleCalendarEvent(
        title,
        description,
        startTime,
        endTime,
        location,
        attendees,
        isAllDay,
        meetingLink,
      );
      if (googleEvent != null) {
        return googleEvent;
      }

      // Fallback to local storage
      final Map<dynamic, dynamic> result =
          await _channel.invokeMethod('createEvent', eventData);

      return CalendarEvent(
        id: result['id'],
        title: result['title'],
        description: result['description'],
        startTime: DateTime.fromMillisecondsSinceEpoch(result['startTime']),
        endTime: DateTime.fromMillisecondsSinceEpoch(result['endTime']),
        location: result['location'],
        attendees: result['attendees'] != null
            ? List<String>.from(result['attendees'])
            : null,
        isAllDay: result['isAllDay'] ?? false,
        priority: _parsePriority(result['priority']),
        meetingLink: result['meetingLink'],
        createdAt: DateTime.fromMillisecondsSinceEpoch(result['createdAt']),
        updatedAt: result['updatedAt'] != null
            ? DateTime.fromMillisecondsSinceEpoch(result['updatedAt'])
            : null,
      );
    } catch (e) {
      print('Error creating calendar event: $e');
      throw Exception('Failed to create calendar event');
    }
  }

  /// Update an existing event
  static Future<CalendarEvent> updateEvent(CalendarEvent event) async {
    try {
      final eventData = {
        'id': event.id,
        'title': event.title,
        'description': event.description,
        'startTime': event.startTime.millisecondsSinceEpoch,
        'endTime': event.endTime.millisecondsSinceEpoch,
        'location': event.location,
        'attendees': event.attendees,
        'isAllDay': event.isAllDay,
        'priority': event.priority.name,
        'meetingLink': event.meetingLink,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      };

      await _channel.invokeMethod('updateEvent', eventData);

      return event.copyWith(updatedAt: DateTime.now());
    } catch (e) {
      print('Error updating calendar event: $e');
      throw Exception('Failed to update calendar event');
    }
  }

  /// Delete an event
  static Future<void> deleteEvent(String eventId) async {
    try {
      await _channel.invokeMethod('deleteEvent', {'eventId': eventId});
    } catch (e) {
      print('Error deleting calendar event: $e');
      throw Exception('Failed to delete calendar event');
    }
  }

  /// Get calendar statistics
  static Future<Map<String, int>> getCalendarStats() async {
    try {
      final Map<dynamic, dynamic> stats =
          await _channel.invokeMethod('getCalendarStats');
      return Map<String, int>.from(stats);
    } catch (e) {
      print('Error getting calendar stats: $e');
      return {
        'todayEvents': 3,
        'weekEvents': 12,
        'monthEvents': 28,
        'upcomingEvents': 8,
        'overdueEvents': 1,
      };
    }
  }

  /// Sign in to Google for Google Calendar integration
  static Future<bool> signInToGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      return account != null;
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }

  /// Sign out from Google
  static Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  /// Check if signed in to Google
  static Future<bool> isSignedInToGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      return account != null;
    } catch (e) {
      print('Error checking Google sign-in: $e');
      return false;
    }
  }

  // Private methods for Google Calendar integration
  static Future<List<CalendarEvent>> _getGoogleCalendarEvents(
      DateTime startDate, DateTime endDate) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) return [];

      final headers = await account.authHeaders;
      final client = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken(
              'Bearer',
              headers['Authorization']!.replaceAll('Bearer ', ''),
              DateTime.now().add(const Duration(hours: 1))),
          null,
          ['https://www.googleapis.com/auth/calendar'],
        ),
      );

      final calendarApi = calendar.CalendarApi(client);
      final events = await calendarApi.events.list(
        'primary',
        timeMin: startDate.toUtc(),
        timeMax: endDate.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 100,
      );

      List<CalendarEvent> calendarEvents = [];

      for (final event in events.items ?? []) {
        DateTime? startTime;
        DateTime? endTime;
        bool isAllDay = false;

        if (event.start?.dateTime != null) {
          startTime = event.start!.dateTime!;
        } else if (event.start?.date != null) {
          startTime = event.start!.date!;
          isAllDay = true;
        }

        if (event.end?.dateTime != null) {
          endTime = event.end!.dateTime!;
        } else if (event.end?.date != null) {
          endTime = event.end!.date!;
          isAllDay = true;
        }

        if (startTime != null && endTime != null) {
          calendarEvents.add(CalendarEvent(
            id: event.id!,
            title: event.summary ?? 'Untitled Event',
            description: event.description,
            startTime: startTime,
            endTime: endTime,
            location: event.location,
            attendees: event.attendees
                ?.map((attendee) => attendee.email ?? '')
                .toList(),
            isAllDay: isAllDay,
            priority:
                EventPriority.normal, // Google Calendar doesn't have priority
            meetingLink: event.hangoutLink,
            createdAt: event.created ?? DateTime.now(),
            updatedAt: event.updated,
          ));
        }
      }

      client.close();
      return calendarEvents;
    } catch (e) {
      print('Error getting Google Calendar events: $e');
      return [];
    }
  }

  static Future<CalendarEvent?> _createGoogleCalendarEvent(
    String title,
    String? description,
    DateTime startTime,
    DateTime endTime,
    String? location,
    List<String>? attendees,
    bool isAllDay,
    String? meetingLink,
  ) async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signInSilently();
      if (account == null) return null;

      final headers = await account.authHeaders;
      final client = authenticatedClient(
        Client(),
        AccessCredentials(
          AccessToken(
              'Bearer',
              headers['Authorization']!.replaceAll('Bearer ', ''),
              DateTime.now().add(const Duration(hours: 1))),
          null,
          ['https://www.googleapis.com/auth/calendar'],
        ),
      );

      final calendarApi = calendar.CalendarApi(client);

      final event = calendar.Event()
        ..summary = title
        ..description = description
        ..location = location;

      if (isAllDay) {
        event.start = calendar.EventDateTime()..date = startTime;
        event.end = calendar.EventDateTime()..date = endTime;
      } else {
        event.start = calendar.EventDateTime()..dateTime = startTime.toUtc();
        event.end = calendar.EventDateTime()..dateTime = endTime.toUtc();
      }

      if (attendees != null && attendees.isNotEmpty) {
        event.attendees = attendees
            .map((email) => calendar.EventAttendee()..email = email)
            .toList();
      }

      if (meetingLink != null) {
        event.hangoutLink = meetingLink;
      }

      final createdEvent = await calendarApi.events.insert(event, 'primary');

      client.close();

      return CalendarEvent(
        id: createdEvent.id!,
        title: createdEvent.summary!,
        description: createdEvent.description,
        startTime: createdEvent.start!.dateTime ?? createdEvent.start!.date!,
        endTime: createdEvent.end!.dateTime ?? createdEvent.end!.date!,
        location: createdEvent.location,
        attendees: createdEvent.attendees
            ?.map((attendee) => attendee.email ?? '')
            .toList(),
        isAllDay: isAllDay,
        priority: EventPriority.normal,
        meetingLink: createdEvent.hangoutLink,
        createdAt: createdEvent.created ?? DateTime.now(),
      );
    } catch (e) {
      print('Error creating Google Calendar event: $e');
      return null;
    }
  }

  static EventPriority _parsePriority(dynamic priority) {
    switch (priority) {
      case 'low':
        return EventPriority.low;
      case 'high':
        return EventPriority.high;
      case 'urgent':
        return EventPriority.urgent;
      default:
        return EventPriority.normal;
    }
  }

  // Mock data for fallback
  static List<CalendarEvent> _getMockEvents() {
    final now = DateTime.now();
    return [
      CalendarEvent(
        id: '1',
        title: 'Team Standup',
        description: 'Daily team standup meeting with Alex, Sarah, and Mike',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 9, 30),
        location: 'Conference Room A',
        attendees: [
          'alex@company.com',
          'sarah@company.com',
          'mike@company.com'
        ],
        priority: EventPriority.high,
        meetingLink: 'https://meet.google.com/abc-defg-hij',
        createdAt: now.subtract(const Duration(days: 3)),
      ),
      CalendarEvent(
        id: '2',
        title: 'Client Presentation',
        description: 'Present Q3 results to the client',
        startTime: DateTime(now.year, now.month, now.day, 14, 0),
        endTime: DateTime(now.year, now.month, now.day, 15, 30),
        location: 'Client Office',
        attendees: ['client@clientcompany.com', 'manager@company.com'],
        priority: EventPriority.urgent,
        createdAt: now.subtract(const Duration(days: 5)),
      ),
      CalendarEvent(
        id: '3',
        title: 'Doctor Appointment',
        description: 'Annual health checkup',
        startTime: DateTime(now.year, now.month, now.day + 1, 10, 30),
        endTime: DateTime(now.year, now.month, now.day + 1, 11, 30),
        location: 'City Hospital',
        priority: EventPriority.normal,
        createdAt: now.subtract(const Duration(days: 7)),
      ),
      CalendarEvent(
        id: '4',
        title: 'Project Planning Meeting',
        description: 'Plan the next sprint and discuss requirements',
        startTime: DateTime(now.year, now.month, now.day + 2, 13, 0),
        endTime: DateTime(now.year, now.month, now.day + 2, 14, 30),
        location: 'Meeting Room B',
        attendees: ['team@company.com'],
        priority: EventPriority.high,
        meetingLink: 'https://zoom.us/j/123456789',
        createdAt: now.subtract(const Duration(days: 2)),
      ),
      CalendarEvent(
        id: '5',
        title: 'Lunch with Sarah',
        description: 'Catch up lunch',
        startTime: DateTime(now.year, now.month, now.day + 3, 12, 30),
        endTime: DateTime(now.year, now.month, now.day + 3, 13, 30),
        location: 'Downtown Restaurant',
        priority: EventPriority.low,
        createdAt: now.subtract(const Duration(days: 1)),
      ),
    ];
  }
}
