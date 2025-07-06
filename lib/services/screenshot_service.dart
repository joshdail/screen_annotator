import 'package:flutter/services.dart';

class ScreenshotService {
  static const _channel = MethodChannel('screen_annotator/screenshot');

  static Future<String?> captureScreenshot() async {
    try {
      final String? path = await _channel.invokeMethod('captureScreenshot');
      return path;
    } on PlatformException catch (err) {
      print('Screenshot capture failed: ${err.message}');
      return null;
    }
  } // captureScreenshot
} // ScreenshotService
