import 'package:flutter/services.dart';
import '../../features/capability_detection/domain/entities/capability_profile.dart';
import '../../features/capability_detection/domain/entities/sensor_type.dart';

class PlatformChannelService {
  static const MethodChannel _channel = MethodChannel(
    'geomeasure/capability_detection',
  );

  Future<CapabilityProfile> detectCapabilities() async {
    try {
      final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'detectCapabilities',
      );
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
          hasFlash: result['hasFlash'] as bool? ?? true,
          hasMicrophone: result['hasMicrophone'] as bool? ?? true,
          hasGpu: result['hasGpu'] as bool? ?? true,
          hasAiAccelerator: result['hasAiAccelerator'] as bool? ?? true,
          cameraCalibrated: result['cameraCalibrated'] as bool? ?? false,
          ramMb: result['ramMb'] as int? ?? 4096,
          cpuCores: result['cpuCores'] as int? ?? 8,
          storageAvailableMb: result['storageAvailableMb'] as int? ?? 2048,
          displayResolution:
              result['displayResolution'] as String? ?? '1080x1920',
          osVersion: result['osVersion'] as String? ?? 'unknown',
          batteryLevel: (result['batteryLevel'] as num?)?.toDouble() ?? 1.0,
          thermalState: _parseThermalState(result['thermalState'] as String?),
          sensorAccuracy: _parseAccuracy(result['sensorAccuracy'] as String?),
          networkType: _parseNetworkType(result['networkType'] as String?),
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

  NetworkType _parseNetworkType(String? value) {
    switch (value) {
      case 'wifi':
        return NetworkType.wifi;
      case 'cellular':
        return NetworkType.cellular;
      default:
        return NetworkType.none;
    }
  }
}
