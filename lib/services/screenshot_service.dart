import 'dart:io';
import 'package:path/path.dart' as path;

class ScreenshotService {
  static Future<String?> captureScreenshot() async {
    try {
      final execDir = File(Platform.resolvedExecutable).parent;
      final cliPath = path.join(execDir.path, '../Resources/screenshot_tool');

      // Create unique temp file path for the screenshot
      final tempDir = Directory.systemTemp;
      final tempFile = File(
        path.join(
          tempDir.path,
          'temp_screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
        ),
      );
      final tempFilePath = tempFile.path;

      final result = await Process.run(cliPath, [tempFilePath]);

      if (result.exitCode == 0) {
        return tempFilePath; // Return full temp path
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
