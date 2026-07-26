import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:geomeasure/features/capability_detection/domain/entities/sensor_type.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/algorithm_selector.dart';

CapabilityProfile _buildProfile({
  bool lidar = false,
  bool depth = false,
  bool arCore = false,
  bool arKit = false,
  bool camera = false,
  bool gps = false,
  bool compass = false,
  bool permissions = true,
  double battery = 0.9,
  ThermalState thermal = ThermalState.nominal,
}) {
  return CapabilityProfile(
    hasLidar: lidar,
    hasDepthSensor: depth,
    hasArCore: arCore,
    hasArKit: arKit,
    hasCamera: camera,
    hasGps: gps,
    hasCompass: compass,
    hasGyroscope: true,
    hasAccelerometer: true,
    hasBarometer: false,
    hasBluetooth: true,
    hasNfc: false,
    hasUwb: false,
    hasFlash: true,
    hasMicrophone: true,
    hasGpu: true,
    hasAiAccelerator: true,
    cameraCalibrated: false,
    ramMb: 8192,
    cpuCores: 8,
    storageAvailableMb: 4096,
    displayResolution: '1080x2400',
    osVersion: 'Android 14',
    batteryLevel: battery,
    thermalState: thermal,
    sensorAccuracy: HardwareAccuracy.high,
    networkType: NetworkType.wifi,
    permissionsGranted: permissions,
  );
}

void main() {
  group('AlgorithmSelector — Full Fallback Hierarchy (G9 Fix)', () {
    test('1. LiDAR available → selects LiDAR', () {
      final p = _buildProfile(lidar: true, depth: true, arCore: true, camera: true, gps: true, compass: true);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.lidar);
    });

    test('2. Depth only → selects depthSensor', () {
      final p = _buildProfile(depth: true);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.depthSensor);
    });

    test('3. ARCore only → selects arCoreArKit', () {
      final p = _buildProfile(arCore: true);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.arCoreArKit);
    });

    test('4. Camera only → selects visualSlam', () {
      final p = _buildProfile(camera: true);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.visualSlam);
    });

    test('5. GPS + Compass only → selects gpsImu', () {
      final p = _buildProfile(gps: true, compass: true);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.gpsImu);
    });

    test('6. Bare device → selects manual', () {
      final p = _buildProfile();
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.manual);
    });

    test('7. Permissions denied → forces manual even with LiDAR', () {
      final p = _buildProfile(lidar: true, permissions: false);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.manual);
    });

    test('G2: Critical thermal → forces manual', () {
      final p = _buildProfile(lidar: true, thermal: ThermalState.critical);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.manual);
    });

    test('G2: Serious thermal with GPS → falls back to gpsImu', () {
      final p = _buildProfile(lidar: true, gps: true, compass: true, thermal: ThermalState.serious);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.gpsImu);
    });

    test('G2: Low battery (<10%) with GPS → falls back to gpsImu', () {
      final p = _buildProfile(lidar: true, gps: true, compass: true, battery: 0.05);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.gpsImu);
    });

    test('G2: Low battery (<10%) without GPS → falls back to manual', () {
      final p = _buildProfile(lidar: true, battery: 0.05);
      expect(AlgorithmSelector.selectOptimalAlgorithm(p), MeasurementAlgorithm.manual);
    });
  });
}
