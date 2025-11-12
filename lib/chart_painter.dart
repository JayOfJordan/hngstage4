import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class LineChartPainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final bool isDetailed;

  LineChartPainter({
    required this.data,
    required this.color,
    this.isDetailed = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final double minVal = data.reduce((a, b) => a < b ? a : b);
    final double maxVal = data.reduce((a, b) => a > b ? a : b);
    final double range = maxVal - minVal;

    final Path path = Path();
    final int pointsToDraw = data.length;

    for (int i = 0; i < pointsToDraw; i++) {
      final double x = (i / (data.length - 1)) * size.width;
      final double y = size.height - ((data[i] - minVal) / (range.abs() > 0 ? range : 1)) * size.height;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = isDetailed ? 2.5 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    if (isDetailed) {
      final Paint fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          Offset(0, 0),
          Offset(0, size.height),
          [color.withOpacity(0.3), color.withOpacity(0.0)],
        )
        ..style = PaintingStyle.fill;

      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();
      canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.color != color;
  }
}
