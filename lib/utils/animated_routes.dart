import 'package:flutter/material.dart';
import 'package:animations/animations.dart';

enum TransitionType {
  sharedAxis,
  fadeThrough,
  fade,
  slide,
}

class AnimatedRoutes {
  static Route<T> createRoute<T>(
    Widget page, {
    TransitionType type = TransitionType.sharedAxis,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
    Duration duration = const Duration(milliseconds: 300),
  }) {
    switch (type) {
      case TransitionType.sharedAxis:
        return PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SharedAxisTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              transitionType: axis,
              child: child,
            );
          },
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );

      case TransitionType.fadeThrough:
        return PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeThroughTransition(
              animation: animation,
              secondaryAnimation: secondaryAnimation,
              child: child,
            );
          },
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );

      case TransitionType.fade:
        return PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );

      case TransitionType.slide:
        return PageRouteBuilder<T>(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeInOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: duration,
          reverseTransitionDuration: duration,
        );
    }
  }

  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubic;

        var tween = Tween(begin: begin, end: end).chain(
          CurveTween(curve: curve),
        );

        return SlideTransition(
          position: animation.drive(tween),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> scaleFromCenter<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return ScaleTransition(
          scale: Tween<double>(
            begin: 0.0,
            end: 1.0,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.elasticOut,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 600),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<T> containerTransform<T>(Widget page, {Color? backgroundColor}) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeThroughTransition(
          animation: animation,
          secondaryAnimation: secondaryAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
      opaque: true,
      barrierColor: backgroundColor ?? Colors.black26,
    );
  }
}

// Enhanced Navigator extension for easier usage
extension AnimatedNavigator on NavigatorState {
  Future<T?> pushAnimated<T>(
    Widget page, {
    TransitionType type = TransitionType.sharedAxis,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
    Duration? duration,
  }) {
    return push<T>(
      AnimatedRoutes.createRoute<T>(
        page,
        type: type,
        axis: axis,
        duration: duration ?? const Duration(milliseconds: 300),
      ),
    );
  }

  Future<T?> pushReplacementAnimated<T, TO>(
    Widget page, {
    TransitionType type = TransitionType.sharedAxis,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      AnimatedRoutes.createRoute<T>(page, type: type, axis: axis),
      result: result,
    );
  }

  Future<T?> pushSlideFromBottom<T>(Widget page) {
    return push<T>(AnimatedRoutes.slideFromBottom<T>(page));
  }

  Future<T?> pushScaleFromCenter<T>(Widget page) {
    return push<T>(AnimatedRoutes.scaleFromCenter<T>(page));
  }
}

// Context extension for easier usage
extension AnimatedContext on BuildContext {
  Future<T?> pushAnimated<T>(
    Widget page, {
    TransitionType type = TransitionType.sharedAxis,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
    Duration? duration,
  }) {
    return Navigator.of(this).pushAnimated<T>(
      page,
      type: type,
      axis: axis,
      duration: duration,
    );
  }

  Future<T?> pushReplacementAnimated<T, TO>(
    Widget page, {
    TransitionType type = TransitionType.sharedAxis,
    SharedAxisTransitionType axis = SharedAxisTransitionType.horizontal,
    TO? result,
  }) {
    return Navigator.of(this).pushReplacementAnimated<T, TO>(
      page,
      type: type,
      axis: axis,
      result: result,
    );
  }

  Future<T?> pushSlideFromBottom<T>(Widget page) {
    return Navigator.of(this).pushSlideFromBottom<T>(page);
  }

  Future<T?> pushScaleFromCenter<T>(Widget page) {
    return Navigator.of(this).pushScaleFromCenter<T>(page);
  }
}
