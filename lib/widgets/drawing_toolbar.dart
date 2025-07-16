import 'package:flutter/material.dart';
import '../controllers/drawing_controller.dart';

class DrawingToolbar extends StatelessWidget {
  final DrawingController controller;

  const DrawingToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: CircleAvatar(radius: 12, backgroundColor: Colors.blue),
        ),
        IconButton(
          tooltip: 'Select Color (⌘K)',
          icon: const Icon(Icons.palette),
          onPressed: () => controller.openColorPicker(context),
        ),
        IconButton(
          tooltip: 'Select Stroke Width (⌘B)',
          icon: const Icon(Icons.brush),
          onPressed: () => controller.openStrokeWidthDialog(context),
        ),
        IconButton(
          tooltip: 'Undo (⌘Z)',
          icon: const Icon(Icons.undo),
          onPressed: controller.undo,
        ),
        IconButton(
          tooltip: 'Redo (⌘⇧Z)',
          icon: const Icon(Icons.redo),
          onPressed: controller.redo,
        ),
        IconButton(
          tooltip: 'Clear (⌘⌫)',
          icon: const Icon(Icons.clear),
          onPressed: controller.clearCanvas,
        ),
        IconButton(
          tooltip: 'Export as PNG',
          icon: const Icon(Icons.download),
          onPressed: () => controller.exportCanvasToImage(context),
        ),
        IconButton(
          tooltip: 'Capture Screenshot',
          icon: const Icon(Icons.camera_alt),
          onPressed: () => controller.captureScreenshotAndDisplay(context),
        ),
      ],
    ); // Row
  } // build
} // DrawingToolbar
