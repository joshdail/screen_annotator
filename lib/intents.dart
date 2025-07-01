import 'package:flutter/widgets.dart';

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

class StrokeWidthIntent extends Intent {
  const StrokeWidthIntent();
}
