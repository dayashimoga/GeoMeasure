import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/visualization/domain/services/polygon_editor.dart';
import 'package:geomeasure/features/project_management/domain/entities/project_version_history.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';
import 'package:geomeasure/core/export/report_templates.dart';
import 'package:geomeasure/core/data/backup_service.dart';

void main() {
  // ━━━ Polygon Editor ━━━
  group('PolygonEditor', () {
    late PolygonEditor editor;

    setUp(() {
      editor = PolygonEditor([
        const Point3D(0, 0, 0),
        const Point3D(5, 0, 0),
        const Point3D(5, 4, 0),
        const Point3D(0, 4, 0),
      ]);
    });

    test('initializes with correct vertex count', () {
      expect(editor.vertexCount, equals(4));
    });

    test('appendVertex increases count', () {
      editor.appendVertex(const Point3D(2.5, 6, 0));
      expect(editor.vertexCount, equals(5));
    });

    test('addVertex inserts at correct index', () {
      editor.addVertex(2, const Point3D(5, 2, 0));
      expect(editor.vertexCount, equals(5));
      expect(editor.vertices[2].y, equals(2));
    });

    test('deleteVertex removes vertex and enforces minimum 3', () {
      editor.deleteVertex(0);
      expect(editor.vertexCount, equals(3));
      expect(() => editor.deleteVertex(0), throwsStateError);
    });

    test('moveVertex updates position', () {
      editor.moveVertex(1, const Point3D(6, 1, 0));
      expect(editor.vertices[1].x, equals(6));
      expect(editor.vertices[1].y, equals(1));
    });

    test('splitEdge inserts midpoint', () {
      editor.splitEdge(0); // between (0,0) and (5,0)
      expect(editor.vertexCount, equals(5));
      expect(editor.vertices[1].x, equals(2.5));
      expect(editor.vertices[1].y, equals(0));
    });

    test('undo reverts last operation', () {
      editor.appendVertex(const Point3D(1, 1, 0));
      expect(editor.vertexCount, equals(5));
      editor.undo();
      expect(editor.vertexCount, equals(4));
    });

    test('redo re-applies undone operation', () {
      editor.appendVertex(const Point3D(1, 1, 0));
      editor.undo();
      editor.redo();
      expect(editor.vertexCount, equals(5));
    });

    test('canUndo/canRedo reflect state', () {
      expect(editor.canUndo, isFalse);
      expect(editor.canRedo, isFalse);
      editor.appendVertex(const Point3D(1, 1, 0));
      expect(editor.canUndo, isTrue);
      editor.undo();
      expect(editor.canRedo, isTrue);
    });

    test('scale changes vertex positions proportionally', () {
      final before = editor.vertices[1].x;
      editor.scale(2.0);
      // After scaling by 2 from centroid, vertex should move further
      expect(editor.vertices[1].x, isNot(equals(before)));
    });

    test('snapAll rounds vertices to grid', () {
      editor.moveVertex(0, const Point3D(0.123, 0.456, 0));
      editor.snapAll(0.1);
      expect(editor.vertices[0].x, closeTo(0.1, 0.001));
      expect(editor.vertices[0].y, closeTo(0.5, 0.001));
    });

    test('centroid calculates polygon center', () {
      final c = editor.centroid;
      expect(c.x, closeTo(2.5, 0.001));
      expect(c.y, closeTo(2.0, 0.001));
    });

    test('deleteVertex throws RangeError for invalid index', () {
      expect(() => editor.deleteVertex(-1), throwsRangeError);
      expect(() => editor.deleteVertex(10), throwsRangeError);
    });

    test('addVertex throws RangeError for invalid index', () {
      expect(() => editor.addVertex(-1, const Point3D(0, 0, 0)),
          throwsRangeError);
    });
  });

  // ━━━ Project Version History ━━━
  group('ProjectVersionHistory', () {
    late ProjectVersionHistory history;

    setUp(() {
      history = ProjectVersionHistory();
    });

    test('starts empty', () {
      expect(history.isEmpty, isTrue);
      expect(history.count, equals(0));
      expect(history.latest, isNull);
    });

    test('addSnapshot increments version', () {
      history.addSnapshot(
        projectId: 'p1',
        data: {'name': 'v1'},
        changeDescription: 'Initial',
      );
      expect(history.count, equals(1));
      expect(history.latest!.version, equals(1));
      expect(history.latest!.changeDescription, equals('Initial'));
    });

    test('multiple snapshots track versions correctly', () {
      history.addSnapshot(projectId: 'p1', data: {'name': 'v1'});
      history.addSnapshot(projectId: 'p1', data: {'name': 'v2'});
      history.addSnapshot(projectId: 'p1', data: {'name': 'v3'});
      expect(history.count, equals(3));
      expect(history.getVersion(1)!.data['name'], equals('v1'));
      expect(history.getVersion(3)!.data['name'], equals('v3'));
    });

    test('getVersion returns null for invalid version', () {
      expect(history.getVersion(0), isNull);
      expect(history.getVersion(99), isNull);
    });

    test('diffKeys identifies changed fields', () {
      history.addSnapshot(projectId: 'p1', data: {'name': 'A', 'area': 10});
      history.addSnapshot(projectId: 'p1', data: {'name': 'B', 'area': 10});
      final diff = history.diffKeys(1, 2);
      expect(diff, contains('name'));
      expect(diff, isNot(contains('area')));
    });

    test('toJson and loadFromJson round-trips', () {
      history.addSnapshot(projectId: 'p1', data: {'x': 1});
      history.addSnapshot(projectId: 'p1', data: {'x': 2});
      final json = history.toJson();

      final restored = ProjectVersionHistory();
      restored.loadFromJson(json);
      expect(restored.count, equals(2));
      expect(restored.getVersion(2)!.data['x'], equals(2));
    });
  });

  // ━━━ Failure / Edge Case Tests ━━━
  group('Failure & Edge Cases', () {
    test('GeodeticCalculator: empty polygon area is 0', () {
      expect(GeodeticCalculator.calculatePolygonAreaGeodetic([]), equals(0.0));
    });

    test('GeodeticCalculator: 2-point polygon area is 0', () {
      final pts = [
        GpsCoordinate(latitude: 0, longitude: 0),
        GpsCoordinate(latitude: 1, longitude: 1),
      ];
      expect(GeodeticCalculator.calculatePolygonAreaGeodetic(pts), equals(0.0));
    });

    test('GeodeticCalculator: same point distance is 0', () {
      final p = GpsCoordinate(latitude: 12.0, longitude: 77.0);
      expect(GeodeticCalculator.calculateDistanceHaversine(p, p), equals(0.0));
    });

    test('GeodeticCalculator: elevation gain all descending is 0', () {
      final path = [
        GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 300),
        GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 200),
        GpsCoordinate(latitude: 0, longitude: 0, altitudeMeters: 100),
      ];
      expect(GeodeticCalculator.calculateElevationGain(path), equals(0.0));
    });

    test('InspectionReport empty items: passRate is 0', () {
      final report = InspectionReport(siteName: 'Empty');
      expect(report.passRate, equals(0.0));
      expect(report.passCount, equals(0));
    });

    test('InventoryReport empty items: totals are 0', () {
      final report = InventoryReport(siteName: 'Empty');
      expect(report.totalItemCount, equals(0));
      expect(report.totalVolumeM3, equals(0.0));
    });

    test('BackupResult default itemCount is 0', () {
      const result = BackupResult(success: false, message: 'err');
      expect(result.itemCount, equals(0));
    });

    test('ProjectSnapshot fromJson round-trips', () {
      final snap = ProjectSnapshot(
        version: 1,
        projectId: 'p1',
        data: {'key': 'value'},
        changeDescription: 'test',
        timestamp: DateTime(2026, 7, 28),
      );
      final json = snap.toJson();
      final restored = ProjectSnapshot.fromJson(json);
      expect(restored.version, equals(1));
      expect(restored.projectId, equals('p1'));
      expect(restored.data['key'], equals('value'));
    });
  });
}
