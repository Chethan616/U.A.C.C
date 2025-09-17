import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/enums.dart';

class PriorityBadge extends StatelessWidget {
  final PriorityLevel priority;
  final String? customText;

  const PriorityBadge({
    Key? key,
    required this.priority,
    this.customText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: config.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config.icon,
            size: 12,
            color: config.color,
          ),
          const SizedBox(width: 4),
          Text(
            customText ?? config.text,
            style: TextStyle(
              color: config.color,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _PriorityConfig _getPriorityConfig(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.urgent:
        return _PriorityConfig(
          color: Colors.red.shade700,
          text: 'Urgent',
          icon: Icons.warning,
        );
      case PriorityLevel.high:
        return _PriorityConfig(
          color: Colors.orange.shade700,
          text: 'High',
          icon: Icons.priority_high,
        );
      case PriorityLevel.medium:
        return _PriorityConfig(
          color: AppColors.accent,
          text: 'Medium',
          icon: Icons.circle,
        );
      case PriorityLevel.low:
        return _PriorityConfig(
          color: AppColors.success,
          text: 'Low',
          icon: Icons.remove,
        );
    }
  }
}

class _PriorityConfig {
  final Color color;
  final String text;
  final IconData icon;

  _PriorityConfig({
    required this.color,
    required this.text,
    required this.icon,
  });
}
