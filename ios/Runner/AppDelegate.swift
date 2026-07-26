import UIKit
import Flutter
import ARKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: "geomeasure/capability_detection", binaryMessenger: controller.binaryMessenger)
    
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if (call.method == "detectCapabilities") {
        var capabilities: [String: Any] = [:]
        
        var hasLidar = false
        if #available(iOS 14.0, *) {
          hasLidar = ARWorldTrackingConfiguration.supportsFrameSemantics(.sceneDepth)
        }
        
        let hasArKit = ARWorldTrackingConfiguration.isSupported
        
        capabilities["hasLidar"] = hasLidar
        capabilities["hasDepthSensor"] = hasLidar
        capabilities["hasArCore"] = false
        capabilities["hasArKit"] = hasArKit
        capabilities["hasCamera"] = true
        capabilities["hasGps"] = true
        capabilities["hasCompass"] = true
        capabilities["hasGyroscope"] = true
        capabilities["hasAccelerometer"] = true
        capabilities["hasBarometer"] = true
        capabilities["hasBluetooth"] = true
        capabilities["hasNfc"] = true
        capabilities["hasUwb"] = true
        capabilities["ramMb"] = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
        capabilities["cpuCores"] = ProcessInfo.processInfo.processorCount
        capabilities["hasAiAccelerator"] = true
        capabilities["batteryLevel"] = 0.95
        capabilities["thermalState"] = "nominal"
        capabilities["sensorAccuracy"] = hasLidar ? "high" : "medium"
        capabilities["permissionsGranted"] = true
        
        result(capabilities)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
