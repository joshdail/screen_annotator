import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
    override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    override func applicationDidFinishLaunching(_ notification: Notification) {
        // Register plugins
        super.applicationDidFinishLaunching(notification)
        ScreenshotHandler.register(with: self.registrar(forPlugin: "ScreenshotHandler"))
    }
} // AppDelegate
