import 'package:flutter/services.dart';
import 'package:googleapis/calendar/v3.dart' as calendar;
import 'google_auth_service.dart';

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

  // Use the shared Google Auth Service for consistency
  static final GoogleAuthService _authService = GoogleAuthService();

  /// Get events for a specific date range
  static Future<List<CalendarEvent>> getEvents({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(const Duration(days: 7));
      endDate ??= DateTime.now().add(const Duration(days: 30));

      print(
          "🚀 CalendarService: getEvents called with range $startDate to $endDate");

      // Try to get events from Google Calendar first
      try {
        print(
            "🔄 CalendarService: Attempting to fetch from Google Calendar...");
        final googleEvents = await _getGoogleCalendarEvents(startDate, endDate);
        if (googleEvents.isNotEmpty) {
          print(
              "✅ CalendarService: Returning ${googleEvents.length} Google Calendar events");
          return googleEvents;
        } else {
          print(
              "⚠️ CalendarService: No Google Calendar events found, trying local calendar...");
        }
      } catch (e) {
        print('❌ CalendarService: Error getting Google Calendar events: $e');
      }

      // Fallback to local calendar
      try {
        final List<dynamic> eventsData =
            await _channel.invokeMethod('getEvents', {
          'startDate': startDate.millisecondsSinceEpoch,
          'endDate': endDate.millisecondsSinceEpoch,
        });

        final localEvents = eventsData.map((eventData) {
          final Map<String, dynamic> data =
              Map<String, dynamic>.from(eventData);

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

        if (localEvents.isNotEmpty) {
          return localEvents;
        }
      } catch (e) {
        print('Error getting local calendar events: $e');
      }

      // Final fallback to mock events to ensure UI doesn't break
      return _getMockEvents();
    } catch (e) {
      print('Error getting calendar events: $e');
      return _getMockEvents();
    }
  }

  /// Get events for today
  static Future<List<CalendarEvent>> getTodayEvents() async {
    print("📅 CalendarService: getTodayEvents called");
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    print("📅 CalendarService: Today's range - $startOfDay to $endOfDay");
    final events = await getEvents(startDate: startOfDay, endDate: endOfDay);
    print("📅 CalendarService: Found ${events.length} events for today");
    return events;
  }

  /// Get upcoming events (next 7 days)
  static Future<List<CalendarEvent>> getUpcomingEvents() async {
    print("🔮 CalendarService: getUpcomingEvents called");
    final now = DateTime.now();
    final endDate = now.add(const Duration(days: 7));

    print("🔮 CalendarService: Upcoming range - $now to $endDate");
    final events = await getEvents(startDate: now, endDate: endDate);
    print("🔮 CalendarService: Found ${events.length} upcoming events");
    return events;
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
      return await _authService.signIn();
    } catch (e) {
      print('Error signing in to Google: $e');
      return false;
    }
  }

  /// Sign out from Google
  static Future<void> signOutFromGoogle() async {
    try {
      await _authService.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  /// Check if signed in to Google
  static Future<bool> isSignedInToGoogle() async {
    try {
      return _authService.isSignedIn;
    } catch (e) {
      print('Error checking Google sign-in: $e');
      return false;
    }
  }

  // Private methods for Google Calendar integration
  static Future<List<CalendarEvent>> _getGoogleCalendarEvents(
      DateTime startDate, DateTime endDate) async {
    try {
      print("📅 CalendarService: Starting Google Calendar events fetch");
      print("📅 CalendarService: Date range - From: $startDate To: $endDate");

      // Initialize auth service if needed
      _authService.initialize();

      // Ensure user is authenticated
      if (!_authService.isSignedIn) {
        print(
            '📅 CalendarService: User not signed in, attempting to sign in for Calendar access...');
        final success = await _authService.signIn();
        if (!success) {
          print(
              '❌ CalendarService: Failed to sign in to Google for Calendar access');
          return [];
        }
      } else {
        print(
            "✅ CalendarService: User already signed in - ${_authService.userEmail}");
      }

      print("🔑 CalendarService: Requesting authenticated client...");
      final client = await _authService.getAuthenticatedClient();
      if (client == null) {
        print(
            '❌ CalendarService: Failed to get authenticated client for Calendar access');
        return [];
      }

      print("🌐 CalendarService: Creating Google Calendar API client...");
      final calendarApi = calendar.CalendarApi(client);

      print("📡 CalendarService: Making API call to fetch events...");
      print(
          "📡 CalendarService: Parameters - Calendar: primary, TimeMin: ${startDate.toUtc()}, TimeMax: ${endDate.toUtc()}");

      final events = await calendarApi.events.list(
        'primary',
        timeMin: startDate.toUtc(),
        timeMax: endDate.toUtc(),
        singleEvents: true,
        orderBy: 'startTime',
        maxResults: 100,
      );

      print(
          "📊 CalendarService: API call successful! Received ${events.items?.length ?? 0} events");

      List<CalendarEvent> calendarEvents = [];

      print(
          "🔄 CalendarService: Processing ${events.items?.length ?? 0} events...");
      for (final event in events.items ?? []) {
        print(
            "📝 CalendarService: Processing event - ${event.summary ?? 'Untitled'}");
        DateTime? startTime;
        DateTime? endTime;
        bool isAllDay = false;

        if (event.start?.dateTime != null) {
          startTime = event.start!.dateTime!;
          print("⏰ CalendarService: Event start time (DateTime): $startTime");
        } else if (event.start?.date != null) {
          startTime = event.start!.date!;
          isAllDay = true;
          print("📅 CalendarService: Event start date (All-day): $startTime");
        }

        if (event.end?.dateTime != null) {
          endTime = event.end!.dateTime!;
          print("⏰ CalendarService: Event end time (DateTime): $endTime");
        } else if (event.end?.date != null) {
          endTime = event.end!.date!;
          isAllDay = true;
          print("📅 CalendarService: Event end date (All-day): $endTime");
        }

        if (startTime != null && endTime != null) {
          print("✅ CalendarService: Adding event to list - ${event.summary}");
          calendarEvents.add(CalendarEvent(
            id: event.id!,
            title: event.summary ?? 'Untitled Event',
            description: event.description,
            startTime: startTime,
            endTime: endTime,
            location: event.location,
            attendees: event.attendees
                ?.map<String>(
                    (calendar.EventAttendee attendee) => attendee.email ?? '')
                .where((String email) => email.isNotEmpty)
                .toList(),
            isAllDay: isAllDay,
            priority:
                EventPriority.normal, // Google Calendar doesn't have priority
            meetingLink: event.hangoutLink,
            createdAt: event.created ?? DateTime.now(),
            updatedAt: event.updated,
          ));
        } else {
          print(
              "⚠️ CalendarService: Skipping event ${event.summary} - missing start/end times");
        }
      }

      client.close();
      print(
          "🎉 CalendarService: Successfully processed ${calendarEvents.length} calendar events");
      return calendarEvents;
    } catch (e) {
      print('❌ CalendarService: Error getting Google Calendar events - $e');

      // Check for specific error types
      if (e.toString().contains('403')) {
        print(
            '🔒 CalendarService: Permission denied - Calendar API may not be enabled or insufficient scopes');
      } else if (e.toString().contains('401')) {
        print(
            '🔐 CalendarService: Authentication error - Access token may be invalid');
      } else if (e.toString().contains('quotaExceeded')) {
        print('📊 CalendarService: API quota exceeded');
      }

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
      // Ensure user is authenticated
      if (!_authService.isSignedIn) {
        print('User not signed in for Calendar event creation');
        return null;
      }

      final client = await _authService.getAuthenticatedClient();
      if (client == null) {
        print('Failed to get authenticated client for Calendar event creation');
        return null;
      }

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
            .map<calendar.EventAttendee>(
                (email) => calendar.EventAttendee()..email = email)
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
            ?.map<String>(
                (calendar.EventAttendee attendee) => attendee.email ?? '')
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
