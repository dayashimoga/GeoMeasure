import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:meassure_app/features/measurement_engine/domain/services/dxf_exporter.dart';

void main() {
  group('DxfExporter Tests', () {
    test('generates valid ASCII AutoCAD DXF structure for RectangleShape', () {
      const rect = RectangleShape(lengthMeters: 5.0, widthMeters: 4.0);
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
  });
}
