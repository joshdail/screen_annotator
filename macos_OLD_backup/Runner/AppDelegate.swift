import Cocoa
import FlutterMacOS
// import GeneratedPluginRegistrant

@main
class AppDelegate: FlutterAppDelegate {
  
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationDidFinishLaunching(_ notification: Notification) {

    // GeneratedPluginRegistrant.register(with: self)
    super.applicationDidFinishLaunching(notification)

    if let window = mainFlutterWindow,
       let controller = window.contentViewController as? FlutterViewController {
      
      let channel = FlutterMethodChannel(
        name: "screen_annotator/screenshot",
        binaryMessenger: controller.engine.binaryMessenger
      )

      channel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
        if call.method == "captureScreenshot" {
          print("Native captureScreenshot called")
          let timestamp = Int(Date().timeIntervalSince1970)
          let tempDir = FileManager.default.temporaryDirectory
          let outputPath = tempDir.appendingPathComponent("screenshot_\(timestamp).png").path

          let process = Process()
          process.launchPath = "/usr/bin/screencapture"
          process.arguments = ["-x", outputPath]

          process.launch()
          process.waitUntilExit()

          if process.terminationStatus == 0 {
            result(outputPath)
          } else {
            result(FlutterError(
              code: "CAPTURE_FAILED",
              message: "Failed to capture screenshot",
              details: nil
            ))
          }
        } else {
          result(FlutterMethodNotImplemented)
        }
      } // end channel.setMethodCallHandler
    } // end if let window...
  } // end applicationDidFinishLaunching
} // end AppDelegate
