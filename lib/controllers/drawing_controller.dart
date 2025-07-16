import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:file_picker/file_picker.dart';

import '../models/stroke.dart';
import '../services/screenshot_service.dart';

class DrawingController {
  final List<Stroke> _strokes = [];
  final List<Stroke> _redoStack = [];
  Stroke? _currentStroke;

  final GlobalKey _canvasKey = GlobalKey();
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);

  Color _selectedColor = Colors.blue;
  double _strokeWidth = 4.0;

  ui.Image? _backgroundImage;
  String? _backgroundImagePath;

  List<Stroke> get strokes => _strokes;
  Stroke? get currentStroke => _currentStroke;
  GlobalKey get canvasKey => _canvasKey;
  ValueNotifier<int> get repaintNotifier => _repaintNotifier;
  ui.Image? get backgroundImage => _backgroundImage;

  void dispose() {
    _backgroundImage?.dispose();
  } // dispose

  void startStroke(Offset point) {
    _currentStroke = Stroke(
      points: [point],
      color: _selectedColor,
      strokeWidth: _strokeWidth,
    );
    _notifyRepaint();
  } // startStroke

  void addPoint(Offset point) {
    _currentStroke?.points.add(point);
    _notifyRepaint();
  } // addPoint

  void endStroke() {
    if (_currentStroke == null) {
      return;
    }
    _strokes.add(_currentStroke!);
    _redoStack.clear();
    _currentStroke = null;
    _notifyRepaint();
  } // endStroke

  void undo() {
    if (_strokes.isEmpty) {
      return;
    }
    _redoStack.add(_strokes.removeLast());
    _notifyRepaint();
  } // undo

  void redo() {
    if (_redoStack.isEmpty) {
      return;
    }
    _strokes.add(_redoStack.removeLast());
    _notifyRepaint();
  } // redo

  void clearCanvas() {
    _strokes.clear();
    _redoStack.clear();
    _currentStroke = null;
    _backgroundImage?.dispose();
    _backgroundImage = null;
    _backgroundImagePath = null;
    _notifyRepaint();
  } // clearCanvas

  void _notifyRepaint() {
    _repaintNotifier.value++;
  } // _notifyRepaint

  void openColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Select Color"),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: _selectedColor,
            onColorChanged: (color) => _selectedColor = color,
          ), // ColorPicker
        ), // SingleChildScrollView
      ), // AlertDialog
    );
  } // openColorPicker

  void openStrokeWidthDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        double temp = _strokeWidth;
        return AlertDialog(
          title: const Text("Select Brush Width"),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Slider(
                value: temp,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                label: temp.toStringAsFixed(1),
                onChanged: (v) => setState(() => temp = v),
              ); // Slider
            },
          ), // StatefulBuilder
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                _strokeWidth = temp;
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ), // ElevatedButton
          ], // actions
        ); // AlertDialog
      },
    );
  } // openStrokeWidthDialog

  Future<void> captureScreenshotAndDisplay(BuildContext context) async {
    final path = await ScreenshotService.captureScreenshot();
    if (path == null) {
      return;
    }
    _backgroundImage?.dispose();
    _backgroundImage = await _loadImageFromFile(path);
    _backgroundImagePath = path;
    _notifyRepaint();

    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (err) {
      debugPrint("Failed to delete temp screenshot file: $err");
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Screenshot loaded for annotation")),
      );
    }
  } // captureScreenshotAndDisplay

  Future<void> exportCanvasToImage(BuildContext context) async {
    final boundary =
        _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      return;
    }

    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      return;
    }

    final bytes = byteData.buffer.asUint8List();
    final path = await FilePicker.platform.saveFile(
      dialogTitle: "Save Drawing",
      fileName: "Untitled.png",
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (path == null) {
      return;
    }

    await File(path).writeAsBytes(bytes);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Saved to: $path")));
    }
  } // exportCanvasToImage

  Future<ui.Image> _loadImageFromFile(String path) async {
    final data = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(data);
    final frame = await codec.getNextFrame();
    return frame.image;
  } // _loadImageFromFile
}
