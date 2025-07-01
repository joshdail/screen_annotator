import 'dart:async'; // For Timer debounce

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: DrawingPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class Stroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;

  Stroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
  });
}

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _currentStroke;

  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  Color _selectedColor = Colors.blue;
  double _strokeWidth = 4.0;

  final FocusNode _focusNode = FocusNode();

  Timer? _repaintDebounceTimer;

  void _startStroke(Offset point) {
    setState(() {
      _currentStroke = Stroke(
        points: [point],
        color: _selectedColor,
        strokeWidth: _strokeWidth,
      );
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
        _redoStack.clear();
        _currentStroke = null;
      });
    }
    _incrementRepaintNotifier();
  }

  void _clearCanvas() {
    setState(() {
      _strokes.clear();
      _redoStack.clear();
      _currentStroke = null;
    });
    _incrementRepaintNotifier();
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() {
        _redoStack.add(_strokes.removeLast());
      });
      _incrementRepaintNotifier();
    }
  }

  void _redo() {
    if (_redoStack.isNotEmpty) {
      setState(() {
        _strokes.add(_redoStack.removeLast());
      });
      _incrementRepaintNotifier();
    }
  }

  void _incrementRepaintNotifier() {
    // Debounce repaint calls to ~60fps (every 16ms)
    if (_repaintDebounceTimer?.isActive ?? false) return;
    _repaintDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      _repaintNotifier.value++;
    });
  }

  void _openColorPicker() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) {
              setState(() => _selectedColor = color);
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _openStrokeWidthDialog() {
    showDialog(
      context: context,
      builder: (_) {
        double tempStrokeWidth = _strokeWidth;
        return AlertDialog(
          title: const Text("Select Stroke Width"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Slider(
                value: tempStrokeWidth,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                label: tempStrokeWidth.toStringAsFixed(1),
                onChanged: (value) {
                  setState(() {
                    tempStrokeWidth = value;
                  });
                },
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _strokeWidth = tempStrokeWidth;
                });
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _repaintDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: true,
      shortcuts: <LogicalKeySet, Intent>{
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.meta,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.backspace):
            const ClearIntent(),
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyK):
            const ColorPickerIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyZ):
            const UndoIntent(),
        LogicalKeySet(
          LogicalKeyboardKey.control,
          LogicalKeyboardKey.shift,
          LogicalKeyboardKey.keyZ,
        ): const RedoIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.backspace):
            const ClearIntent(),
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyK):
            const ColorPickerIntent(),
      },
      actions: <Type, Action<Intent>>{
        UndoIntent: CallbackAction<UndoIntent>(onInvoke: (_) => _undo()),
        RedoIntent: CallbackAction<RedoIntent>(onInvoke: (_) => _redo()),
        ClearIntent: CallbackAction<ClearIntent>(
          onInvoke: (_) => _clearCanvas(),
        ),
        ColorPickerIntent: CallbackAction<ColorPickerIntent>(
          onInvoke: (_) => _openColorPicker(),
        ),
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: CircleAvatar(radius: 12, backgroundColor: _selectedColor),
            ),
            IconButton(
              tooltip: 'Select Color (⌘K)',
              icon: const Icon(Icons.palette),
              onPressed: _openColorPicker,
            ),
            IconButton(
              tooltip: 'Select Stroke Width',
              icon: const Icon(Icons.brush),
              onPressed: _openStrokeWidthDialog,
            ),
            IconButton(
              tooltip: 'Undo (⌘Z)',
              icon: const Icon(Icons.undo),
              onPressed: _undo,
            ),
            IconButton(
              tooltip: 'Redo (⌘⇧Z)',
              icon: const Icon(Icons.redo),
              onPressed: _redo,
            ),
            IconButton(
              tooltip: 'Clear (⌘⌫)',
              icon: const Icon(Icons.clear),
              onPressed: _clearCanvas,
            ),
          ],
        ),
        body: DrawingCanvas(
          strokes: _strokes,
          currentStroke: _currentStroke,
          onStartStroke: _startStroke,
          onDraw: _addPoint,
          onEndStroke: _endStroke,
          repaintNotifier: _repaintNotifier,
        ),
      ),
    );
  }
}

// === Custom Intents ===

class UndoIntent extends Intent {
  const UndoIntent();
}

class RedoIntent extends Intent {
  const RedoIntent();
}

class ClearIntent extends Intent {
  const ClearIntent();
}

class ColorPickerIntent extends Intent {
  const ColorPickerIntent();
}

// === Canvas ===

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

// === Painter ===

class DrawingPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Stroke? currentStroke;

  DrawingPainter({
    required this.strokes,
    required this.currentStroke,
    Listenable? repaint,
  }) : super(repaint: repaint);

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
      canvas.drawLine(p, p.translate(0.01, 0.01), paint);
    } else {
      for (int i = 0; i < points.length - 1; i++) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
