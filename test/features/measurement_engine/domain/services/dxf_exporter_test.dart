import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/dxf_exporter.dart';

void main() {
  group('DxfExporter', () {
    test('generates valid DXF for RectangleShape', () {
      const rect = RectangleShape(lengthMeters: 5, widthMeters: 4);
      final dxf = DxfExporter.generateDxf(rect);
      expect(dxf, contains('SECTION'));
      expect(dxf, contains('ENTITIES'));
      expect(dxf, contains('LINE'));
      expect(dxf, contains('EOF'));
    });

    test('generates CIRCLE entity for CircleShape', () {
      const circle = CircleShape(radiusMeters: 3.5);
      final dxf = DxfExporter.generateDxf(circle);
      expect(dxf, contains('CIRCLE'));
      expect(dxf, contains('3.5'));
    });

    test('generates LINE entities for IrregularPolygon', () {
      const poly = IrregularPolygonShape(vertices: [
        Point3D(0, 0), Point3D(3, 0), Point3D(3, 4),
      ]);
      final dxf = DxfExporter.generateDxf(poly);
      expect(dxf, contains('LINE'));
    });
  });
}
