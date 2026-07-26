import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:meassure_app/features/capability_detection/domain/entities/sensor_type.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:meassure_app/features/measurement_engine/domain/services/algorithm_selector.dart';

void main() {
  group('AlgorithmSelector Fallback Hierarchy Tests', () {
    test('selects LiDAR when LiDAR hardware is available', () {
      final profile = CapabilityProfile(
        hasLidar: true,
        hasDepthSensor: true,
        hasArCore: true,
        hasArKit: true,
        hasCamera: true,
        hasGps: true,
        hasCompass: true,
        hasGyroscope: true,
        hasAccelerometer: true,
        hasBarometer: true,
        hasBluetooth: true,
        hasNfc: true,
        hasUwb: true,
        ramMb: 8192,
        cpuCores: 8,
        hasAiAccelerator: true,
        batteryLevel: 0.9,
        thermalState: ThermalState.nominal,
        sensorAccuracy: HardwareAccuracy.high,
        permissionsGranted: true,
      );

      final selected = AlgorithmSelector.selectOptimalAlgorithm(profile);
      expect(selected, equals(MeasurementAlgorithm.lidar));
    });

    test('selects Manual fallback when permissions are denied', () {
      final profile = CapabilityProfile(
        hasLidar: true,
        hasDepthSensor: true,
        hasArCore: true,
        hasArKit: true,
        hasCamera: true,
        hasGps: true,
        hasCompass: true,
        hasGyroscope: true,
        hasAccelerometer: true,
        hasBarometer: true,
        hasBluetooth: true,
        hasNfc: true,
        hasUwb: true,
        ramMb: 8192,
        cpuCores: 8,
        hasAiAccelerator: true,
        batteryLevel: 0.9,
        thermalState: ThermalState.nominal,
        sensorAccuracy: HardwareAccuracy.high,
        permissionsGranted: false, // Permissions denied
      );

      final selected = AlgorithmSelector.selectOptimalAlgorithm(profile);
      expect(selected, equals(MeasurementAlgorithm.manual));
    });
  });
}
