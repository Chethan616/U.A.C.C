import 'package:flutter/material.dart';
import '../services/gemini_speech_service.dart';

class TaskCard extends StatelessWidget {
  final GeminiTask task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;

  const TaskCard({
    Key? key,
    required this.task,
    this.onTap,
    this.onComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final hasDeadline = task.dueDate != null;
    final isOverdue = hasDeadline && task.dueDate!.isBefore(DateTime.now());
    final isDueSoon = hasDeadline &&
        task.dueDate!.isAfter(DateTime.now()) &&
        task.dueDate!.difference(DateTime.now()).inDays <= 1;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Task icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getTaskColor(isOverdue, isDueSoon).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  Icons.task_alt,
                  color: _getTaskColor(isOverdue, isDueSoon),
                  size: 20,
                ),
              ),

              const SizedBox(width: 16),

              // Task content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (hasDeadline) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: _getTaskColor(isOverdue, isDueSoon),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDueDate(task.dueDate!),
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTaskColor(isOverdue, isDueSoon),
                              fontWeight: isOverdue || isDueSoon
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action button
              if (onComplete != null)
                IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  onPressed: onComplete,
                  tooltip: 'Mark as complete',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getTaskColor(bool isOverdue, bool isDueSoon) {
    if (isOverdue) return Colors.red;
    if (isDueSoon) return Colors.orange;
    return Colors.blue;
  }

  String _formatDueDate(DateTime dueDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(dueDate.year, dueDate.month, dueDate.day);

    final daysDifference = taskDate.difference(today).inDays;

    if (daysDifference == 0) {
      return 'Due today';
    } else if (daysDifference == 1) {
      return 'Due tomorrow';
    } else if (daysDifference == -1) {
      return 'Due yesterday';
    } else if (daysDifference < 0) {
      return 'Overdue by ${-daysDifference} day${-daysDifference == 1 ? '' : 's'}';
    } else if (daysDifference <= 7) {
      return 'Due in $daysDifference day${daysDifference == 1 ? '' : 's'}';
    } else {
      return 'Due ${dueDate.day}/${dueDate.month}/${dueDate.year}';
    }
  }
}

/// Simple task card variant for display-only use cases
class SimpleTaskCard extends StatelessWidget {
  final String title;
  final DateTime? dueDate;
  final bool completed;
  final VoidCallback? onTap;

  const SimpleTaskCard({
    Key? key,
    required this.title,
    this.dueDate,
    this.completed = false,
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
              Icon(
                completed ? Icons.check_circle : Icons.radio_button_unchecked,
                color: completed ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        color: completed ? Colors.grey : null,
                      ),
                    ),
                    if (dueDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Due: ${dueDate!.day}/${dueDate!.month}/${dueDate!.year}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
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
