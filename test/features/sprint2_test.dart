import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';
import 'package:geomeasure/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:geomeasure/features/capability_detection/domain/entities/sensor_type.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/core/export/report_templates.dart';
import 'package:geomeasure/core/export/image_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/core/data/backup_service.dart';

/// Helper to build CapabilityProfile with sensible defaults.
CapabilityProfile _profile({
  bool lidar = false,
  bool depth = false,
  bool arCore = false,
  bool camera = false,
  bool gps = false,
  bool compass = false,
  bool gyroscope = false,
  bool accelerometer = false,
  bool barometer = false,
  bool calibrated = false,
  int ramMb = 4096,
  HardwareAccuracy accuracy = HardwareAccuracy.medium,
}) {
  return CapabilityProfile(
    hasLidar: lidar,
    hasDepthSensor: depth,
    hasArCore: arCore,
    hasArKit: false,
    hasCamera: camera,
    hasGps: gps,
    hasCompass: compass,
    hasGyroscope: gyroscope,
    hasAccelerometer: accelerometer,
    hasBarometer: barometer,
    hasBluetooth: false,
    hasNfc: false,
    hasUwb: false,
    hasFlash: false,
    hasMicrophone: false,
    hasGpu: true,
    hasAiAccelerator: false,
    cameraCalibrated: calibrated,
    ramMb: ramMb,
    cpuCores: 8,
    storageAvailableMb: 4096,
    displayResolution: '1080x2400',
    osVersion: 'Android 14',
    batteryLevel: 0.9,
    thermalState: ThermalState.nominal,
    sensorAccuracy: accuracy,
    networkType: NetworkType.wifi,
    permissionsGranted: true,
  );
}

