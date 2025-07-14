import 'dart:io';
import 'package:path/path.dart' as path;

class ScreenshotService {
  static Future<String?> captureScreenshot() async {
    try {
      final execDir = File(Platform.resolvedExecutable).parent;
      final cliPath = path.join(execDir.path, '../Resources/screenshot_tool');

      // Choose a fixed output location (in app's temp dir or current dir)
      final outputPath = path.join(Directory.systemTemp.path, 'screenshot.png');

      final result = await Process.run(cliPath, [outputPath]);

      if (result.exitCode == 0) {
        return outputPath;
      } else {
        print('Screenshot CLI error: ${result.stderr}');
        return null;
      }
    } catch (e) {
      print('Screenshot CLI failed: $e');
      return null;
    }
  }
} // ScreenshotService

String getExecutablePath() {
  if (Platform.isMacOS) {
    final execDir = File(Platform.resolvedExecutable).parent;

    final contentsDir = execDir.parent;
    final resourcePath = path.join(
      contentsDir.path,
      'Resources',
      'screenshot_tool',
    );

    return resourcePath;
  } else {
    return './screenshot_tool';
  }
}
