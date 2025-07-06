import 'dart:io';

class ScreenshotService {
  static Future<String?> captureScreenshot() async {
    try {
      final result = await Process.run('./screenshot_cli', []);
      if (result.exitCode == 0) {
        // Optional: parse stdout if CLI outputs path
        return 'screenshot.png';
      } else {
        print('Screenshot CLI error: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('Screenshot CLI failed: $e');
      return null;
    }
  }
}
