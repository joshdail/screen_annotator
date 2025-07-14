import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';

import '../models/stroke.dart';
import '../intents.dart';
import '../widgets/drawing_canvas.dart';
import '../services/screenshot_service.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _currentStroke;
  final GlobalKey _canvasKey = GlobalKey();

  final ValueNotifier<int> _repaintNotifier = ValueNotifier<int>(0);
  Color _selectedColor = Colors.blue;
  double _strokeWidth = 4.0;

  final FocusNode _focusNode = FocusNode();
  Timer? _repaintDebounceTimer;

  // New fields to hold background image and path
  ui.Image? _backgroundImage;
  String? _backgroundImagePath;

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
      _backgroundImage = null; // Clear background image too
      _backgroundImagePath = null;
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
    _backgroundImage?.dispose();
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
            IconButton(
              tooltip: 'Export as PNG',
              icon: const Icon(Icons.download),
              onPressed: _exportCanvasToImage,
            ),
            IconButton(
              tooltip: 'Capture Screenshot',
              icon: const Icon(Icons.camera_alt),
              onPressed: _captureAndDisplayScreenshot,
            ),
          ],
        ),
        body: DrawingCanvas(
          backgroundImage: _backgroundImage,
          strokes: _strokes,
          currentStroke: _currentStroke,
          onStartStroke: _startStroke,
          onDraw: _addPoint,
          onEndStroke: _endStroke,
          repaintNotifier: _repaintNotifier,
          repaintKey: _canvasKey,
        ),
      ),
    );
  } // build

  Future<void> _exportCanvasToImage() async {
    try {
      final boundary =
          _canvasKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary == null) return;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return;

      final Uint8List pngBytes = byteData.buffer.asUint8List();

      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Save your drawing as PNG',
        fileName: 'Untitled.png',
        type: FileType.custom,
        allowedExtensions: ['png'],
      );

      if (path == null) return;

      final file = File(path);
      await file.writeAsBytes(pngBytes);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Saved to: $path')));
      }
    } catch (err) {
      debugPrint('Failed to export image: $err');
    }
  } // _exportCanvasToImage

  Future<ui.Image> _loadImageFromFile(String path) async {
    final data = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  void _captureAndDisplayScreenshot() async {
    final path = await ScreenshotService.captureScreenshot();
    if (path != null && context.mounted) {
      final image = await _loadImageFromFile(path);

      setState(() {
        _backgroundImage?.dispose();
        _backgroundImage = image;
        _backgroundImagePath = path;
      });

      // Delete the temporary screenshot file immediately after loading
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
          print('Temporary screenshot file deleted.');
        }
      } catch (e) {
        print('Failed to delete temp screenshot file: $e');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Screenshot loaded for annotation')),
      );
    }
  }
}
