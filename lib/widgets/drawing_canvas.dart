import 'package:flutter/material.dart';

import '../models/stroke.dart';
import '../painters/drawing_painter.dart';

class DrawingCanvas extends StatelessWidget {
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final ValueChanged<Offset> onStartStroke;
  final ValueChanged<Offset> onDraw;
  final VoidCallback onEndStroke;
  final ValueNotifier<int> repaintNotifier;

  const DrawingCanvas({
    super.key,
    required this.strokes,
    required this.currentStroke,
    required this.onStartStroke,
    required this.onDraw,
    required this.onEndStroke,
    required this.repaintNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onStartStroke(details.localPosition),
      onPanUpdate: (details) => onDraw(details.localPosition),
      onPanEnd: (_) => onEndStroke(),
      child: CustomPaint(
        painter: DrawingPainter(
          strokes: strokes,
          currentStroke: currentStroke,
          repaint: repaintNotifier,
        ),
        size: Size.infinite,
      ),
    );
  }
}
