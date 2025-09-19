import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Performance-optimized animated transitions with 120fps support
class PerformantAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration ultra = Duration(milliseconds: 800);

  // Professional curves for smooth animations
  static const Curve easeOutCubic = Cubic(0.33, 1, 0.68, 1);
  static const Curve easeInOutCubic = Cubic(0.65, 0, 0.35, 1);
  static const Curve swiftOut = Cubic(0.4, 0.0, 0.2, 1.0);
  static const Curve swiftIn = Cubic(0.4, 0.0, 1.0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);

  /// Creates a staggered animation controller with optimized frame rate
  static AnimationController createStaggeredController({
    required TickerProvider vsync,
    Duration duration = medium,
  }) {
    return AnimationController(
      duration: duration,
      vsync: vsync,
    );
  }

  /// Creates smooth slide transition optimized for 120fps
  static Widget slideTransition({
    required Animation<double> animation,
    required Widget child,
    Offset begin = const Offset(0.0, 1.0),
    Offset end = Offset.zero,
    Curve curve = swiftOut,
  }) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: begin,
        end: end,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
      ),
      child: child,
    );
  }

  /// Creates smooth fade transition optimized for performance
  static Widget fadeTransition({
    required Animation<double> animation,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = swiftOut,
  }) {
    return FadeTransition(
      opacity: Tween<double>(
        begin: begin,
        end: end,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
      ),
      child: child,
    );
  }

  /// Creates smooth scale transition with professional feel
  static Widget scaleTransition({
    required Animation<double> animation,
    required Widget child,
    double begin = 0.0,
    double end = 1.0,
    Curve curve = emphasizedDecelerate,
    Alignment alignment = Alignment.center,
  }) {
    return ScaleTransition(
      scale: Tween<double>(
        begin: begin,
        end: end,
      ).animate(
        CurvedAnimation(
          parent: animation,
          curve: curve,
        ),
      ),
      alignment: alignment,
      child: child,
    );
  }

  /// Creates staggered list animations with optimized performance
  static Widget staggeredListItem({
    required int index,
    required Animation<double> animation,
    required Widget child,
    Duration staggerDelay = const Duration(milliseconds: 50),
  }) {
    final itemAnimation = CurvedAnimation(
      parent: animation,
      curve: Interval(
        (index * 0.1).clamp(0.0, 0.9),
        1.0,
        curve: emphasizedDecelerate,
      ),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.0, 0.5),
        end: Offset.zero,
      ).animate(itemAnimation),
      child: FadeTransition(
        opacity: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).animate(itemAnimation),
        child: child,
      ),
    );
  }

  /// Creates smooth rotating animation for loading indicators
  static Widget rotateTransition({
    required Animation<double> animation,
    required Widget child,
    double turns = 1.0,
  }) {
    return RotationTransition(
      turns: Tween<double>(
        begin: 0.0,
        end: turns,
      ).animate(animation),
      child: child,
    );
  }

  /// Professional shimmer effect for loading states
  static Widget shimmerTransition({
    required Animation<double> animation,
    required Widget child,
    Color baseColor = Colors.grey,
    Color highlightColor = Colors.white,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(-1.0, -0.3),
              end: Alignment(1.0, 0.3),
              colors: [
                baseColor,
                baseColor,
                highlightColor,
                baseColor,
                baseColor,
              ],
              stops: [
                0.0,
                0.35 + animation.value * 0.3,
                0.5 + animation.value * 0.3,
                0.65 + animation.value * 0.3,
                1.0,
              ],
            ),
          ),
          child: child,
        );
      },
      child: child,
    );
  }

  /// Creates smooth page transition for navigation
  static PageRouteBuilder createPageRoute({
    required Widget page,
    Duration duration = medium,
    PageTransitionType type = PageTransitionType.slide,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, _) => page,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        switch (type) {
          case PageTransitionType.slide:
            return slideTransition(
              animation: animation,
              child: child,
            );
          case PageTransitionType.fade:
            return fadeTransition(
              animation: animation,
              child: child,
            );
          case PageTransitionType.scale:
            return scaleTransition(
              animation: animation,
              child: child,
            );
          case PageTransitionType.rotation:
            return rotateTransition(
              animation: animation,
              child: child,
            );
        }
      },
    );
  }
}

enum PageTransitionType {
  slide,
  fade,
  scale,
  rotation,
}

/// Performance optimized container that reduces rebuilds
class PerformantContainer extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final Border? border;

  const PerformantContainer({
    super.key,
    required this.child,
    this.backgroundColor,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.borderRadius,
    this.boxShadow,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Container(
        width: width,
        height: height,
        padding: padding,
        margin: margin,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
          border: border,
        ),
        child: child,
      ),
    );
  }
}

/// Performance optimized animated widget base class
abstract class PerformantAnimatedWidget extends StatefulWidget {
  const PerformantAnimatedWidget({super.key});

  @override
  State<PerformantAnimatedWidget> createState() =>
      _PerformantAnimatedWidgetState();

  Widget buildAnimatedChild(BuildContext context, Animation<double> animation);
}

class _PerformantAnimatedWidgetState extends State<PerformantAnimatedWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: PerformantAnimations.medium,
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: PerformantAnimations.emphasizedDecelerate,
    );

    // Start animation on next frame
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return widget.buildAnimatedChild(context, _animation);
        },
      ),
    );
  }
}
