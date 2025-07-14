import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../models/stroke.dart';

class DrawingPainter extends CustomPainter {
  final ui.Image? backgroundImage;
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  DrawingPainter({
    required this.backgroundImage,
    required this.strokes,
    required this.currentStroke,
    super.repaint,
  });

  void _drawStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.points;
    final baseColor = stroke.color;
    final strokeWidth = stroke.strokeWidth;

    final paint = Paint()
      ..color = baseColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (points.length == 1) {
      final p = points[0];
      // Draw a very short line segment to simulate a dot
      canvas.drawLine(p, p.translate(0.01, 0.01), paint);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (backgroundImage != null) {
      paintImage(
        canvas: canvas,
        rect: Offset.zero & size,
        image: backgroundImage!,
        fit: BoxFit.contain,
      );
    }

    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
