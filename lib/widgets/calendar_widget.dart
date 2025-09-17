// lib/widgets/calendar_widget.dart
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget({Key? key}) : super(key: key);

  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  DateTime selectedDate = DateTime.now();
  DateTime currentMonth = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.outline,
            width: 1.0,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Calendar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    onPressed: () => _showFullCalendar(context),
                    icon: const Icon(Icons.calendar_month,
                        color: AppColors.primary),
                  ),
                ],
              ),
              //const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getMonthYear(currentMonth),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _previousMonth,
                        icon: const Icon(Icons.chevron_left, size: 20),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: const Icon(Icons.chevron_right, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
              //const SizedBox(height: 8),
              _buildMiniCalendar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniCalendar() {
    final daysInMonth =
        DateTime(currentMonth.year, currentMonth.month + 1, 0).day;
    final firstWeekday =
        DateTime(currentMonth.year, currentMonth.month, 1).weekday;

    return Column(
      children: [
        // Week days header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((day) => SizedBox(
                    width: 30,
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ))
              .toList(),
        ),
        //const SizedBox(height: 8),
        // Calendar grid
        Wrap(
          children: List.generate(42, (index) {
            final day = index - firstWeekday + 2;
            final isCurrentMonth = day > 0 && day <= daysInMonth;
            final isSelected = isCurrentMonth &&
                selectedDate.day == day &&
                selectedDate.month == currentMonth.month &&
                selectedDate.year == currentMonth.year;
            final isToday = isCurrentMonth &&
                DateTime.now().day == day &&
                DateTime.now().month == currentMonth.month &&
                DateTime.now().year == currentMonth.year;

            return GestureDetector(
              onTap: isCurrentMonth
                  ? () => setState(() {
                        selectedDate = DateTime(
                            currentMonth.year, currentMonth.month, day);
                      })
                  : null,
              child: Container(
                width: 35,
                height: 25,
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : isToday
                          ? AppColors.accent
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    isCurrentMonth ? day.toString() : '',
                    style: TextStyle(
                      color: isSelected || isToday
                          ? AppColors.text
                          : isCurrentMonth
                              ? AppColors.text
                              : AppColors.muted,
                      fontWeight: isSelected || isToday
                          ? FontWeight.bold
                          : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _previousMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      currentMonth = DateTime(currentMonth.year, currentMonth.month + 1, 1);
    });
  }

  String _getMonthYear(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  void _showFullCalendar(BuildContext context) {
    // Navigate to full calendar view
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Full Calendar'),
        content: const Text('Full calendar view coming soon!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
