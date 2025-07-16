import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/drawing_controller.dart';
import '../intents.dart';
import '../widgets/drawing_canvas.dart';
import '../widgets/drawing_toolbar.dart';

class DrawingPage extends StatefulWidget {
  const DrawingPage({super.key});

  @override
  State<DrawingPage> createState() => _DrawingPageState();
}

class _DrawingPageState extends State<DrawingPage> {
  final _controller = DrawingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      focusNode: _focusNode,
      autofocus: true,
      shortcuts: {
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
      actions: {
        UndoIntent: CallbackAction<UndoIntent>(
          onInvoke: (_) => _controller.undo(),
        ),
        RedoIntent: CallbackAction<RedoIntent>(
          onInvoke: (_) => _controller.redo(),
        ),
        ClearIntent: CallbackAction<ClearIntent>(
          onInvoke: (_) => _controller.clearCanvas(),
        ),
        ColorPickerIntent: CallbackAction<ColorPickerIntent>(
          onInvoke: (_) => _controller.openColorPicker(context),
        ),
        StrokeWidthIntent: CallbackAction<StrokeWidthIntent>(
          onInvoke: (_) => _controller.openStrokeWidthDialog(context),
        ),
      },
      child: Scaffold(
        appBar: AppBar(actions: [DrawingToolbar(controller: _controller)]),
        body: ValueListenableBuilder<int>(
          valueListenable: _controller.repaintNotifier,
          builder: (context, _, __) {
            return DrawingCanvas(
              backgroundImage: _controller.backgroundImage,
              strokes: _controller.strokes,
              currentStroke: _controller.currentStroke,
              onStartStroke: _controller.startStroke,
              onDraw: _controller.addPoint,
              onEndStroke: _controller.endStroke,
              repaintNotifier: _controller.repaintNotifier,
              repaintKey: _controller.canvasKey,
            );
          },
        ),
      ),
    );
  }
}
