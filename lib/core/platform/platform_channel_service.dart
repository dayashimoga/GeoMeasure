import 'package:flutter/services.dart';
import '../logging/app_logger.dart';

/// Platform channel service with desktop (Windows/macOS/Linux) support.
///
/// Each platform implements a subset of capability queries.
/// Desktop platforms report available sensors via OS APIs.
class PlatformChannelService {
  static const _channel = MethodChannel('geomeasure/capability_detection');

  /// Query hardware capabilities from the native platform.
  Future<Map<String, dynamic>> queryCapabilities() async {
    try {
      final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'detectCapabilities',
      );
      if (result != null) {
        return result.cast<String, dynamic>();
      }
    } on MissingPluginException {
      logger.warning(
        'Platform channel not available — using fallback',
        tag: 'Platform',
      );
    } on PlatformException catch (e) {
      logger.error(
        'Platform channel error: ${e.message}',
        tag: 'Platform',
      );
    }
    return _fallbackCapabilities();
  }

  /// Fallback capabilities for platforms without native channel.
  Map<String, dynamic> _fallbackCapabilities() {
    return {
      'hasLidar': false,
      'hasDepthSensor': false,
      'hasArCore': false,
      'hasArKit': false,
      'hasCamera': false,
      'hasGps': false,
      'hasCompass': false,
      'hasGyroscope': false,
      'hasAccelerometer': false,
      'hasBarometer': false,
      'hasBluetooth': false,
      'hasNfc': false,
      'hasAiAccelerator': false,
      'ramMb': 2048,
      'cpuCores': 4,
      'batteryLevel': 1.0,
      'thermalState': 'nominal',
      'networkType': 'unknown',
      'cameraPermission': false,
      'locationPermission': false,
      'deviceModel': 'Unknown',
      'osVersion': 'Unknown',
    };
  }
}

// ─── Windows Platform Channel (native side reference) ───
// In windows/runner/flutter_window.cpp, register:
//
// flutter::MethodChannel<> channel(
//     flutter_controller->engine()->messenger(),
//     "com.geomeasure.app/capabilities",
//     &flutter::StandardMethodCodec::GetInstance());
//
// channel.SetMethodCallHandler(
//     [](const flutter::MethodCall<>& call, auto result) {
//       if (call.method_name() == "getHardwareCapabilities") {
//         flutter::EncodableMap caps;
//         caps[flutter::EncodableValue("hasCamera")] = true;
//         caps[flutter::EncodableValue("cpuCores")] = 8;
//         // ... etc
//         result->Success(flutter::EncodableValue(caps));
//       }
//     });
