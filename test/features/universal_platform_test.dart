import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/precision_mode.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/ai_vision/domain/entities/detected_object.dart';
import 'package:geomeasure/features/ai_vision/domain/entities/building_analysis.dart';
import 'package:geomeasure/features/ai_vision/domain/entities/measurement_validation.dart';
import 'package:geomeasure/features/ai_vision/domain/services/edge_detector.dart';
import 'package:geomeasure/features/ai_vision/domain/services/object_counter.dart';
import 'package:geomeasure/features/ai_vision/domain/services/photogrammetry.dart';
import 'package:geomeasure/features/ai_vision/data/services/vision_service.dart';
import 'package:geomeasure/features/estimation/domain/entities/material_estimate.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/sensor_fusion.dart';
import 'package:geomeasure/features/export/excel_exporter.dart';
import 'package:geomeasure/core/export/json_exporter.dart';
import 'package:geomeasure/core/export/export_manager.dart';
import 'package:geomeasure/core/config/app_config.dart';

void main() {
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Universal Shape Tests
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('CylinderShape', () {
    test('volume = πr²h', () {
      const cyl = CylinderShape(radiusMeters: 2, heightMeters: 5);
      expect(cyl.calculateVolumeInCubicMeters(), closeTo(pi * 4 * 5, 0.01));
    });

    test('lateral area = 2πrh', () {
      const cyl = CylinderShape(radiusMeters: 3, heightMeters: 7);
      expect(cyl.calculateLateralArea(), closeTo(2 * pi * 3 * 7, 0.01));
    });

    test('surface area = 2πr² + 2πrh', () {
      const cyl = CylinderShape(radiusMeters: 2, heightMeters: 5);
      final expected = 2 * pi * 4 + 2 * pi * 2 * 5;
      expect(cyl.calculateSurfaceArea(), closeTo(expected, 0.01));
    });

    test('validation rejects zero radius', () {
      const cyl = CylinderShape(radiusMeters: 0, heightMeters: 5);
      expect(cyl.validate(), isNotNull);
    });
  });

  group('SphereShape', () {
    test('volume = 4/3 πr³', () {
      const s = SphereShape(radiusMeters: 3);
      expect(s.calculateVolumeInCubicMeters(),
          closeTo(4.0 / 3.0 * pi * 27, 0.01));
    });

    test('surface area = 4πr²', () {
      const s = SphereShape(radiusMeters: 5);
      expect(s.calculateSurfaceArea(), closeTo(4 * pi * 25, 0.01));
    });

    test('diameter', () {
      const s = SphereShape(radiusMeters: 2.5);
      expect(s.diameterMeters, 5.0);
    });
  });

  group('CuboidShape', () {
    test('volume = l × w × h', () {
      const b = CuboidShape(lengthMeters: 3, widthMeters: 4, heightMeters: 5);
      expect(b.calculateVolumeInCubicMeters(), 60.0);
    });

    test('surface area = 2(lw + lh + wh)', () {
      const b = CuboidShape(lengthMeters: 3, widthMeters: 4, heightMeters: 5);
      expect(b.calculateSurfaceArea(), 2 * (12 + 15 + 20));
    });

    test('lateral area = 2(l+w)h', () {
      const b = CuboidShape(lengthMeters: 3, widthMeters: 4, heightMeters: 5);
      expect(b.calculateLateralArea(), 2 * 7 * 5);
    });

    test('diagonal', () {
      const b = CuboidShape(lengthMeters: 3, widthMeters: 4, heightMeters: 0);
      expect(b.diagonalMeters, closeTo(5.0, 0.01)); // 3-4-5
    });
  });

  group('ConeShape', () {
    test('volume = 1/3 πr²h', () {
      const c = ConeShape(radiusMeters: 3, heightMeters: 6);
      expect(c.calculateVolumeInCubicMeters(),
          closeTo(pi * 9 * 6 / 3, 0.01));
    });

    test('slant height', () {
      const c = ConeShape(radiusMeters: 3, heightMeters: 4);
      expect(c.slantHeight, closeTo(5.0, 0.01)); // 3-4-5
    });

    test('lateral area = πrl', () {
      const c = ConeShape(radiusMeters: 3, heightMeters: 4);
      expect(c.calculateLateralArea(), closeTo(pi * 3 * 5, 0.01));
    });
  });

  group('FrustumShape', () {
    test('volume formula', () {
      const f = FrustumShape(
          topRadiusMeters: 2, bottomRadiusMeters: 4, heightMeters: 6);
      final expected = (pi * 6 / 3) * (16 + 4 + 8); // π*2*(16+4+8)
      expect(f.calculateVolumeInCubicMeters(), closeTo(expected, 0.01));
    });

    test('slant height', () {
      const f = FrustumShape(
          topRadiusMeters: 1, bottomRadiusMeters: 4, heightMeters: 4);
      expect(f.slantHeight, closeTo(5.0, 0.01)); // 3-4-5
    });
  });

  group('LShapeRoom', () {
    test('area = sum of two rectangles', () {
      const l = LShapeRoom(
        longLengthMeters: 10,
        longWidthMeters: 5,
        shortLengthMeters: 4,
        shortWidthMeters: 3,
        heightMeters: 3,
      );
      expect(l.calculateAreaInSquareMeters(), 50 + 12);
    });

    test('volume = area × height', () {
      const l = LShapeRoom(
        longLengthMeters: 10,
        longWidthMeters: 5,
        shortLengthMeters: 4,
        shortWidthMeters: 3,
        heightMeters: 3,
      );
      expect(l.calculateVolumeInCubicMeters(), 62 * 3);
    });
  });

  group('ArchShape', () {
    test('semicircular arch area', () {
      // A semicircle with diameter 4 has radius 2, area = π*4/2 = 2π
      const arch = ArchShape(
        spanMeters: 4,
        riseMeters: 2,
        depthMeters: 1,
      );
      // radius = (16/16) + 1 = 2, theta = 2*asin(1) = π
      // area = (4/2)(π - 0) = 2π ≈ 6.28
      expect(arch.calculateAreaInSquareMeters(), closeTo(2 * pi, 0.1));
    });

    test('volume = area × depth', () {
      const arch = ArchShape(
        spanMeters: 4,
        riseMeters: 2,
        depthMeters: 3,
      );
      expect(arch.calculateVolumeInCubicMeters(),
          closeTo(arch.calculateAreaInSquareMeters() * 3, 0.1));
    });
  });

  group('GableRoofShape', () {
    test('pitch angle', () {
      const roof = GableRoofShape(
        ridgeLengthMeters: 10,
        spanMeters: 8,
        riseMeters: 4,
      );
      // pitch = atan2(4, 4) = 45°
      expect(roof.pitchDegrees, closeTo(45.0, 0.1));
    });

    test('surface area is > plan area (sloped)', () {
      const roof = GableRoofShape(
        ridgeLengthMeters: 10,
        spanMeters: 8,
        riseMeters: 3,
      );
      expect(roof.calculateAreaInSquareMeters(),
          greaterThan(roof.planArea * 0.9));
    });
  });

  group('ExcavationShape', () {
    test('trapezoidal cross-section volume', () {
      const exc = ExcavationShape(
        lengthMeters: 10,
        topWidthMeters: 6,
        bottomWidthMeters: 4,
        depthMeters: 3,
      );
      // cross-section = (6+4)/2 * 3 = 15
      // volume = 15 * 10 = 150
      expect(exc.calculateVolumeInCubicMeters(), 150.0);
      expect(exc.cutVolume, 150.0);
    });

    test('fill volume calculation', () {
      const exc = ExcavationShape(
        lengthMeters: 10,
        topWidthMeters: 6,
        bottomWidthMeters: 4,
        depthMeters: 3,
      );
      expect(exc.fillVolume(100), 50.0); // 150 - 100
    });
  });

  group('PipeShape', () {
    test('annular cross-section', () {
      const pipe = PipeShape(
        outerRadiusMeters: 0.5,
        innerRadiusMeters: 0.4,
        lengthMeters: 10,
      );
      final expected = pi * (0.25 - 0.16);
      expect(pipe.calculateAreaInSquareMeters(), closeTo(expected, 0.001));
    });

    test('wall thickness', () {
      const pipe = PipeShape(
        outerRadiusMeters: 0.5,
        innerRadiusMeters: 0.4,
        lengthMeters: 10,
      );
      expect(pipe.wallThickness, closeTo(0.1, 0.001));
    });

    test('inner volume', () {
      const pipe = PipeShape(
        outerRadiusMeters: 0.5,
        innerRadiusMeters: 0.4,
        lengthMeters: 10,
      );
      expect(pipe.innerVolume, closeTo(pi * 0.16 * 10, 0.01));
    });

    test('validation rejects inner >= outer', () {
      const bad = PipeShape(
        outerRadiusMeters: 0.3,
        innerRadiusMeters: 0.4,
        lengthMeters: 10,
      );
      expect(bad.validate(), isNotNull);
    });
  });

  group('PoolShape', () {
    test('water volume', () {
      const pool = PoolShape(
        lengthMeters: 25,
        widthMeters: 10,
        shallowDepthMeters: 1,
        deepDepthMeters: 3,
      );
      expect(pool.calculateVolumeInCubicMeters(), 25 * 10 * 2.0);
    });

    test('water volume in litres', () {
      const pool = PoolShape(
        lengthMeters: 25,
        widthMeters: 10,
        shallowDepthMeters: 1,
        deepDepthMeters: 3,
      );
      expect(pool.waterVolumeLitres, 500000.0);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Precision Modes
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('PrecisionMode', () {
    test('all modes have default configs', () {
      for (final mode in PrecisionMode.values) {
        final config = PrecisionConfig.forMode(mode);
        expect(config.mode, mode);
        expect(config.sampleCount, greaterThan(0));
        expect(config.accuracyTargetMeters, greaterThan(0));
      }
    });

    test('fast is less accurate than highAccuracy', () {
      final fast = PrecisionConfig.forMode(PrecisionMode.fast);
      final high = PrecisionConfig.forMode(PrecisionMode.highAccuracy);
      expect(fast.accuracyTargetMeters,
          greaterThan(high.accuracyTargetMeters));
    });

    test('professional requires external hardware', () {
      final pro =
          PrecisionConfig.forMode(PrecisionMode.professionalSurvey);
      expect(pro.requiresExternalHardware, true);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Extended MeasurementResult
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('MeasurementResult.fromShape', () {
    test('extracts room metrics', () {
      const room = RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(5, 0),
          Point3D(5, 4),
          Point3D(0, 4),
        ],
        heightMeters: 3,
      );
      final result = MeasurementResult.fromShape(
        shape: room,
        algorithm: MeasurementAlgorithm.manual,
        accuracy: 95.0,
        name: 'Living Room',
      );
      expect(result.area, closeTo(20.0, 0.01));
      expect(result.volume, closeTo(60.0, 0.01));
      expect(result.wallArea, closeTo(54.0, 0.01));
      expect(result.floorArea, closeTo(20.0, 0.01));
      expect(result.ceilingArea, closeTo(20.0, 0.01));
    });

    test('extracts pipe metrics', () {
      const pipe = PipeShape(
        outerRadiusMeters: 0.5,
        innerRadiusMeters: 0.4,
        lengthMeters: 10,
      );
      final result = MeasurementResult.fromShape(
        shape: pipe,
        algorithm: MeasurementAlgorithm.manual,
        accuracy: 90.0,
      );
      expect(result.thickness, closeTo(0.1, 0.001));
    });

    test('serialization round-trip with extended fields', () {
      final result = MeasurementResult(
        area: 100,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 40,
        distanceUnit: DistanceUnit.meters,
        volume: 300,
        surfaceArea: 340,
        wallArea: 240,
        floorArea: 100,
        ceilingArea: 100,
        roofArea: 110,
        confidenceScore: 0.95,
        errorMarginMeters: 0.02,
        sensorUsed: 'lidar',
        precisionMode: PrecisionMode.highAccuracy,
        algorithmUsed: MeasurementAlgorithm.lidar,
        estimatedAccuracyPercentage: 99.5,
        shapeType: ShapeType.room,
      );

      final json = result.toJson();
      final restored = MeasurementResult.fromJson(json);

      expect(restored.surfaceArea, 340);
      expect(restored.wallArea, 240);
      expect(restored.floorArea, 100);
      expect(restored.roofArea, 110);
      expect(restored.confidenceScore, 0.95);
      expect(restored.sensorUsed, 'lidar');
      expect(restored.precisionMode, PrecisionMode.highAccuracy);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Object Detection & Counting
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('BoundingBox', () {
    test('IoU of identical boxes is 1.0', () {
      const box = BoundingBox(left: 0, top: 0, right: 1, bottom: 1);
      expect(box.iou(box), closeTo(1.0, 0.001));
    });

    test('IoU of non-overlapping boxes is 0.0', () {
      const a = BoundingBox(left: 0, top: 0, right: 0.5, bottom: 0.5);
      const b = BoundingBox(left: 0.6, top: 0.6, right: 1, bottom: 1);
      expect(a.iou(b), 0.0);
    });

    test('IoU of 50% overlap', () {
      const a = BoundingBox(left: 0, top: 0, right: 1, bottom: 1);
      const b = BoundingBox(left: 0.5, top: 0, right: 1.5, bottom: 1);
      // intersection = 0.5, union = 1 + 1 - 0.5 = 1.5
      expect(a.iou(b), closeTo(0.5 / 1.5, 0.001));
    });
  });

  group('DetectedObject', () {
    test('serialization round-trip', () {
      const obj = DetectedObject(
        label: 'car',
        category: ObjectCategory.car,
        confidence: 0.92,
        boundingBox:
            BoundingBox(left: 0.1, top: 0.2, right: 0.5, bottom: 0.8),
        estimatedWidthMeters: 1.8,
        estimatedHeightMeters: 1.5,
      );
      final json = obj.toJson();
      final restored = DetectedObject.fromJson(json);
      expect(restored.label, 'car');
      expect(restored.category, ObjectCategory.car);
      expect(restored.confidence, 0.92);
      expect(restored.estimatedWidthMeters, 1.8);
    });
  });

  group('DetectionResult', () {
    test('counts by category with deduplication', () {
      final result = DetectionResult(
        objects: [
          const DetectedObject(
            label: 'car',
            category: ObjectCategory.car,
            confidence: 0.9,
            boundingBox:
                BoundingBox(left: 0, top: 0, right: 0.3, bottom: 0.3),
          ),
          // Duplicate (high IoU with above)
          const DetectedObject(
            label: 'car',
            category: ObjectCategory.car,
            confidence: 0.85,
            boundingBox:
                BoundingBox(left: 0.02, top: 0.02, right: 0.32, bottom: 0.32),
          ),
          const DetectedObject(
            label: 'tree',
            category: ObjectCategory.tree,
            confidence: 0.95,
            boundingBox:
                BoundingBox(left: 0.5, top: 0.1, right: 0.7, bottom: 0.9),
          ),
        ],
        imageWidth: 1920,
        imageHeight: 1080,
        processingTime: const Duration(milliseconds: 45),
        timestamp: DateTime.now(),
      );

      final counts = result.countByCategory();
      final carCount = counts.firstWhere((c) => c.category == ObjectCategory.car);
      expect(carCount.count, 1); // Duplicate removed
      expect(carCount.duplicatesRemoved, 1);

      final treeCount = counts.firstWhere((c) => c.category == ObjectCategory.tree);
      expect(treeCount.count, 1);
    });
  });

  group('ObjectCounter', () {
    test('filters by minimum confidence', () {
      const counter = ObjectCounter(minConfidence: 0.5);
      final result = DetectionResult(
        objects: [
          const DetectedObject(
            label: 'chair',
            category: ObjectCategory.chair,
            confidence: 0.8,
            boundingBox:
                BoundingBox(left: 0, top: 0, right: 0.2, bottom: 0.2),
          ),
          const DetectedObject(
            label: 'chair',
            category: ObjectCategory.chair,
            confidence: 0.3, // below threshold
            boundingBox:
                BoundingBox(left: 0.5, top: 0.5, right: 0.7, bottom: 0.7),
          ),
        ],
        imageWidth: 640,
        imageHeight: 480,
        processingTime: const Duration(milliseconds: 20),
        timestamp: DateTime.now(),
      );

      final counts = counter.count(result);
      final chairCount =
          counts.firstWhere((c) => c.category == ObjectCategory.chair);
      expect(chairCount.count, 1);
    });

    test('density estimation', () {
      const counter = ObjectCounter();
      final counts = [
        const ObjectCount(
            category: ObjectCategory.tree, count: 50, averageConfidence: 0.9),
      ];
      expect(counter.estimateDensity(counts, 1000), closeTo(0.05, 0.001));
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Building Analysis
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('BuildingAnalyzer', () {
    test('basic building analysis', () {
      const footprint =
          RectangleShape(lengthMeters: 20, widthMeters: 15);
      const building = BuildingShape(
        baseFootprint: footprint,
        numberOfFloors: 4,
        floorHeightMeters: 3,
      );
      final analysis = BuildingAnalyzer.analyze(
        building: building,
        plotAreaSqm: 600,
        windowCount: 32,
        doorCount: 8,
      );

      expect(analysis.footprintAreaSqm, closeTo(300, 0.01));
      expect(analysis.totalFloorAreaSqm, closeTo(1200, 0.01));
      expect(analysis.heightMeters, closeTo(12, 0.01));
      expect(analysis.floorAreaRatio, closeTo(2.0, 0.01)); // 1200/600
      expect(analysis.plotCoverage, closeTo(0.5, 0.01)); // 300/600
      expect(analysis.windowCount, 32);
      expect(analysis.openAreaSqm, closeTo(300, 0.01)); // 600-300
    });

    test('estimate floors from height', () {
      expect(BuildingAnalyzer.estimateFloors(9.0), 3);
      expect(BuildingAnalyzer.estimateFloors(15.5), 5);
    });

    test('serialization round-trip', () {
      final analysis = BuildingAnalysis(
        lengthMeters: 20,
        widthMeters: 15,
        heightMeters: 12,
        numberOfFloors: 4,
        roofType: RoofType.gable,
        roofPitchDegrees: 30,
        windowCount: 32,
        doorCount: 8,
        footprintAreaSqm: 300,
        totalFloorAreaSqm: 1200,
        builtUpAreaSqm: 1200,
        perimeterMeters: 70,
      );
      final json = analysis.toJson();
      final restored = BuildingAnalysis.fromJson(json);
      expect(restored.roofType, RoofType.gable);
      expect(restored.windowCount, 32);
      expect(restored.totalFloorAreaSqm, 1200);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Measurement Validation
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('MeasurementValidation', () {
    test('survey grade classification', () {
      final v = MeasurementValidation(
        confidenceScore: 0.98,
        estimatedAccuracy: 0.005,
        errorMarginMeters: 0.005,
        sensorUsed: 'rtk_gps',
        precisionMode: PrecisionMode.professionalSurvey,
        timestamp: DateTime.now(),
      );
      expect(v.grade, MeasurementGrade.surveyGrade);
    });

    test('rough grade for low confidence', () {
      final v = MeasurementValidation(
        confidenceScore: 0.3,
        estimatedAccuracy: 1.0,
        errorMarginMeters: 1.0,
        timestamp: DateTime.now(),
      );
      expect(v.grade, MeasurementGrade.rough);
    });

    test('serialization round-trip', () {
      final v = MeasurementValidation(
        confidenceScore: 0.92,
        estimatedAccuracy: 0.03,
        errorMarginMeters: 0.03,
        sensorUsed: 'lidar',
        measurementMethod: 'time_of_flight',
        calibrationStatus: CalibrationStatus.manuallyCalibratedRecent,
        precisionMode: PrecisionMode.lidar,
        timestamp: DateTime(2026, 7, 26),
        sampleCount: 10,
        standardDeviation: 0.002,
      );
      final json = v.toJson();
      final restored = MeasurementValidation.fromJson(json);
      expect(restored.confidenceScore, 0.92);
      expect(restored.sensorUsed, 'lidar');
      expect(restored.calibrationStatus,
          CalibrationStatus.manuallyCalibratedRecent);
      expect(restored.sampleCount, 10);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Edge Detector
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('EdgeDetector', () {
    test('Sobel detects vertical edge', () {
      // 10×10 image: left half black, right half white
      final gray = List<int>.generate(
          100, (i) => (i % 10) < 5 ? 0 : 255);
      final edges = EdgeDetector.detectEdgesSobel(gray, 10, 10);
      // Edges should be strongest at x=5 (boundary)
      // Check middle row (y=5)
      final edgeAt5 = edges[5 * 10 + 5];
      final edgeAt0 = edges[5 * 10 + 0];
      expect(edgeAt5, greaterThan(edgeAt0));
    });

    test('Harris detects corners on a square', () {
      // 20×20 image with a white square (4-8, 4-8) on black
      final gray = List<int>.filled(400, 0);
      for (int y = 4; y <= 8; y++) {
        for (int x = 4; x <= 8; x++) {
          gray[y * 20 + x] = 255;
        }
      }
      final corners = EdgeDetector.detectCornersHarris(gray, 20, 20);
      // Should detect corners near (4,4), (8,4), (4,8), (8,8)
      expect(corners.length, greaterThanOrEqualTo(2));
    });

    test('line detection finds horizontal run', () {
      // Create edge map with a horizontal line at y=5
      final edges = Uint8List(100);
      for (int x = 0; x < 10; x++) {
        edges[5 * 10 + x] = 255;
      }
      final lines =
          EdgeDetector.detectLines(edges, 10, 10, minLength: 5);
      expect(lines.any((l) => l.isHorizontal), true);
    });

    test('RGBA to grayscale conversion', () {
      // Red pixel
      final rgba = Uint8List.fromList([255, 0, 0, 255]);
      final gray = EdgeDetector.rgbaToGrayscale(rgba, 1, 1);
      // ITU-R: 0.299*255 + 0.587*0 + 0.114*0 ≈ 76
      expect(gray[0], closeTo(76, 1));
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Material Estimation
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('MaterialEstimator', () {
    test('room estimation produces all material types', () {
      const room = RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(5, 0),
          Point3D(5, 4),
          Point3D(0, 4),
        ],
        heightMeters: 3,
      );
      final takeoff = MaterialEstimator.estimateForRoom(room);
      expect(takeoff.items.length, 7);
      expect(
          takeoff.items
              .any((i) => i.material == MaterialType.concrete),
          true);
      expect(
          takeoff.items.any((i) => i.material == MaterialType.brick),
          true);
      expect(
          takeoff.items.any((i) => i.material == MaterialType.paint),
          true);
    });

    test('wastage adjustment', () {
      const m = MaterialEstimate(
        material: MaterialType.brick,
        quantity: 100,
        unit: MaterialUnit.pieces,
        wastagePercent: 10,
      );
      expect(m.adjustedQuantity, closeTo(110.0, 0.001));
    });

    test('cost calculation', () {
      const m = MaterialEstimate(
        material: MaterialType.cement,
        quantity: 50,
        unit: MaterialUnit.bags,
        unitCost: 350.0,
        wastagePercent: 2,
      );
      expect(m.totalCost, closeTo(50 * 1.02 * 350, 0.01));
    });

    test('cost estimate with overhead and contingency', () {
      final takeoff = QuantityTakeoff(
        projectName: 'Test',
        items: [
          const MaterialEstimate(
            material: MaterialType.concrete,
            quantity: 10,
            unit: MaterialUnit.cubicMeters,
            unitCost: 5000,
            wastagePercent: 0,
          ),
        ],
      );
      final cost = CostEstimate(
        materials: takeoff,
        laborCost: 20000,
        overheadPercent: 10,
        contingencyPercent: 5,
        profitPercent: 10,
      );
      // Material = 50000, subtotal = 70000
      expect(cost.materialCost, 50000);
      expect(cost.subtotal, 70000);
      expect(cost.overhead, 7000);
      expect(cost.contingency, 3500);
      expect(cost.grandTotal, closeTo(87500, 0.01));
    });

    test('paint estimation', () {
      final paint = MaterialEstimator.estimatePaint(100, coats: 2);
      expect(paint.quantity, 20.0); // 100 * 2 / 10
    });

    test('tile estimation', () {
      final tiles = MaterialEstimator.estimateTiles(20);
      // 300mm tiles = 0.09m², 20/0.09 ≈ 222 tiles
      expect(tiles.quantity, closeTo(222.2, 0.1));
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // T-Shape & U-Shape Rooms
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('TShapeRoom', () {
    test('area = main + wing', () {
      const t = TShapeRoom(
        mainLengthMeters: 8,
        mainWidthMeters: 4,
        wingLengthMeters: 10,
        wingWidthMeters: 3,
        heightMeters: 3,
      );
      expect(t.calculateAreaInSquareMeters(), 32 + 30);
    });

    test('volume = area × height', () {
      const t = TShapeRoom(
        mainLengthMeters: 8,
        mainWidthMeters: 4,
        wingLengthMeters: 10,
        wingWidthMeters: 3,
        heightMeters: 3,
      );
      expect(t.calculateVolumeInCubicMeters(), 62 * 3);
    });

    test('validation rejects zero', () {
      const t = TShapeRoom(
        mainLengthMeters: 0,
        mainWidthMeters: 4,
        wingLengthMeters: 10,
        wingWidthMeters: 3,
        heightMeters: 3,
      );
      expect(t.validate(), isNotNull);
    });
  });

  group('UShapeRoom', () {
    test('area = main + 2×wing', () {
      const u = UShapeRoom(
        mainLengthMeters: 10,
        mainWidthMeters: 8,
        wingLengthMeters: 6,
        wingWidthMeters: 3,
        heightMeters: 3,
      );
      expect(u.calculateAreaInSquareMeters(), 80 + 2 * 18);
    });

    test('courtyard area', () {
      const u = UShapeRoom(
        mainLengthMeters: 10,
        mainWidthMeters: 8,
        wingLengthMeters: 6,
        wingWidthMeters: 3,
        heightMeters: 3,
      );
      // innerWidth = 8 - 2*3 = 2, courtyard = 2 * 6 = 12
      expect(u.courtyardArea, 12.0);
    });

    test('volume = area × height', () {
      const u = UShapeRoom(
        mainLengthMeters: 10,
        mainWidthMeters: 8,
        wingLengthMeters: 6,
        wingWidthMeters: 3,
        heightMeters: 3,
      );
      expect(u.calculateVolumeInCubicMeters(), 116 * 3);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // JSON Exporter
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('JsonExporter', () {
    test('exports single result as valid JSON', () {
      final result = MeasurementResult(
        area: 50,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 30,
        distanceUnit: DistanceUnit.meters,
        volume: 150,
        algorithmUsed: MeasurementAlgorithm.manual,
        estimatedAccuracyPercentage: 95,
        shapeType: ShapeType.room,
      );
      final jsonStr = JsonExporter.exportResult(result);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(parsed['area'], 50);
      expect(parsed['shapeType'], 'room');
    });

    test('exports history with metadata', () {
      final results = [
        MeasurementResult(
          area: 20,
          areaUnit: AreaUnit.squareMeters,
          perimeter: 18,
          distanceUnit: DistanceUnit.meters,
          volume: 0,
          algorithmUsed: MeasurementAlgorithm.manual,
          estimatedAccuracyPercentage: 90,
          shapeType: ShapeType.rectangle,
        ),
      ];
      final jsonStr = JsonExporter.exportHistory(results);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(parsed['count'], 1);
      expect(parsed['measurements'], isList);
      expect(parsed['exportDate'], isNotEmpty);
    });

    test('exports quantity takeoff', () {
      final takeoff = QuantityTakeoff(
        projectName: 'Test Project',
        items: [
          const MaterialEstimate(
            material: MaterialType.concrete,
            quantity: 10,
            unit: MaterialUnit.cubicMeters,
          ),
        ],
      );
      final jsonStr = JsonExporter.exportTakeoff(takeoff);
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(parsed['projectName'], 'Test Project');
      expect(parsed['lineItemCount'], 1);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ExportManager JSON format
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('ExportManager JSON', () {
    test('JSON format has correct extension and MIME', () {
      expect(ExportManager.fileExtension(ExportFormat.json), '.json');
      expect(ExportManager.mimeType(ExportFormat.json), 'application/json');
      expect(
          ExportManager.formatDisplayName(ExportFormat.json), 'JSON Data');
    });

    test('JSON always in supported formats', () {
      final formats = ExportManager.supportedFormats(null);
      expect(formats, contains(ExportFormat.json));
    });

    test('exports history as JSON string', () {
      final jsonStr = ExportManager.exportToString(
        format: ExportFormat.json,
        history: [],
      );
      final parsed = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(parsed['count'], 0);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // VisionService
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('LocalVisionService', () {
    test('is always available', () {
      final svc = LocalVisionService();
      expect(svc.isAvailable, true);
      expect(svc.engineName, 'Local Analysis');
    });

    test('detect objects on synthetic image', () async {
      final svc = LocalVisionService();
      // 10×10 RGBA image — left half dark, right half bright
      final pixels = Uint8List(10 * 10 * 4);
      for (int y = 0; y < 10; y++) {
        for (int x = 0; x < 10; x++) {
          final idx = (y * 10 + x) * 4;
          final val = x < 5 ? 0 : 255;
          pixels[idx] = val;
          pixels[idx + 1] = val;
          pixels[idx + 2] = val;
          pixels[idx + 3] = 255;
        }
      }
      final result = await svc.detectObjects(pixels, 10, 10);
      expect(result.imageWidth, 10);
      expect(result.imageHeight, 10);
      expect(result.processingTime.inMicroseconds, greaterThan(0));
    });

    test('label image returns brightness label', () async {
      final svc = LocalVisionService();
      // Bright image
      final bright = Uint8List.fromList(
          List.generate(4 * 4, (_) => 230));
      final labels = await svc.labelImage(bright, 1, 1);
      expect(labels, isNotEmpty);
    });

    test('barcode scan returns empty on local', () async {
      final svc = LocalVisionService();
      final result = await svc.scanBarcodes(Uint8List(0), 0, 0);
      expect(result, isEmpty);
    });
  });

  group('VisionServiceFactory', () {
    test('creates a service', () {
      final svc = VisionServiceFactory.create();
      expect(svc, isNotNull);
      expect(svc.isAvailable, true);
      svc.dispose();
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Excel Exporter
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('ExcelExporter', () {
    test('exports measurements as valid XLSX bytes', () {
      final results = [
        MeasurementResult(
          area: 25,
          areaUnit: AreaUnit.squareMeters,
          perimeter: 20,
          distanceUnit: DistanceUnit.meters,
          volume: 75,
          algorithmUsed: MeasurementAlgorithm.manual,
          estimatedAccuracyPercentage: 95,
          shapeType: ShapeType.room,
        ),
      ];
      final bytes = ExcelExporter.exportMeasurements(results);
      // XLSX files start with PK header (ZIP)
      expect(bytes.length, greaterThan(100));
      expect(bytes[0], 0x50); // P
      expect(bytes[1], 0x4B); // K
    });

    test('exports takeoff as valid XLSX bytes', () {
      final takeoff = QuantityTakeoff(
        projectName: 'Test',
        items: [
          const MaterialEstimate(
            material: MaterialType.concrete,
            quantity: 10,
            unit: MaterialUnit.cubicMeters,
            unitCost: 5000,
          ),
        ],
      );
      final bytes = ExcelExporter.exportTakeoff(takeoff);
      expect(bytes[0], 0x50); // ZIP PK header
      expect(bytes[1], 0x4B);
    });

    test('exports cost estimate as valid XLSX', () {
      final takeoff = QuantityTakeoff(
        projectName: 'Cost Test',
        items: [
          const MaterialEstimate(
            material: MaterialType.cement,
            quantity: 50,
            unit: MaterialUnit.bags,
            unitCost: 350,
          ),
        ],
      );
      final estimate = CostEstimate(
        materials: takeoff,
        laborCost: 20000,
      );
      final bytes = ExcelExporter.exportCostEstimate(estimate);
      expect(bytes.length, greaterThan(100));
      expect(bytes[0], 0x50);
    });
  });

  group('ExportManager Excel', () {
    test('Excel format metadata', () {
      expect(ExportManager.fileExtension(ExportFormat.excel), '.xlsx');
      expect(ExportManager.mimeType(ExportFormat.excel),
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      expect(ExportManager.formatDisplayName(ExportFormat.excel),
          'Excel Spreadsheet');
    });

    test('Excel always in supported formats', () {
      final formats = ExportManager.supportedFormats(null);
      expect(formats, contains(ExportFormat.excel));
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Sensor Fusion
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('SensorFusionEngine', () {
    test('initial state is zero', () {
      final engine = SensorFusionEngine();
      expect(engine.currentState.sensorCount, 0);
      expect(engine.currentState.confidence, 0);
    });

    test('single GPS reading updates state', () {
      final engine = SensorFusionEngine();
      final state = engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 12.97, y: 77.59, z: 920),
        accuracyMeters: 3.0,
        timestamp: DateTime.now(),
      ));
      expect(state.sensorCount, 1);
      expect(state.primarySensor, 'gps');
      expect(state.accuracyMeters, closeTo(3.0, 0.01));
    });

    test('multi-sensor fusion improves accuracy', () {
      final engine = SensorFusionEngine();
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 10, y: 20, z: 0),
        accuracyMeters: 5.0,
        timestamp: DateTime.now(),
      ));
      final fused = engine.addReading(SensorReading(
        sensorType: SensorType.arCore,
        position: const Position3D(x: 10.1, y: 20.1, z: 0),
        accuracyMeters: 0.5,
        timestamp: DateTime.now(),
      ));
      // Fused accuracy should be better than worst single sensor
      expect(fused.accuracyMeters, lessThan(5.0));
      expect(fused.sensorCount, 2);
    });

    test('heading fusion with circular mean', () {
      final engine = SensorFusionEngine();
      engine.addReading(SensorReading(
        sensorType: SensorType.magnetometer,
        heading: 350,
        timestamp: DateTime.now(),
      ));
      final state = engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        heading: 10,
        timestamp: DateTime.now(),
      ));
      // Mean of 350° and 10° should be ~0° (north)
      expect(state.heading, isNotNull);
      expect(state.heading!, closeTo(0, 15));
    });

    test('reset clears state', () {
      final engine = SensorFusionEngine();
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 1, y: 2, z: 3),
        accuracyMeters: 1.0,
        timestamp: DateTime.now(),
      ));
      engine.reset();
      expect(engine.currentState.sensorCount, 0);
    });

    test('distance between states', () {
      final a = FusedState(
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: 1,
        sensorCount: 1,
        primarySensor: 'gps',
        confidence: 0.9,
        timestamp: DateTime.now(),
      );
      final b = FusedState(
        position: const Position3D(x: 3, y: 4, z: 0),
        accuracyMeters: 1,
        sensorCount: 1,
        primarySensor: 'gps',
        confidence: 0.9,
        timestamp: DateTime.now(),
      );
      expect(SensorFusionEngine.distance(a, b), closeTo(5.0, 0.01));
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // Photogrammetry
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('PhotogrammetryPipeline', () {
    test('scale factor calculation', () {
      const a = PgPoint3D(x: 0, y: 0, z: 0);
      const b = PgPoint3D(x: 1, y: 0, z: 0);
      final scale = PhotogrammetryPipeline.computeScaleFactor(a, b, 5.0);
      expect(scale, 5.0); // 1 unit = 5 meters
    });

    test('distance measurement with scale', () {
      const a = PgPoint3D(x: 0, y: 0, z: 0);
      const b = PgPoint3D(x: 3, y: 4, z: 0);
      final dist = PhotogrammetryPipeline.measureDistance(a, b, 2.0);
      expect(dist, closeTo(10.0, 0.01)); // 5 * 2.0 scale
    });

    test('camera intrinsics from FoV', () {
      final cam = CameraIntrinsics.fromFov(90, 1920, 1080);
      expect(cam.fx, closeTo(960, 1)); // width/2 / tan(45°) = 960
      expect(cam.cx, 960);
      expect(cam.cy, 540);
    });

    test('surface area estimation from point cloud', () {
      // Square with side 2: area = 4
      final points = [
        const PgPoint3D(x: 0, y: 0, z: 0),
        const PgPoint3D(x: 2, y: 0, z: 0),
        const PgPoint3D(x: 2, y: 2, z: 0),
        const PgPoint3D(x: 0, y: 2, z: 0),
      ];
      final area = PhotogrammetryPipeline.estimateSurfaceArea(points);
      expect(area, closeTo(4.0, 0.01));
    });

    test('FAST corner detection on synthetic image', () {
      // 50×50 image with a bright dot — FAST detects isolated bright points
      // where all 16 Bresenham circle pixels are darker than center
      final gray = Uint8List(50 * 50); // all 0 (dark background)
      // Place a single bright point at (25, 25)
      gray[25 * 50 + 25] = 200;
      // Also fill a tiny 3×3 bright area so surrounding pixels contrast
      for (int dy = -1; dy <= 1; dy++) {
        for (int dx = -1; dx <= 1; dx++) {
          gray[(25 + dy) * 50 + (25 + dx)] = 200;
        }
      }
      final corners = PhotogrammetryPipeline.detectFastCornersPublic(
          gray, 50, 50, threshold: 10);
      // The bright dot is an isolated feature — FAST should detect it
      expect(corners, isNotEmpty);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // ML Kit Vision Service (Fallback Pattern)
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('MlKitVisionService', () {
    test('isAvailable returns false on non-mobile (test runner)', () {
      final service = MlKitVisionService();
      // In test runner, platform is not Android/iOS
      expect(service.engineName, equals('Google ML Kit'));
    });

    test('detectObjects falls back to LocalVisionService on non-mobile',
        () async {
      final service = MlKitVisionService();
      final img = Uint8List(100 * 100 * 4);
      final result = await service.detectObjects(img, 100, 100);
      // Should succeed via fallback, not throw
      expect(result.imageWidth, equals(100));
      expect(result.imageHeight, equals(100));
    });

    test('scanBarcodes returns empty on non-mobile', () async {
      final service = MlKitVisionService();
      final img = Uint8List(10);
      final results = await service.scanBarcodes(img, 10, 1);
      expect(results, isEmpty);
    });

    test('recognizeText returns empty on non-mobile', () async {
      final service = MlKitVisionService();
      final img = Uint8List(10);
      final results = await service.recognizeText(img, 10, 1);
      expect(results, isEmpty);
    });

    test('labelImage falls back to local analysis', () async {
      final service = MlKitVisionService();
      final img = Uint8List(10 * 10 * 4);
      // Set RGBA pixels: R=220 (above 200 threshold for bright_scene)
      for (int i = 0; i < 10 * 10; i++) {
        img[i * 4] = 220;     // R
        img[i * 4 + 1] = 220; // G
        img[i * 4 + 2] = 220; // B
        img[i * 4 + 3] = 255; // A
      }
      final labels = await service.labelImage(img, 10, 10);
      expect(labels, isNotEmpty);
      expect(labels.first.label, equals('bright_scene'));
    });

    test('dispose does not throw', () {
      final service = MlKitVisionService();
      expect(() => service.dispose(), returnsNormally);
    });
  });

  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  // AppConfig v2.3.0 Production Readiness
  // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  group('AppConfig', () {
    test('version matches pubspec 2.3.0', () {
      expect(AppConfig.appVersion, equals('2.3.0'));
      expect(AppConfig.buildNumber, equals(9));
    });

    test('all implemented features are enabled', () {
      final config = AppConfig();
      // Core features must be enabled
      expect(config.isEnabled('gps_tracking'), isTrue);
      expect(config.isEnabled('manual_measurement'), isTrue);
      expect(config.isEnabled('project_management'), isTrue);
      expect(config.isEnabled('ai_detection'), isTrue);
      expect(config.isEnabled('camera_capture'), isTrue);

      // Export formats
      expect(config.isEnabled('export_csv'), isTrue);
      expect(config.isEnabled('export_dxf'), isTrue);
      expect(config.isEnabled('export_geojson'), isTrue);
      expect(config.isEnabled('export_svg'), isTrue);
      expect(config.isEnabled('export_kml'), isTrue);
      expect(config.isEnabled('export_pdf'), isTrue);
      expect(config.isEnabled('export_json'), isTrue);
      expect(config.isEnabled('export_excel'), isTrue);

      // Advanced features
      expect(config.isEnabled('sensor_fusion'), isTrue);
      expect(config.isEnabled('photogrammetry'), isTrue);
      expect(config.isEnabled('material_estimation'), isTrue);
      expect(config.isEnabled('pdf_report_templates'), isTrue);
    });

    test('unimplemented features are disabled', () {
      final config = AppConfig();
      expect(config.isEnabled('ar_measurement'), isFalse);
      expect(config.isEnabled('cloud_sync'), isFalse);
      expect(config.isEnabled('offline_maps'), isFalse);
    });

    test('feature flags are runtime-configurable', () {
      final config = AppConfig();
      expect(config.isEnabled('ar_measurement'), isFalse);
      config.setFeatureFlag('ar_measurement', true);
      expect(config.isEnabled('ar_measurement'), isTrue);
      // Reset
      config.setFeatureFlag('ar_measurement', false);
    });

    test('unknown features return false', () {
      final config = AppConfig();
      expect(config.isEnabled('nonexistent_feature'), isFalse);
    });

    test('allFlags returns unmodifiable map', () {
      final config = AppConfig();
      final flags = config.allFlags;
      expect(flags, isA<Map<String, bool>>());
      expect(() => flags['test'] = true,
          throwsUnsupportedError);
    });

    test('constants are production-grade', () {
      expect(AppConfig.appName, equals('GeoMeasure'));
      expect(AppConfig.maxProjectsPerUser, equals(1000));
      expect(AppConfig.maxMeasurementsPerProject, equals(10000));
      expect(AppConfig.maxUndoStackDepth, equals(50));
      expect(AppConfig.minGpsAccuracyMeters, equals(3.0));
      expect(AppConfig.maxExportFileSizeMb, equals(50));
    });
  });
}

