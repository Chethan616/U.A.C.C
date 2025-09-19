import 'package:flutter/material.dart';

/// Material 3 Expressive Design Icons with enhanced visual appeal
/// These use the new M3 expressive iconography principles with rounded forms,
/// increased visual weight, and softer aesthetics
class ExpressiveIcons {
  // Phone icon with Material 3 expressive design
  static Widget phone({
    double size = 24.0,
    Color? color,
    bool filled = false,
  }) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ExpressivePhonePainter(
          color: color ?? Colors.black,
          filled: filled,
        ),
      ),
    );
  }

  // Notification bell with Material 3 expressive design
  static Widget notifications({
    double size = 24.0,
    Color? color,
    bool filled = false,
    bool hasIndicator = false,
  }) {
    return Container(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            painter: _ExpressiveNotificationPainter(
              color: color ?? Colors.black,
              filled: filled,
            ),
          ),
          if (hasIndicator)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: size * 0.25,
                height: size * 0.25,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Tasks/checklist icon with Material 3 expressive design
  static Widget tasks({
    double size = 24.0,
    Color? color,
    bool filled = false,
  }) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ExpressiveTasksPainter(
          color: color ?? Colors.black,
          filled: filled,
        ),
      ),
    );
  }

  // Dashboard/home icon with Material 3 expressive design
  static Widget dashboard({
    double size = 24.0,
    Color? color,
    bool filled = false,
  }) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ExpressiveDashboardPainter(
          color: color ?? Colors.black,
          filled: filled,
        ),
      ),
    );
  }

  // Profile/person icon with Material 3 expressive design
  static Widget person({
    double size = 24.0,
    Color? color,
    bool filled = false,
  }) {
    return Container(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ExpressivePersonPainter(
          color: color ?? Colors.black,
          filled: filled,
        ),
      ),
    );
  }
}

// Custom painter for expressive phone icon
class _ExpressivePhonePainter extends CustomPainter {
  final Color color;
  final bool filled;

  _ExpressivePhonePainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Create a more expressive phone shape with rounded corners
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.2,
        size.width * 0.1,
        size.width * 0.6,
        size.height * 0.8,
      ),
      Radius.circular(size.width * 0.12),
    );

    path.addRRect(rect);

    if (filled) {
      canvas.drawPath(path, paint);

      // Add speaker and home button details
      final speakerPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.5, size.height * 0.25),
            width: size.width * 0.3,
            height: size.height * 0.06,
          ),
          Radius.circular(size.width * 0.03),
        ),
        speakerPaint,
      );

      canvas.drawCircle(
        Offset(size.width * 0.5, size.height * 0.8),
        size.width * 0.06,
        speakerPaint,
      );
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for expressive notification icon
class _ExpressiveNotificationPainter extends CustomPainter {
  final Color color;
  final bool filled;

  _ExpressiveNotificationPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();

    // Bell body with expressive curves
    final bellCenter = Offset(size.width * 0.5, size.height * 0.45);
    final bellRadius = size.width * 0.35;

    // Create a bell shape with smoother curves
    path.moveTo(bellCenter.dx - bellRadius, bellCenter.dy + bellRadius * 0.3);
    path.quadraticBezierTo(
      bellCenter.dx - bellRadius * 1.2,
      bellCenter.dy - bellRadius * 0.5,
      bellCenter.dx,
      bellCenter.dy - bellRadius * 0.8,
    );
    path.quadraticBezierTo(
      bellCenter.dx + bellRadius * 1.2,
      bellCenter.dy - bellRadius * 0.5,
      bellCenter.dx + bellRadius,
      bellCenter.dy + bellRadius * 0.3,
    );

    // Bell bottom
    path.lineTo(bellCenter.dx - bellRadius, bellCenter.dy + bellRadius * 0.3);

    if (filled) {
      canvas.drawPath(path, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    // Bell clapper (small circle at bottom)
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.8),
      size.width * 0.08,
      paint,
    );

