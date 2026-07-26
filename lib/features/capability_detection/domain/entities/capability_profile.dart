import 'sensor_type.dart';

class CapabilityProfile {
  final bool hasLidar;
  final bool hasDepthSensor;
  final bool hasArCore;
  final bool hasArKit;
  final bool hasCamera;
  final bool hasGps;
  final bool hasCompass;
  final bool hasGyroscope;
  final bool hasAccelerometer;
  final bool hasBarometer;
  final bool hasBluetooth;
  final bool hasNfc;
  final bool hasUwb;
  final bool hasFlash;
  final bool hasMicrophone;
  final bool hasGpu;
  final bool hasAiAccelerator;
  final bool cameraCalibrated;
  final int ramMb;
  final int cpuCores;
  final int storageAvailableMb;
  final String displayResolution;
  final String osVersion;
  final double batteryLevel;
  final ThermalState thermalState;
  final HardwareAccuracy sensorAccuracy;
  final NetworkType networkType;
  final bool permissionsGranted;

  const CapabilityProfile({
    required this.hasLidar,
    required this.hasDepthSensor,
    required this.hasArCore,
    required this.hasArKit,
    required this.hasCamera,
    required this.hasGps,
    required this.hasCompass,
    required this.hasGyroscope,
    required this.hasAccelerometer,
    required this.hasBarometer,
    required this.hasBluetooth,
    required this.hasNfc,
    required this.hasUwb,
    required this.hasFlash,
    required this.hasMicrophone,
    required this.hasGpu,
    required this.hasAiAccelerator,
    required this.cameraCalibrated,
    required this.ramMb,
    required this.cpuCores,
    required this.storageAvailableMb,
    required this.displayResolution,
    required this.osVersion,
    required this.batteryLevel,
    required this.thermalState,
    required this.sensorAccuracy,
    required this.networkType,
    required this.permissionsGranted,
  });

  factory CapabilityProfile.fallbackManual() {
    return const CapabilityProfile(
      hasLidar: false,
      hasDepthSensor: false,
      hasArCore: false,
      hasArKit: false,
      hasCamera: false,
      hasGps: false,
      hasCompass: false,
      hasGyroscope: false,
      hasAccelerometer: false,
      hasBarometer: false,
      hasBluetooth: false,
      hasNfc: false,
      hasUwb: false,
      hasFlash: false,
      hasMicrophone: false,
      hasGpu: false,
      hasAiAccelerator: false,
      cameraCalibrated: false,
      ramMb: 2048,
      cpuCores: 4,
      storageAvailableMb: 1024,
      displayResolution: '720x1280',
      osVersion: 'unknown',
      batteryLevel: 1.0,
      thermalState: ThermalState.nominal,
      sensorAccuracy: HardwareAccuracy.low,
      networkType: NetworkType.none,
      permissionsGranted: true,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasLidar': hasLidar,
        'hasDepthSensor': hasDepthSensor,
        'hasArCore': hasArCore,
        'hasArKit': hasArKit,
        'hasCamera': hasCamera,
        'hasGps': hasGps,
        'hasCompass': hasCompass,
        'hasGyroscope': hasGyroscope,
        'hasAccelerometer': hasAccelerometer,
        'hasBarometer': hasBarometer,
        'hasBluetooth': hasBluetooth,
        'hasNfc': hasNfc,
        'hasUwb': hasUwb,
        'hasFlash': hasFlash,
        'hasMicrophone': hasMicrophone,
        'hasGpu': hasGpu,
        'hasAiAccelerator': hasAiAccelerator,
        'cameraCalibrated': cameraCalibrated,
        'ramMb': ramMb,
        'cpuCores': cpuCores,
        'storageAvailableMb': storageAvailableMb,
        'displayResolution': displayResolution,
        'osVersion': osVersion,
        'batteryLevel': batteryLevel,
        'thermalState': thermalState.name,
        'sensorAccuracy': sensorAccuracy.name,
        'networkType': networkType.name,
        'permissionsGranted': permissionsGranted,
      };
}
