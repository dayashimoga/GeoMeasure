import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/core/security/certificate_pinning.dart';
import 'package:geomeasure/features/visualization/domain/services/polygon_editor.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/unit_converter.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';

void main() {
  // ━━━ Certificate Pinning ━━━
  group('CertificatePinning', () {
    setUp(() => CertificatePinning.clearAll());

    test('pinCertificate registers domain', () {
      CertificatePinning.pinCertificate('api.example.com', ['abc123']);
      expect(CertificatePinning.isPinned('api.example.com'), isTrue);
      expect(CertificatePinning.pinnedDomains, contains('api.example.com'));
    });

    test('unpinCertificate removes domain', () {
      CertificatePinning.pinCertificate('api.example.com', ['abc123']);
      CertificatePinning.unpinCertificate('api.example.com');
      expect(CertificatePinning.isPinned('api.example.com'), isFalse);
    });

    test('clearAll removes all pins', () {
      CertificatePinning.pinCertificate('a.com', ['x']);
      CertificatePinning.pinCertificate('b.com', ['y']);
      CertificatePinning.clearAll();
      expect(CertificatePinning.pinnedDomains, isEmpty);
    });

    test('isPinned returns false for unknown domain', () {
      expect(CertificatePinning.isPinned('unknown.com'), isFalse);
    });

    test('multiple pins per domain', () {
      CertificatePinning.pinCertificate('api.com', ['hash1', 'hash2']);
      expect(CertificatePinning.isPinned('api.com'), isTrue);
    });
  });

  // ━━━ SecurityAudit ━━━
  group('SecurityAudit', () {
    test('runChecks returns complete map', () {
      final checks = SecurityAudit.runChecks();
      expect(checks.containsKey('secure_storage'), isTrue);
      expect(checks.containsKey('certificate_pinning'), isTrue);
      expect(checks.containsKey('input_validation'), isTrue);
      expect(checks.containsKey('error_handling'), isTrue);
    });

    test('complianceScore is between 0 and 100', () {
      final score = SecurityAudit.complianceScore;
      expect(score, greaterThanOrEqualTo(0));
      expect(score, lessThanOrEqualTo(100));
    });

    test('pinning increases compliance score', () {
      CertificatePinning.clearAll();
      final before = SecurityAudit.complianceScore;
      CertificatePinning.pinCertificate('api.com', ['hash']);
      final after = SecurityAudit.complianceScore;
      expect(after, greaterThanOrEqualTo(before));
      CertificatePinning.clearAll();
    });
  });

  // ━━━ Polygon Editor Edge Cases ━━━
  group('PolygonEditor — advanced operations', () {
    test('rotate 360 returns near-original positions', () {
      final editor = PolygonEditor([
        const Point3D(0, 0, 0),
        const Point3D(1, 0, 0),
        const Point3D(1, 1, 0),
        const Point3D(0, 1, 0),
      ]);
      final before = editor.vertices.toList();
      editor.rotate(360);
      for (int i = 0; i < before.length; i++) {
        expect(editor.vertices[i].x, closeTo(before[i].x, 0.01));
        expect(editor.vertices[i].y, closeTo(before[i].y, 0.01));
      }
    });

    test('scale by 1.0 preserves positions', () {
      final editor = PolygonEditor([
        const Point3D(0, 0, 0),
        const Point3D(2, 0, 0),
        const Point3D(2, 2, 0),
      ]);
      final before = editor.vertices.toList();
      editor.scale(1.0);
      for (int i = 0; i < before.length; i++) {
        expect(editor.vertices[i].x, closeTo(before[i].x, 0.001));
        expect(editor.vertices[i].y, closeTo(before[i].y, 0.001));
      }
    });

    test('multiple undo/redo cycles', () {
      final editor = PolygonEditor([
        const Point3D(0, 0, 0),
        const Point3D(1, 0, 0),
        const Point3D(1, 1, 0),
      ]);
      editor.appendVertex(const Point3D(0, 1, 0)); // 4
      editor.appendVertex(const Point3D(0.5, 1.5, 0)); // 5
      expect(editor.vertexCount, 5);

      editor.undo(); // back to 4
      expect(editor.vertexCount, 4);

      editor.undo(); // back to 3
      expect(editor.vertexCount, 3);

      editor.redo(); // forward to 4
      expect(editor.vertexCount, 4);

      editor.redo(); // forward to 5
      expect(editor.vertexCount, 5);
    });

    test('undo after new op clears redo history', () {
      final editor = PolygonEditor([
        const Point3D(0, 0, 0),
        const Point3D(1, 0, 0),
        const Point3D(1, 1, 0),
      ]);
      editor.appendVertex(const Point3D(2, 2, 0));
      editor.undo();
      editor.appendVertex(const Point3D(3, 3, 0)); // new branch
      expect(editor.canRedo, isFalse);
    });
  });

  // ━━━ Unit Converter Edge Cases ━━━
  group('UnitConverter — edge cases', () {
    test('0 meters converts to 0 feet', () {
      expect(
        UnitConverter.convertDistance(
            valueMeters: 0, targetUnit: DistanceUnit.feet),
        equals(0.0),
      );
    });

    test('negative distance converts correctly', () {
      final result = UnitConverter.convertDistance(
          valueMeters: -1, targetUnit: DistanceUnit.feet);
      expect(result, lessThan(0));
    });

    test('same unit returns same value', () {
      expect(
        UnitConverter.convertDistance(
            valueMeters: 42.5, targetUnit: DistanceUnit.meters),
        equals(42.5),
      );
    });

    test('0 area converts to 0', () {
      expect(
        UnitConverter.convertArea(
            valueSqMeters: 0, targetUnit: AreaUnit.squareFeet),
        equals(0.0),
      );
    });
  });

  // ━━━ Spatial Shape Edge Cases ━━━
  group('SpatialShape — boundary conditions', () {
    test('zero-dimension rectangle has 0 area', () {
      const shape = RectangleShape(lengthMeters: 0, widthMeters: 5);
      expect(shape.calculateAreaInSquareMeters(), equals(0.0));
    });

    test('very large rectangle computes without overflow', () {
      const shape = RectangleShape(lengthMeters: 1e6, widthMeters: 1e6);
      expect(shape.calculateAreaInSquareMeters(), equals(1e12));
    });

    test('very small circle computes area', () {
      const shape = CircleShape(radiusMeters: 0.001);
      expect(shape.calculateAreaInSquareMeters(), greaterThan(0));
      expect(shape.calculateAreaInSquareMeters(), lessThan(0.01));
    });
  });
}
