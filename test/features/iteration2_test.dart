import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/angle_calculator.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/svg_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/kml_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/unit_converter.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';
import 'package:geomeasure/core/commands/command.dart';
import 'package:geomeasure/core/config/app_config.dart';
import 'package:geomeasure/core/logging/app_logger.dart';
import 'package:geomeasure/features/project_management/domain/entities/project.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'dart:math';

void main() {
  // ━━━ New Shapes ━━━
  group('SquareShape', () {
    test('area and perimeter', () {
      const sq = SquareShape(sideMeters: 5.0);
      expect(sq.calculateAreaInSquareMeters(), 25.0);
      expect(sq.calculatePerimeterInMeters(), 20.0);
      expect(sq.validate(), isNull);
    });

    test('rejects zero side', () {
      const sq = SquareShape(sideMeters: 0);
      expect(sq.validate(), isNotNull);
    });
  });

  group('EllipseShape', () {
    test('area and perimeter', () {
      const e = EllipseShape(semiMajorMeters: 5, semiMinorMeters: 3);
      expect(e.calculateAreaInSquareMeters(), closeTo(pi * 15, 0.001));
      expect(e.calculatePerimeterInMeters(), greaterThan(20));
      expect(e.validate(), isNull);
    });

    test('rejects negative axis', () {
      const e = EllipseShape(semiMajorMeters: -1, semiMinorMeters: 3);
      expect(e.validate(), isNotNull);
    });
  });

  group('TrapezoidShape', () {
    test('area calculation', () {
      const t = TrapezoidShape(
        parallelSideA: 10,
        parallelSideB: 6,
        heightMeters: 4,
      );
      expect(t.calculateAreaInSquareMeters(), 32.0);
      expect(t.calculatePerimeterInMeters(), greaterThan(20));
    });

    test('rejects zero height', () {
      const t = TrapezoidShape(
        parallelSideA: 10,
        parallelSideB: 6,
        heightMeters: 0,
      );
      expect(t.validate(), isNotNull);
    });
  });

  group('CorridorShape', () {
    test('area, perimeter, and volume', () {
      const c = CorridorShape(
        lengthMeters: 10,
        widthMeters: 1.5,
        heightMeters: 2.5,
      );
      expect(c.calculateAreaInSquareMeters(), 15.0);
      expect(c.calculatePerimeterInMeters(), 23.0);
      expect(c.calculateVolumeInCubicMeters(), 37.5);
      expect(c.calculateWallSurfaceArea(), 57.5);
    });
  });

  // ━━━ Angle Calculator ━━━
  group('AngleCalculator', () {
    test('right angle between perpendicular vectors', () {
      final angle = AngleCalculator.angleBetweenPoints(
        const Point3D(1, 0),
        const Point3D(0, 0),
        const Point3D(0, 1),
      );
      expect(angle, closeTo(90.0, 0.01));
    });

    test('slope angle for 45-degree incline', () {
      final slope = AngleCalculator.slopeAngle(
        const Point3D(0, 0, 0),
        const Point3D(10, 0, 10),
      );
      expect(slope, closeTo(45.0, 0.01));
    });

    test('bearing north is 0°', () {
      final b = AngleCalculator.bearing(
        const Point3D(0, 0),
        const Point3D(0, 10),
      );
      expect(b, closeTo(0.0, 0.01));
    });

    test('bearing east is 90°', () {
      final b = AngleCalculator.bearing(
        const Point3D(0, 0),
        const Point3D(10, 0),
      );
      expect(b, closeTo(90.0, 0.01));
    });

    test('polygon interior angles of a square sum to 360°', () {
      final angles = AngleCalculator.polygonInteriorAngles([
        const Point3D(0, 0),
        const Point3D(1, 0),
        const Point3D(1, 1),
        const Point3D(0, 1),
      ]);
      expect(angles.length, 4);
      final sum = angles.fold(0.0, (s, a) => s + a);
      expect(sum, closeTo(360.0, 0.1));
    });
  });

  // ━━━ SVG Exporter ━━━
  group('SvgExporter', () {
    test('generates valid SVG for rectangle', () {
      const rect = RectangleShape(lengthMeters: 5, widthMeters: 3);
      final svg = SvgExporter.generateSvg(rect);
      expect(svg, contains('<svg'));
      expect(svg, contains('<rect'));
      expect(svg, contains('</svg>'));
    });

    test('generates valid SVG for circle', () {
      const c = CircleShape(radiusMeters: 4);
      final svg = SvgExporter.generateSvg(c);
      expect(svg, contains('<circle'));
    });

    test('generates valid SVG for polygon', () {
      const poly = IrregularPolygonShape(vertices: [
        Point3D(0, 0),
        Point3D(5, 0),
        Point3D(5, 3),
      ]);
      final svg = SvgExporter.generateSvg(poly);
      expect(svg, contains('<polygon'));
    });
  });

  // ━━━ KML Exporter ━━━
  group('KmlExporter', () {
    test('generates valid KML for plot', () {
      const plot = PlotShape(coordinates: [
        GpsCoordinate(latitude: 37.7749, longitude: -122.4194),
        GpsCoordinate(latitude: 37.7755, longitude: -122.4194),
        GpsCoordinate(latitude: 37.7755, longitude: -122.4185),
      ]);
      final kml = KmlExporter.generateKml(plot);
      expect(kml, contains('<?xml'));
      expect(kml, contains('<kml'));
      expect(kml, contains('<Polygon>'));
      expect(kml, contains('<coordinates>'));
    });

    test('generates waypoint KML', () {
      final kml = KmlExporter.generateWaypointKml([
        const GpsCoordinate(latitude: 37.77, longitude: -122.41),
        const GpsCoordinate(latitude: 37.78, longitude: -122.42),
      ]);
      expect(kml, contains('<LineString>'));
      expect(kml, contains('Point 1'));
      expect(kml, contains('Point 2'));
    });
  });

  // ━━━ Regional Unit Conversion ━━━
  group('UnitConverter — Regional Units', () {
    test('sq meters to bigha', () {
      final result = UnitConverter.convertArea(
        valueSqMeters: 2529.29,
        targetUnit: AreaUnit.bigha,
      );
      expect(result, closeTo(1.0, 0.01));
    });

    test('sq meters to kanal', () {
      final result = UnitConverter.convertArea(
        valueSqMeters: 505.857,
        targetUnit: AreaUnit.kanal,
      );
      expect(result, closeTo(1.0, 0.01));
    });

    test('sq meters to marla', () {
      final result = UnitConverter.convertArea(
        valueSqMeters: 25.2929,
        targetUnit: AreaUnit.marla,
      );
      expect(result, closeTo(1.0, 0.01));
    });

    test('meters to centimeters', () {
      final result = UnitConverter.convertDistance(
        valueMeters: 1.0,
        targetUnit: DistanceUnit.centimeters,
      );
      expect(result, 100.0);
    });

    test('meters to kilometers', () {
      final result = UnitConverter.convertDistance(
        valueMeters: 1000.0,
        targetUnit: DistanceUnit.kilometers,
      );
      expect(result, 1.0);
    });

    test('unit labels are non-empty', () {
      for (final u in AreaUnit.values) {
        expect(UnitConverter.areaUnitLabel(u), isNotEmpty);
      }
      for (final u in DistanceUnit.values) {
        expect(UnitConverter.distanceUnitLabel(u), isNotEmpty);
      }
    });
  });

  // ━━━ Undo/Redo ━━━
  group('CommandManager', () {
    test('execute, undo, redo', () {
      final manager = CommandManager();
      int value = 0;

      final cmd = _TestCommand(
        desc: 'increment',
        doAction: () => value++,
        undoAction: () => value--,
      );

      manager.execute(cmd);
      expect(value, 1);
      expect(manager.canUndo, true);
      expect(manager.canRedo, false);

      manager.undo();
      expect(value, 0);
      expect(manager.canUndo, false);
      expect(manager.canRedo, true);

      manager.redo();
      expect(value, 1);
    });

    test('respects max stack depth', () {
      final manager = CommandManager(maxStackDepth: 3);
      int counter = 0;

      for (int i = 0; i < 5; i++) {
        manager.execute(_TestCommand(
          desc: 'cmd $i',
          doAction: () => counter++,
          undoAction: () => counter--,
        ));
      }

      expect(counter, 5);
      expect(manager.undoCount, 3); // oldest 2 pruned
    });
  });

  // ━━━ Feature Flags ━━━
  group('AppConfig', () {
    test('feature flags default values', () {
      final config = AppConfig();
      expect(config.isEnabled('manual_measurement'), true);
      expect(config.isEnabled('ar_measurement'), false);
      expect(config.isEnabled('project_management'), true);
    });

    test('can toggle feature flags', () {
      final config = AppConfig();
      config.setFeatureFlag('ar_measurement', true);
      expect(config.isEnabled('ar_measurement'), true);
      config.setFeatureFlag('ar_measurement', false);
      expect(config.isEnabled('ar_measurement'), false);
    });
  });

  // ━━━ Logger ━━━
  group('AppLogger', () {
    test('buffers log entries', () {
      final log = AppLogger();
      log.clear();
      log.info('test message', tag: 'TEST');
      final recent = log.getRecentLogs();
      expect(recent, isNotEmpty);
      expect(recent.last.message, 'test message');
      expect(recent.last.tag, 'TEST');
    });
  });

  // ━━━ Project ━━━
  group('Project', () {
    test('serialization round-trip', () {
      final project = Project(
        id: 'test-id',
        name: 'Test Project',
        description: 'A test project',
        tags: ['indoor', 'survey'],
        type: ProjectType.room,
      );

      final json = project.toJson();
      final restored = Project.fromJson(json);

      expect(restored.id, project.id);
      expect(restored.name, project.name);
      expect(restored.description, project.description);
      expect(restored.tags, project.tags);
      expect(restored.type, project.type);
    });

    test('totalArea sums measurements', () {
      final result1 = MeasurementResult(
        area: 25.0,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 20.0,
        distanceUnit: DistanceUnit.meters,
        volume: 0,
        algorithmUsed: MeasurementAlgorithm.manual,
        estimatedAccuracyPercentage: 100,
        shapeType: ShapeType.rectangle,
      );
      final result2 = MeasurementResult(
        area: 15.0,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 16.0,
        distanceUnit: DistanceUnit.meters,
        volume: 0,
        algorithmUsed: MeasurementAlgorithm.manual,
        estimatedAccuracyPercentage: 100,
        shapeType: ShapeType.rectangle,
      );

      final project = Project(
        id: 'p1',
        name: 'Multi Room',
        measurements: [result1, result2],
      );

      expect(project.totalArea, 40.0);
      expect(project.measurementCount, 2);
    });

    test('copyWith updates fields', () {
      final original = Project(id: 'p1', name: 'Original');
      final updated = original.copyWith(name: 'Updated', folder: 'Work');
      expect(updated.id, 'p1');
      expect(updated.name, 'Updated');
      expect(updated.folder, 'Work');
    });
  });
}

/// Test helper for Command pattern tests.
class _TestCommand extends Command {
  final VoidCallback doAction;
  final VoidCallback undoAction;

  _TestCommand({
    required String desc,
    required this.doAction,
    required this.undoAction,
  }) : super(description: desc);

  @override
  void execute() => doAction();

  @override
  void undo() => undoAction();
}

typedef VoidCallback = void Function();
