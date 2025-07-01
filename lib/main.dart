import 'package:flutter/material.dart';
import 'dart:ui' as ui;

void main() {
  runApp(const MyApp());
}

// Root of the app
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(title: 'Drawing Canvas', home: const DrawingPage());
  }
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  // Holds the current list of drawn points
  final List<Offset?> _points = [];

  void _addPoint(Offset point) => setState(() => _points.add(point));
  void _endStroke() => setState(() => _points.add(null));
  void _clearCanvas() => setState(() => _points.clear());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Draw Something")),
      body: Stack(
        children: [
          DrawingCanvas(
            points: _points,
            onDraw: _addPoint,
            onEndStroke: _endStroke,
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton.extended(
              onPressed: _clearCanvas,
              icon: const Icon(Icons.clear),
              label: const Text("Clear"),
            ),
          ),
        ],
      ),
    );
  }
}

class DrawingCanvas extends StatelessWidget {
  final List<Offset?> points;
  final ValueChanged<Offset> onDraw;
  final VoidCallback onEndStroke;

  const DrawingCanvas({
    super.key,
    required this.points,
    required this.onDraw,
    required this.onEndStroke,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) => onDraw(details.localPosition),
      onPanEnd: (_) => onEndStroke(),
      child: CustomPaint(
        painter: DrawingPainter(points: points),
        size: Size.infinite,
      ),
    );
  }
}

class DrawingPainter extends CustomPainter {
  final List<Offset?> points;

  DrawingPainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      if (p1 != null && p2 != null) {
        canvas.drawLine(p1, p2, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
