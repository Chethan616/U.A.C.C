// lib/widgets/upcoming_events_carousel.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

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

  final List<EventData> _events = [
    EventData(
      title: 'Team Meeting',
      time: '2:00 PM - 3:00 PM',
      date: 'Today',
      location: 'Conference Room A',
      attendees: 5,
      color: AppColors.primary,
      category: 'Work',
    ),
    EventData(
      title: 'Doctor Appointment',
      time: '4:30 PM - 5:00 PM',
      date: 'Today',
      location: 'City Hospital',
      attendees: 2,
      color: AppColors.accent,
      category: 'Health',
    ),
    EventData(
      title: 'Gym Session',
      time: '7:00 PM - 8:30 PM',
      date: 'Today',
      location: 'Fitness Center',
      attendees: 1,
      color: AppColors.success,
      category: 'Health',
    ),
    EventData(
      title: 'Project Review',
      time: '10:00 AM - 11:00 AM',
      date: 'Tomorrow',
      location: 'Online',
      attendees: 8,
      color: AppColors.primary,
      category: 'Work',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming Events',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton(
                  onPressed: _viewAllEvents,
                  child: const Text('View All'),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
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
                  color: AppColors.primary.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(EventData event, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 4,
        shadowColor: AppColors.shadow.withOpacity(0.15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
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
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: event.color,
                      shape: BoxShape.circle,
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${event.date} • ${event.time}',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 16,
                    color: AppColors.muted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      event.location,
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: AppColors.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${event.attendees}',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => _viewEventDetails(event),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: event.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
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
    // Navigate to all events screen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Events'),
        content: const Text('Full events view coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
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

  EventData({
    required this.title,
    required this.time,
    required this.date,
    required this.location,
    required this.attendees,
    required this.color,
    required this.category,
  });
}