    // Top attachment
    canvas.drawLine(
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.5, size.height * 0.25),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for expressive tasks icon
class _ExpressiveTasksPainter extends CustomPainter {
  final Color color;
  final bool filled;

  _ExpressiveTasksPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Clipboard background with rounded corners
    final clipboardRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.15,
        size.width * 0.1,
        size.width * 0.7,
        size.height * 0.8,
      ),
      Radius.circular(size.width * 0.08),
    );

    if (filled) {
      canvas.drawRRect(clipboardRect, paint);
    } else {
      canvas.drawRRect(clipboardRect, paint);
    }

    // Clipboard clip at top
    final clipPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(size.width * 0.5, size.height * 0.12),
          width: size.width * 0.25,
          height: size.height * 0.08,
        ),
        Radius.circular(size.width * 0.03),
      ),
      clipPaint,
    );

    // Checkboxes and lines
    final checkPaint = Paint()
      ..color = filled ? Colors.white.withOpacity(0.9) : color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Three task items
    for (int i = 0; i < 3; i++) {
      final y = size.height * (0.3 + i * 0.15);

      // Checkbox
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(size.width * 0.25, y),
            width: size.width * 0.08,
            height: size.width * 0.08,
          ),
          Radius.circular(size.width * 0.02),
        ),
        checkPaint,
      );

      // Task line
      canvas.drawLine(
        Offset(size.width * 0.35, y),
        Offset(size.width * 0.75, y),
        checkPaint,
      );

      // Checkmark in first box
      if (i == 0) {
        final checkPath = Path();
        checkPath.moveTo(size.width * 0.22, y);
        checkPath.lineTo(size.width * 0.245, y + size.width * 0.02);
        checkPath.lineTo(size.width * 0.28, y - size.width * 0.02);
        canvas.drawPath(checkPath, checkPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for expressive dashboard icon
class _ExpressiveDashboardPainter extends CustomPainter {
  final Color color;
  final bool filled;

  _ExpressiveDashboardPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Four rounded rectangles in a grid
    final cardSpacing = size.width * 0.08;
    final cardWidth = (size.width - cardSpacing * 3) / 2;
    final cardHeight = (size.height - cardSpacing * 3) / 2;
    final radius = cardWidth * 0.15;

    // Top left card
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cardSpacing, cardSpacing, cardWidth, cardHeight),
        Radius.circular(radius),
      ),
      paint,
    );

    // Top right card
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cardSpacing * 2 + cardWidth,
          cardSpacing,
          cardWidth,
          cardHeight,
        ),
        Radius.circular(radius),
      ),
      paint,
    );

    // Bottom left card
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cardSpacing,
          cardSpacing * 2 + cardHeight,
          cardWidth,
          cardHeight,
        ),
        Radius.circular(radius),
      ),
      paint,
    );

    // Bottom right card
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cardSpacing * 2 + cardWidth,
          cardSpacing * 2 + cardHeight,
          cardWidth,
          cardHeight,
        ),
        Radius.circular(radius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for expressive person icon
class _ExpressivePersonPainter extends CustomPainter {
  final Color color;
  final bool filled;

  _ExpressivePersonPainter({required this.color, required this.filled});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Head (circle)
    final headCenter = Offset(size.width * 0.5, size.height * 0.3);
    final headRadius = size.width * 0.2;

    canvas.drawCircle(headCenter, headRadius, paint);

    // Body (rounded rectangle/oval)
    final bodyPath = Path();
    final bodyTop = size.height * 0.55;
    final bodyBottom = size.height * 0.9;
    final bodyWidth = size.width * 0.5;
    final bodyCenter = size.width * 0.5;

    bodyPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(bodyCenter, (bodyTop + bodyBottom) / 2),
          width: bodyWidth,
          height: bodyBottom - bodyTop,
        ),
        Radius.circular(bodyWidth * 0.4),
      ),
    );

    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
