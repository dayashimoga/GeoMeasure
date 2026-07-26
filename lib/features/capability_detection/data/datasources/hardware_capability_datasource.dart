import '../../../../core/platform/platform_channel_service.dart';
import '../../domain/entities/capability_profile.dart';
import '../../domain/entities/sensor_type.dart';

abstract class HardwareCapabilityDataSource {
  Future<CapabilityProfile> probeHardware();
}

class HardwareCapabilityDataSourceImpl implements HardwareCapabilityDataSource {
  final PlatformChannelService platformChannelService;

  HardwareCapabilityDataSourceImpl({PlatformChannelService? platformService})
      : platformChannelService = platformService ?? PlatformChannelService();

  @override
  Future<CapabilityProfile> probeHardware() async {
    try {
      final caps = await platformChannelService.queryCapabilities();
      return CapabilityProfile(
        hasLidar: caps['hasLidar'] as bool? ?? false,
        hasDepthSensor: caps['hasDepthSensor'] as bool? ?? false,
        hasArCore: caps['hasArCore'] as bool? ?? false,
        hasArKit: caps['hasArKit'] as bool? ?? false,
        hasCamera: caps['hasCamera'] as bool? ?? false,
        hasGps: caps['hasGps'] as bool? ?? false,
        hasCompass: caps['hasCompass'] as bool? ?? false,
        hasGyroscope: caps['hasGyroscope'] as bool? ?? false,
        hasAccelerometer: caps['hasAccelerometer'] as bool? ?? false,
        hasBarometer: caps['hasBarometer'] as bool? ?? false,
        hasBluetooth: caps['hasBluetooth'] as bool? ?? false,
        hasNfc: caps['hasNfc'] as bool? ?? false,
        hasUwb: caps['hasUwb'] as bool? ?? false,
        hasFlash: caps['hasFlash'] as bool? ?? false,
        hasMicrophone: caps['hasMicrophone'] as bool? ?? false,
        hasGpu: caps['hasGpu'] as bool? ?? false,
        hasAiAccelerator: caps['hasAiAccelerator'] as bool? ?? false,
        cameraCalibrated: caps['cameraCalibrated'] as bool? ?? false,
        ramMb: caps['ramMb'] as int? ?? 2048,
        cpuCores: caps['cpuCores'] as int? ?? 4,
        storageAvailableMb: caps['storageAvailableMb'] as int? ?? 1024,
        displayResolution: caps['displayResolution'] as String? ?? '720x1280',
        osVersion: caps['osVersion'] as String? ?? 'unknown',
        batteryLevel: (caps['batteryLevel'] as num?)?.toDouble() ?? 1.0,
        thermalState: _parseThermalState(caps['thermalState']),
        sensorAccuracy: _parseSensorAccuracy(caps['sensorAccuracy']),
        networkType: _parseNetworkType(caps['networkType']),
        permissionsGranted: caps['permissionsGranted'] as bool? ?? false,
      );
    } catch (_) {
      return CapabilityProfile.fallbackManual();
    }
  }

  static ThermalState _parseThermalState(dynamic value) {
    if (value is ThermalState) return value;
    final name = value?.toString() ?? 'nominal';
    return ThermalState.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ThermalState.nominal,
    );
  }

  static HardwareAccuracy _parseSensorAccuracy(dynamic value) {
    if (value is HardwareAccuracy) return value;
    final name = value?.toString() ?? 'low';
    return HardwareAccuracy.values.firstWhere(
      (e) => e.name == name,
      orElse: () => HardwareAccuracy.low,
    );
  }

  static NetworkType _parseNetworkType(dynamic value) {
    if (value is NetworkType) return value;
    final name = value?.toString() ?? 'none';
    return NetworkType.values.firstWhere(
      (e) => e.name == name,
      orElse: () => NetworkType.none,
    );
  }
}
