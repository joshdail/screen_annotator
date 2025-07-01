import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import '../models/stroke.dart';
import '../intents.dart';
import '../widgets/drawing_canvas.dart';

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
        LogicalKeySet(LogicalKeyboardKey.meta, LogicalKeyboardKey.keyB):
            const StrokeWidthIntent(),
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
        LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyB):
            const StrokeWidthIntent(),
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
        StrokeWidthIntent: CallbackAction<StrokeWidthIntent>(
          onInvoke: (_) => _openStrokeWidthDialog(),
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
              tooltip: 'Select Stroke Width (⌘B)',
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
