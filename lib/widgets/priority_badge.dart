import 'package:flutter/material.dart';
// Theme colors are read from Theme.of(context) to respect selected Material 3 themes
import '../models/enums.dart';

class PriorityBadge extends StatefulWidget {
  final PriorityLevel priority;
  final String? customText;
  final bool animate;

  const PriorityBadge({
    Key? key,
    required this.priority,
    this.customText,
    this.animate = true,
  }) : super(key: key);

  @override
  State<PriorityBadge> createState() => _PriorityBadgeState();
}

class _PriorityBadgeState extends State<PriorityBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeInOut),
    ));

    if (widget.animate) {
      _controller.forward();

      // Add pulsing effect for urgent priority
      if (widget.priority == PriorityLevel.urgent) {
        _controller.repeat(reverse: true);
      }
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig(widget.priority);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value *
              (widget.priority == PriorityLevel.urgent
                  ? _pulseAnimation.value
                  : 1.0),
          child: TweenAnimationBuilder<Color?>(
            tween: ColorTween(
              begin: config.color.withOpacity(0.0),
              end: config.color,
            ),
            duration: const Duration(milliseconds: 800),
            builder: (context, animatedColor, child) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (animatedColor ?? config.color).withOpacity(0.15),
                      (animatedColor ?? config.color).withOpacity(0.08),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: (animatedColor ?? config.color).withOpacity(0.4),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (animatedColor ?? config.color).withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.elasticOut,
                      builder: (context, iconValue, child) {
                        return Transform.rotate(
                          angle: iconValue * 2 * 3.14159,
                          child: Icon(
                            config.icon,
                            size: 14,
                            color: animatedColor ?? config.color,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 400),
                      style: TextStyle(
                        color: animatedColor ?? config.color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      child: Text(widget.customText ?? config.text),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  _PriorityConfig _getPriorityConfig(PriorityLevel priority) {
    final colors = Theme.of(context).colorScheme;

    switch (priority) {
      case PriorityLevel.urgent:
        return _PriorityConfig(
          color: colors.error, // use theme error for urgent
          text: 'URGENT',
          icon: Icons.warning_rounded,
        );
      case PriorityLevel.high:
        return _PriorityConfig(
          color: colors.primary, // high priority uses primary accent
          text: 'HIGH',
          icon: Icons.priority_high_rounded,
        );
      case PriorityLevel.medium:
        return _PriorityConfig(
          color: colors.secondary, // medium uses secondary/accent
          text: 'MEDIUM',
          icon: Icons.circle_rounded,
        );
      case PriorityLevel.low:
        return _PriorityConfig(
          color: colors.tertiary, // use tertiary from color scheme
          text: 'LOW',
          icon: Icons.check_circle_rounded,
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
