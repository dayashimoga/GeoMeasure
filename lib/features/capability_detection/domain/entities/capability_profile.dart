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
  final int ramMb;
  final int cpuCores;
  final bool hasAiAccelerator;
  final double batteryLevel;
  final ThermalState thermalState;
  final HardwareAccuracy sensorAccuracy;
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
    required this.ramMb,
    required this.cpuCores,
    required this.hasAiAccelerator,
    required this.batteryLevel,
    required this.thermalState,
    required this.sensorAccuracy,
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
      ramMb: 2048,
      cpuCores: 4,
      hasAiAccelerator: false,
      batteryLevel: 1.0,
      thermalState: ThermalState.nominal,
      sensorAccuracy: HardwareAccuracy.low,
      permissionsGranted: true,
    );
  }
}
