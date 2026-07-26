import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/spatial_shape.dart';

void main() {
  group('WallShape Net Area Deduction Tests', () {
    test('deducts door and window openings from wall gross area', () {
      const wall = WallShape(
        lengthMeters: 6.0,
        heightMeters: 3.0,
        openings: [
          WallOpening(label: 'Main Door', widthMeters: 1.0, heightMeters: 2.0), // 2.0 sq m
          WallOpening(label: 'Window A', widthMeters: 1.5, heightMeters: 1.0), // 1.5 sq m
        ],
      );

      expect(wall.grossAreaInSquareMeters, equals(18.0));
      expect(wall.openingsTotalAreaInSquareMeters, equals(3.5));
      expect(wall.calculateAreaInSquareMeters(), equals(14.5));
    });
  });
}
