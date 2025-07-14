import 'package:flutter/material.dart';
import 'dart:ui' as ui;

import '../models/stroke.dart';
import '../painters/drawing_painter.dart';

class DrawingCanvas extends StatelessWidget {
  final ui.Image? backgroundImage;
  final List<Stroke> strokes;
  final Stroke? currentStroke;
  final ValueChanged<Offset> onStartStroke;
  final ValueChanged<Offset> onDraw;
  final VoidCallback onEndStroke;
  final ValueNotifier<int> repaintNotifier;
  final GlobalKey repaintKey;

  const DrawingCanvas({
    super.key,
    required this.backgroundImage,
    required this.strokes,
    required this.currentStroke,
    required this.onStartStroke,
    required this.onDraw,
    required this.onEndStroke,
    required this.repaintNotifier,
    required this.repaintKey,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => onStartStroke(details.localPosition),
      onPanUpdate: (details) => onDraw(details.localPosition),
      onPanEnd: (_) => onEndStroke(),
      child: RepaintBoundary(
        key: repaintKey,
        child: CustomPaint(
          painter: DrawingPainter(
            backgroundImage: backgroundImage,
            strokes: strokes,
            currentStroke: currentStroke,
            repaint: repaintNotifier,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}
