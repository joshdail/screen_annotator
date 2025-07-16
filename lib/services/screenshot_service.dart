import 'dart:io';
import 'package:path/path.dart' as path;

class ScreenshotService {
  static Future<String?> captureScreenshot() async {
    try {
      final cliPath = getExecutablePath();

      // Use Flutter's managed system temp directory
      final tempDir = Directory.systemTemp;

      final tempFilePath = path.join(
        tempDir.path,
        'temp_screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
      );

      final result = await Process.run(cliPath, [tempFilePath]);

      if (result.exitCode == 0) {
        return tempFilePath;
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

String getExecutablePath() {
  if (Platform.isMacOS) {
    // Use absolute path during development (inside Flutter project)
    final devPath = './screenshot_tool';

    if (File(devPath).existsSync()) {
      return devPath;
    }

    // Fallback: when bundled in a macOS app (production)
    final execDir = File(Platform.resolvedExecutable).parent;
    final contentsDir = execDir.parent;
    return path.join(contentsDir.path, 'Resources', 'screenshot_tool');
  } else {
    return './screenshot_tool';
  }
}
