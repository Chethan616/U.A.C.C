// lib/widgets/upcoming_events_carousel.dart
import 'package:flutter/material.dart';
import '../services/calendar_service.dart';
import '../screens/all_events_screen.dart';
// Uses Theme.of(context) tokens for colors

class UpcomingEventsCarousel extends StatefulWidget {
  const UpcomingEventsCarousel({Key? key}) : super(key: key);

  @override
  State<UpcomingEventsCarousel> createState() => _UpcomingEventsCarouselState();
}

class _UpcomingEventsCarouselState extends State<UpcomingEventsCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85,
    initialPage: 0,
  );

  List<EventData> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEvents();
  }

  Future<void> _loadEvents() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print("🎠 UpcomingEventsCarousel: Loading upcoming events...");
      final calendarEvents = await CalendarService.getUpcomingEvents();
      print(
          "🎠 UpcomingEventsCarousel: Received ${calendarEvents.length} calendar events");

      if (calendarEvents.isNotEmpty) {
        for (final event in calendarEvents) {
          print(
              "🎠 UpcomingEventsCarousel: Event - ${event.title} at ${event.startTime}");
        }
      }

      setState(() {
        _events = calendarEvents
            .map((event) => _convertCalendarEventToEventData(event))
            .toList();
        _isLoading = false;
      });
      print(
          "🎠 UpcomingEventsCarousel: UI updated with ${_events.length} events");
    } catch (e) {
      print('❌ UpcomingEventsCarousel: Error loading calendar events - $e');
      // Fallback to mock data if calendar loading fails
      setState(() {
        _events = _getMockEvents();
        _isLoading = false;
      });
      print("🎠 UpcomingEventsCarousel: Using mock data as fallback");
    }
  }

  EventData _convertCalendarEventToEventData(CalendarEvent calendarEvent) {
    // Format time display
    String timeString;
    if (calendarEvent.isAllDay) {
      timeString = 'All day';
    } else {
      final startTime = calendarEvent.startTime;
      final endTime = calendarEvent.endTime;
      timeString = '${_formatTime(startTime)} - ${_formatTime(endTime)}';
    }

    // Determine date display
    final now = DateTime.now();
    final eventDate = calendarEvent.startTime;
    String dateString;
    if (_isSameDay(eventDate, now)) {
      dateString = 'Today';
    } else if (_isSameDay(eventDate, now.add(const Duration(days: 1)))) {
      dateString = 'Tomorrow';
    } else {
      dateString = '${eventDate.month}/${eventDate.day}';
    }

    // Choose color based on category first, then priority
    final category = _getEventCategory(calendarEvent);
    Color eventColor = _getCategoryColor(category);

    // Override with priority colors if set
    switch (calendarEvent.priority) {
      case EventPriority.urgent:
        eventColor = Colors.deepOrange;
        break;
      case EventPriority.high:
        eventColor = Colors.red;
        break;
      case EventPriority.low:
        // Keep category color for low priority
        break;
      default:
        // Keep category color for normal priority
        break;
    }

    return EventData(
      title: calendarEvent.title,
      time: timeString,
      date: dateString,
      location: calendarEvent.location ?? 'No location',
      attendees: calendarEvent.attendees?.length ?? 0,
      color: eventColor,
      category: category,
      icon: _getCategoryIcon(category),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour == 0
        ? 12
        : (dateTime.hour > 12 ? dateTime.hour - 12 : dateTime.hour);
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _getEventCategory(CalendarEvent event) {
    // Enhanced category determination based on title, location, or description
    final title = event.title.toLowerCase();
    final location = event.location?.toLowerCase() ?? '';

    // Work related
    if (title.contains('meeting') ||
        title.contains('call') ||
        title.contains('standup') ||
        title.contains('presentation') ||
        title.contains('review') ||
        title.contains('sync') ||
        location.contains('office') ||
        location.contains('conference room')) return 'Work';

    // Health & Medical
    if (title.contains('doctor') ||
        title.contains('appointment') ||
        title.contains('checkup') ||
        title.contains('dentist') ||
        title.contains('medical') ||
        title.contains('hospital') ||
        location.contains('hospital') ||
        location.contains('clinic')) return 'Health';

    // Fitness & Sports
    if (title.contains('gym') ||
        title.contains('workout') ||
        title.contains('exercise') ||
        title.contains('yoga') ||
        title.contains('fitness') ||
        title.contains('sport') ||
        location.contains('gym') ||
        location.contains('fitness')) return 'Fitness';

    // Social & Entertainment
    if (title.contains('lunch') ||
        title.contains('dinner') ||
        title.contains('party') ||
        title.contains('birthday') ||
        title.contains('celebration') ||
        title.contains('hangout') ||
        title.contains('movie') ||
        title.contains('concert')) return 'Social';

    // Education & Learning
    if (title.contains('class') ||
        title.contains('course') ||
        title.contains('training') ||
        title.contains('workshop') ||
        title.contains('seminar') ||
        title.contains('lecture') ||
        location.contains('school') ||
        location.contains('university')) return 'Education';

    // Travel & Transportation
    if (title.contains('flight') ||
        title.contains('travel') ||
        title.contains('trip') ||
        title.contains('vacation') ||
        title.contains('holiday') ||
        location.contains('airport') ||
        location.contains('station')) return 'Travel';

    return 'Personal';
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Icons.work_outline;
      case 'health':
        return Icons.health_and_safety_outlined;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'social':
        return Icons.people_outline;
      case 'education':
        return Icons.school_outlined;
      case 'travel':
        return Icons.flight_outlined;
      case 'personal':
      default:
        return Icons.person_outline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'work':
        return Colors.blue;
      case 'health':
        return Colors.red;
      case 'fitness':
        return Colors.green;
      case 'social':
        return Colors.purple;
      case 'education':
        return Colors.orange;
      case 'travel':
        return Colors.teal;
      case 'personal':
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  List<EventData> _getMockEvents() => [
        EventData(
          title: 'Team Meeting',
          time: '2:00 PM - 3:00 PM',
          date: 'Today',
          location: 'Conference Room A',
          attendees: 5,
          color: Theme.of(context).colorScheme.primary,
          category: 'Work',
          icon: Icons.work_outline,
        ),
        EventData(
          title: 'Doctor Appointment',
          time: '4:30 PM - 5:00 PM',
          date: 'Today',
          location: 'City Hospital',
          attendees: 2,
          color: Theme.of(context).colorScheme.secondary,
          category: 'Health',
          icon: Icons.health_and_safety_outlined,
        ),
        EventData(
          title: 'Gym Session',
          time: '7:00 PM - 8:30 PM',
          date: 'Today',
          location: 'Fitness Center',
          attendees: 1,
          color: Theme.of(context).colorScheme.tertiary,
          category: 'Fitness',
          icon: Icons.fitness_center_outlined,
        ),
        EventData(
          title: 'Project Review',
          time: '10:00 AM - 11:00 AM',
          date: 'Tomorrow',
          location: 'Online',
          attendees: 8,
          color: Theme.of(context).colorScheme.primary,
          category: 'Work',
          icon: Icons.work_outline,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Upcoming Events',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isLoading)
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _isLoading ? null : _loadEvents,
                        child: const Text('Refresh'),
                      ),
                      TextButton(
                        onPressed: _viewAllEvents,
                        child: const Text('View All'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              height: 200,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_events.isEmpty)
            const SizedBox(
              height: 200,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.event_available, size: 48, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No upcoming events',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _events.length,
                    itemBuilder: (context, index) {
                      return _buildEventCard(_events[index], index);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _events.length,
                    (index) => Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventData event, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        // use a lighter elevation for M3 feel and theme shadow
        elevation: 1,
        shadowColor: Theme.of(context).shadowColor.withOpacity(0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            // match other cards (calendar) by using colorScheme.outline
            color: Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [
                event.color.withOpacity(0.05),
                event.color.withOpacity(0.02),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      event.icon,
                      size: 16,
                      color: event.color,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: event.color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      event.category,
                      style: TextStyle(
                        color: event.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.date} • ${event.time}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.attendees}',
                          style: TextStyle(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () => _viewEventDetails(event),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 0),
                      side: BorderSide(
                        color: event.color.withOpacity(0.15),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'View',
                      style: TextStyle(
                        color: event.color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _viewAllEvents() {
    // Navigate to all events screen like recent summaries
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AllEventsScreen(events: _events),
      ),
    );
  }

  void _viewEventDetails(EventData event) {
    // Show event details
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(event.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Time: ${event.date} • ${event.time}'),
            const SizedBox(height: 8),
            Text('Location: ${event.location}'),
            const SizedBox(height: 8),
            Text('Attendees: ${event.attendees}'),
            const SizedBox(height: 8),
            Text('Category: ${event.category}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class EventData {
  final String title;
  final String time;
  final String date;
  final String location;
  final int attendees;
  final Color color;
  final String category;
  final IconData icon;

  EventData({
    required this.title,
    required this.time,
    required this.date,
    required this.location,
    required this.attendees,
    required this.color,
    required this.category,
    required this.icon,
  });
}