void main() {
  group('Slope & Elevation Calculations', () {
    test('calculateSlopeDegrees returns 0 for flat terrain', () {
      const p1 = GpsCoordinate(latitude: 12.0, longitude: 77.0, altitudeMeters: 100);
      const p2 = GpsCoordinate(latitude: 12.001, longitude: 77.0, altitudeMeters: 100);
      expect(GeodeticCalculator.calculateSlopeDegrees(p1, p2), equals(0.0));
    });

    test('calculateSlopeDegrees returns ~45 for equal rise and run', () {
      const p1 = GpsCoordinate(latitude: 0.0, longitude: 0.0, altitudeMeters: 0);
      const p2 = GpsCoordinate(latitude: 0.0009, longitude: 0.0, altitudeMeters: 100);
      final slope = GeodeticCalculator.calculateSlopeDegrees(p1, p2);
      expect(slope, greaterThan(40));
      expect(slope, lessThan(50));
    });

    test('calculateSlopePercent returns 0 for flat terrain', () {
      const p1 = GpsCoordinate(latitude: 12.0, longitude: 77.0, altitudeMeters: 50);
      const p2 = GpsCoordinate(latitude: 12.01, longitude: 77.0, altitudeMeters: 50);
      expect(GeodeticCalculator.calculateSlopePercent(p1, p2), equals(0.0));
    });

    test('calculateElevationDifference positive when ascending', () {
      const p1 = GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 100);
      const p2 = GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 250);
      expect(GeodeticCalculator.calculateElevationDifference(p1, p2), equals(150.0));
    });

    test('calculateElevationDifference negative when descending', () {
      const p1 = GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 250);
      const p2 = GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 100);
      expect(GeodeticCalculator.calculateElevationDifference(p1, p2), equals(-150.0));
    });

    test('calculateElevationGain sums only positive deltas', () {
      final path = [
        const GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 100),
        const GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 200),
        const GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 150),
        const GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 300),
      ];
      expect(GeodeticCalculator.calculateElevationGain(path), equals(250.0));
    });

    test('calculateElevationGain returns 0 for single point', () {
      final path = [const GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 100)];
      expect(GeodeticCalculator.calculateElevationGain(path), equals(0.0));
    });

    test('calculateBearing north is ~0 degrees', () {
      const p1 = GpsCoordinate(latitude: 0.0, longitude: 0.0);
      const p2 = GpsCoordinate(latitude: 1.0, longitude: 0.0);
      expect(GeodeticCalculator.calculateBearing(p1, p2), closeTo(0.0, 1.0));
    });

    test('calculateBearing east is ~90 degrees', () {
      const p1 = GpsCoordinate(latitude: 0.0, longitude: 0.0);
      const p2 = GpsCoordinate(latitude: 0.0, longitude: 1.0);
      expect(GeodeticCalculator.calculateBearing(p1, p2), closeTo(90.0, 1.0));
    });

    test('calculateSlopeDegrees returns 0 for same point', () {
      const p = GpsCoordinate(latitude: 12.0, longitude: 77.0, altitudeMeters: 100);
      expect(GeodeticCalculator.calculateSlopeDegrees(p, p), equals(0.0));
    });
  });

  group('Engine Confidence Scoring', () {
    test('manual-only profile has 50% confidence', () {
      final profile = _profile();
      expect(profile.bestConfidence, equals(50.0));
      expect(profile.bestAlgorithm, equals(MeasurementAlgorithm.manual));
    });

    test('LiDAR calibrated profile has 98% confidence', () {
      final profile = _profile(lidar: true, camera: true, calibrated: true);
      expect(profile.bestConfidence, equals(98.0));
      expect(profile.bestAlgorithm, equals(MeasurementAlgorithm.lidar));
    });

    test('GPS+compass has moderate confidence', () {
      final profile = _profile(gps: true, compass: true);
      expect(profile.bestConfidence, greaterThanOrEqualTo(60.0));
      expect(profile.bestAlgorithm, equals(MeasurementAlgorithm.gpsImu));
    });

    test('engineConfidence contains all available engines', () {
      final profile = _profile(
        lidar: true, depth: true, arCore: true,
        camera: true, gps: true, compass: true,
        gyroscope: true, accelerometer: true,
      );
      final conf = profile.engineConfidence;
      expect(conf.containsKey(MeasurementAlgorithm.lidar), isTrue);
      expect(conf.containsKey(MeasurementAlgorithm.depthSensor), isTrue);
      expect(conf.containsKey(MeasurementAlgorithm.arCoreArKit), isTrue);
      expect(conf.containsKey(MeasurementAlgorithm.visualSlam), isTrue);
      expect(conf.containsKey(MeasurementAlgorithm.gpsImu), isTrue);
      expect(conf.containsKey(MeasurementAlgorithm.manual), isTrue);
    });

    test('barometer boosts GPS confidence', () {
      final without = _profile(gps: true, compass: true);
      final with_ = _profile(gps: true, compass: true, barometer: true);
      expect(
        with_.engineConfidence[MeasurementAlgorithm.gpsImu]!,
        greaterThan(without.engineConfidence[MeasurementAlgorithm.gpsImu]!),
      );
    });

    test('high accuracy boosts GPS confidence', () {
      final medium = _profile(
          gps: true, compass: true, accuracy: HardwareAccuracy.medium);
      final high = _profile(
          gps: true, compass: true, accuracy: HardwareAccuracy.high);
      expect(
        high.engineConfidence[MeasurementAlgorithm.gpsImu]!,
        greaterThan(medium.engineConfidence[MeasurementAlgorithm.gpsImu]!),
      );
    });
  });

  group('Report Templates', () {
    test('InspectionReport building template has 16 items', () {
      final items = InspectionReport.buildingTemplate();
      expect(items.length, equals(16));
    });

    test('InspectionReport calculates pass rate', () {
      final report = InspectionReport(
        siteName: 'Test Site',
        items: [
          InspectionItem(category: 'A', item: 'X', status: InspectionStatus.pass),
          InspectionItem(category: 'A', item: 'Y', status: InspectionStatus.pass),
          InspectionItem(category: 'B', item: 'Z', status: InspectionStatus.fail),
        ],
      );
      expect(report.passRate, closeTo(66.67, 0.1));
      expect(report.passCount, equals(2));
      expect(report.failCount, equals(1));
    });

    test('InventoryReport aggregates totals', () {
      final report = InventoryReport(
        siteName: 'Warehouse',
        items: [
          InventoryItem(name: 'Box A', quantity: 10,
              unitLengthM: 0.5, unitWidthM: 0.5, unitHeightM: 0.5),
          InventoryItem(name: 'Box B', quantity: 5,
              unitLengthM: 1.0, unitWidthM: 1.0, unitHeightM: 1.0),
        ],
      );
      expect(report.totalItemCount, equals(15));
      expect(report.totalVolumeM3, closeTo(6.25, 0.01));
    });

    test('InventoryReport groups by category', () {
      final report = InventoryReport(
        siteName: 'Site',
        items: [
          InventoryItem(name: 'A', category: 'Tools'),
          InventoryItem(name: 'B', category: 'Materials'),
          InventoryItem(name: 'C', category: 'Tools'),
        ],
      );
      expect(report.itemsByCategory.keys.length, equals(2));
      expect(report.itemsByCategory['Tools']!.length, equals(2));
    });

    test('PropertyReport serializes to JSON', () {
      const report = PropertyReport(
        propertyName: 'Test',
        totalAreaSqm: 150.0,
        numberOfRooms: 3,
      );
      final json = report.toJson();
      expect(json['propertyName'], equals('Test'));
      expect(json['totalAreaSqm'], equals(150.0));
    });

    test('InspectionItem serializes to JSON', () {
      final item = InspectionItem(
        category: 'Structure',
        item: 'Foundation',
        status: InspectionStatus.pass,
        notes: 'Good condition',
      );
      final json = item.toJson();
      expect(json['status'], equals('pass'));
      expect(json['notes'], equals('Good condition'));
    });
  });

  group('Image Exporter', () {
    test('generateFilename includes shape type and format', () {
      const shape = RectangleShape(lengthMeters: 5, widthMeters: 3);
      final filename = ImageExporter.generateFilename(shape, 'png');
      expect(filename, contains('rectangle'));
      expect(filename, endsWith('.png'));
    });

    test('generateCaption includes area', () {
      const shape = RectangleShape(lengthMeters: 5, widthMeters: 3);
      final caption = ImageExporter.generateCaption(shape);
      expect(caption, contains('15.00'));
      expect(caption, contains('m'));
    });
  });

  group('Backup Service', () {
    test('defaultFilename contains timestamp format', () {
      final filename = BackupService.defaultFilename();
      expect(filename, startsWith('geomeasure_backup_'));
      expect(filename, endsWith('.json'));
    });

    test('BackupResult stores success state', () {
      const result = BackupResult(success: true, message: 'OK', itemCount: 5);
      expect(result.success, isTrue);
      expect(result.itemCount, equals(5));
    });

    test('BackupResult failure state', () {
      const result = BackupResult(success: false, message: 'File not found');
      expect(result.success, isFalse);
      expect(result.itemCount, equals(0));
    });
  });
}
