import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';

void main() {
  group('GeodeticCalculator', () {
    test('Haversine distance is accurate for ~66m separation', () {
      const p1 = GpsCoordinate(latitude: 37.7749, longitude: -122.4194);
      const p2 = GpsCoordinate(latitude: 37.7755, longitude: -122.4194);
      final d = GeodeticCalculator.calculateDistanceHaversine(p1, p2);
      expect(d, greaterThan(60.0));
      expect(d, lessThan(70.0));
    });

    test('same point returns 0 distance', () {
      const p = GpsCoordinate(latitude: 0, longitude: 0);
      expect(GeodeticCalculator.calculateDistanceHaversine(p, p), 0.0);
    });

    test('polygon area for outdoor parcel', () {
      const polygon = [
        GpsCoordinate(latitude: 37.7749, longitude: -122.4194),
        GpsCoordinate(latitude: 37.7755, longitude: -122.4194),
        GpsCoordinate(latitude: 37.7755, longitude: -122.4185),
        GpsCoordinate(latitude: 37.7749, longitude: -122.4185),
      ];
      final area = GeodeticCalculator.calculatePolygonAreaGeodetic(polygon);
      expect(area, greaterThan(4000));
      expect(area, lessThan(7000));
    });

    test('fewer than 3 points returns 0', () {
      expect(GeodeticCalculator.calculatePolygonAreaGeodetic([]), 0.0);
    });
  });
}
