import Cocoa
import FlutterMacOS

public class ScreenshotHandler: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "screen_annotator/screenshot", binaryMessenger: registrar.messenger)
        let instance = ScreenshotHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public func handle(_ call: FlutterMethodCall, result, @escaping FlutterResult) {
        switch call.method {
        case "captureScreenshot":
            NSLog("captureScreenshot method called")
            result("/dummy/path/to/screenshot.png") // placeholder
        default:
            result(FlutterMethodNotImplemented)
        } // switch
    }
} // ScreenshotHandler
