import 'package:flutter/services.dart';
import '../../features/capability_detection/domain/entities/capability_profile.dart';
import '../../features/capability_detection/domain/entities/sensor_type.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel('geomeasure/capability_detection');

  Future<CapabilityProfile> detectCapabilities() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod('detectCapabilities');
      if (result != null) {
        return CapabilityProfile(
          hasLidar: result['hasLidar'] as bool? ?? false,
          hasDepthSensor: result['hasDepthSensor'] as bool? ?? false,
          hasArCore: result['hasArCore'] as bool? ?? false,
          hasArKit: result['hasArKit'] as bool? ?? false,
          hasCamera: result['hasCamera'] as bool? ?? true,
          hasGps: result['hasGps'] as bool? ?? true,
          hasCompass: result['hasCompass'] as bool? ?? true,
          hasGyroscope: result['hasGyroscope'] as bool? ?? true,
          hasAccelerometer: result['hasAccelerometer'] as bool? ?? true,
          hasBarometer: result['hasBarometer'] as bool? ?? false,
          hasBluetooth: result['hasBluetooth'] as bool? ?? true,
          hasNfc: result['hasNfc'] as bool? ?? false,
          hasUwb: result['hasUwb'] as bool? ?? false,
          ramMb: result['ramMb'] as int? ?? 4096,
          cpuCores: result['cpuCores'] as int? ?? 8,
          hasAiAccelerator: result['hasAiAccelerator'] as bool? ?? true,
          batteryLevel: (result['batteryLevel'] as num?)?.toDouble() ?? 1.0,
          thermalState: _parseThermalState(result['thermalState'] as String?),
          sensorAccuracy: _parseAccuracy(result['sensorAccuracy'] as String?),
          permissionsGranted: result['permissionsGranted'] as bool? ?? true,
        );
      }
    } on MissingPluginException {
      // Running on non-native platform (Web/Desktop runner)
    } catch (_) {
      // Fallback safely to baseline hardware profile
    }

    return CapabilityProfile.fallbackManual();
  }

  ThermalState _parseThermalState(String? value) {
    switch (value) {
      case 'fair':
        return ThermalState.fair;
      case 'serious':
        return ThermalState.serious;
      case 'critical':
        return ThermalState.critical;
      default:
        return ThermalState.nominal;
    }
  }

  HardwareAccuracy _parseAccuracy(String? value) {
    switch (value) {
      case 'high':
        return HardwareAccuracy.high;
      case 'medium':
        return HardwareAccuracy.medium;
      case 'low':
        return HardwareAccuracy.low;
      default:
        return HardwareAccuracy.uncalibrated;
    }
  }
}
