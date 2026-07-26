import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/spatial_shape.dart';

void main() {
  group('SpatialShape Geometry Tests', () {
    test('Rectangle shape area & perimeter calculation', () {
      const rect = RectangleShape(lengthMeters: 10, widthMeters: 5);
      expect(rect.calculateAreaInSquareMeters(), equals(50.0));
      expect(rect.calculatePerimeterInMeters(), equals(30.0));
    });

    test('Circle shape area & perimeter calculation', () {
      const circle = CircleShape(radiusMeters: 2.0);
      expect(circle.calculateAreaInSquareMeters(), closeTo(12.566, 0.01));
      expect(circle.calculatePerimeterInMeters(), closeTo(12.566, 0.01));
    });

    test('Irregular polygon Shoelace formula calculation', () {
      const polygon = IrregularPolygonShape(
        vertices: [
          Point3D(0, 0),
          Point3D(4, 0),
          Point3D(4, 3),
          Point3D(0, 3),
        ],
      );
      expect(polygon.calculateAreaInSquareMeters(), equals(12.0));
      expect(polygon.calculatePerimeterInMeters(), equals(14.0));
    });

    test('Room volume calculation', () {
      const room = RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(5, 0),
          Point3D(5, 4),
          Point3D(0, 4),
        ],
        heightMeters: 3.0,
      );
      expect(room.calculateAreaInSquareMeters(), equals(20.0));
      expect(room.calculateVolumeInCubicMeters(), equals(60.0));
    });
  });
}
