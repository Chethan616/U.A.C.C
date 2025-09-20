import 'package:flutter/material.dart';
import '../services/gemini_speech_service.dart';

class EventCard extends StatelessWidget {
  final GeminiEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCalendar;

  const EventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.onAddToCalendar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasStartTime = event.startTime != null;
    final hasEndTime = event.endTime != null;
    final isToday = hasStartTime && _isToday(event.startTime!);
    final isPast = hasStartTime && event.startTime!.isBefore(DateTime.now());

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Event icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getEventColor(isToday, isPast).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.event,
                  color: _getEventColor(isToday, isPast),
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // Event content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isPast ? Colors.grey : null,
                        decoration: isPast ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    if (hasStartTime || hasEndTime) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: _getEventColor(isToday, isPast),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatEventTime(event.startTime, event.endTime),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getEventColor(isToday, isPast),
                              fontWeight:
                                  isToday ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (event.description != null &&
                        event.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        event.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Action button
              if (onAddToCalendar != null && !isPast)
                IconButton(
                  icon: const Icon(Icons.add_to_photos),
                  onPressed: onAddToCalendar,
                  tooltip: 'Add to calendar',
                ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  Color _getEventColor(bool isToday, bool isPast) {
    if (isPast) return Colors.grey;
    if (isToday) return Colors.red;
    return Colors.blue;
  }

  String _formatEventTime(DateTime? startTime, DateTime? endTime) {
    if (startTime == null && endTime == null) {
      return 'No time specified';
    }

    if (startTime != null && endTime != null) {
      final startStr = _formatTime(startTime);
      final endStr = _formatTime(endTime);

      if (_isSameDay(startTime, endTime)) {
        return '$startStr - $endStr';
      } else {
        return '${_formatDateTime(startTime)} - ${_formatDateTime(endTime)}';
      }
    }

    if (startTime != null) {
      return 'From ${_formatDateTime(startTime)}';
    }

    if (endTime != null) {
      return 'Until ${_formatDateTime(endTime)}';
    }

    return '';
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final eventDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final daysDifference = eventDate.difference(today).inDays;

    if (daysDifference == 0) {
      return 'Today ${_formatTime(dateTime)}';
    } else if (daysDifference == 1) {
      return 'Tomorrow ${_formatTime(dateTime)}';
    } else if (daysDifference == -1) {
      return 'Yesterday ${_formatTime(dateTime)}';
    } else if (daysDifference > 0 && daysDifference <= 7) {
      final weekday = _getWeekdayName(dateTime.weekday);
      return '$weekday ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${_formatTime(dateTime)}';
    }
  }

  String _getWeekdayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Unknown';
    }
  }
}

/// Simple event card variant for display-only use cases
class SimpleEventCard extends StatelessWidget {
  final String title;
  final DateTime? startTime;
  final DateTime? endTime;
  final String? description;
  final VoidCallback? onTap;

  const SimpleEventCard({
    Key? key,
    required this.title,
    this.startTime,
    this.endTime,
    this.description,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(
                Icons.event,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (startTime != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${startTime!.day}/${startTime!.month}/${startTime!.year} at ${startTime!.hour.toString().padLeft(2, '0')}:${startTime!.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
