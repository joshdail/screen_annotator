import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Drawing Canvas',
      home: DrawingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// A stroke contains a list of points and a color
class Stroke {
  final List<Offset> points;
  final Color color;

  Stroke({required this.points, required this.color});
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<Stroke> _strokes = [];
  Stroke? _currentStroke;

  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  Color _selectedColor = Colors.blue;

  void _startStroke(Offset point) {
    setState(() {
      _currentStroke = Stroke(points: [point], color: _selectedColor);
    });
    _incrementRepaintNotifier();
  }

  void _addPoint(Offset point) {
    _currentStroke?.points.add(point);
    _incrementRepaintNotifier();
  }

  void _endStroke() {
    if (_currentStroke != null) {
      setState(() {
        _strokes.add(_currentStroke!);
        _currentStroke = null;
      });
    }
    _incrementRepaintNotifier();
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _currentStroke = null;
    });
    _incrementRepaintNotifier();
  }

  void _incrementRepaintNotifier() {
    _repaintNotifier.value++;
  }

  void _openColorPicker() {
    Color pickerColor = _selectedColor;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickerColor,
            onColorChanged: (color) => pickerColor = color,
            enableAlpha: false,
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Select'),
            onPressed: () {
              setState(() => _selectedColor = pickerColor);
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Toolbar
          Container(
            color: Colors.grey[200],
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _openColorPicker,
                  icon: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black),
                    ),
                  ),
                  label: const Text("Select Color"),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: _clearCanvas,
                  icon: const Icon(Icons.clear),
                  label: const Text("Clear"),
                ),
              ],
            ),
          ),

          // Drawing Canvas
          Expanded(
            child: DrawingCanvas(
              strokes: _strokes,
              currentStroke: _currentStroke,
              onStartStroke: _startStroke,
              onDraw: _addPoint,
              onEndStroke: _endStroke,
              repaintNotifier: _repaintNotifier,
            ),
          ),
        ],
      ),
    );
  }
}

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

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    Listenable? repaint,
  }) : super(repaint: repaint);

  final Map<Color, Paint> _paintCache = {};

  Paint _getPaint(Color color) {
    return _paintCache.putIfAbsent(
      color,
      () => Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4.0,
    );
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    final points = stroke.points;
    final paint = _getPaint(stroke.color);
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], paint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke);
    }
    if (currentStroke != null) {
      _drawStroke(canvas, currentStroke!);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingPainter oldDelegate) => true;
}
