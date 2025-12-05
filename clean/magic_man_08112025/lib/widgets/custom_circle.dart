import 'dart:math' as math;

import 'package:flutter/material.dart';

class PercentageColorCircle extends StatelessWidget {
  final double size;
  final Color color;
  final int percent;
  final bool isSmall;

  const PercentageColorCircle({
    Key? key,
    required this.size,
    required this.color,
    required this.percent,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _PercentageColorCirclePainter(
          color: color, percent: percent, isSmall: isSmall),
    );
  }
}

class _PercentageColorCirclePainter extends CustomPainter {
  final Color color;
  final int percent;
  final bool isSmall;

  _PercentageColorCirclePainter(
      {required this.color, required this.percent, required this.isSmall});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * (isSmall ? 0.2 : 0.1); // 10% of radius
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = (percent / 100) * 2 * math.pi;
    const startAngle = -math.pi;
    final endAngle = startAngle + sweepAngle;

    final path = Path()
      ..addArc(
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
        startAngle,
        sweepAngle,
      );

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PercentageColorCirclePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.percent != percent;
}
