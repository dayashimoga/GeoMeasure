import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/measurement_engine/domain/services/geodetic_calculator.dart';

void main() {
  group('GeodeticCalculator Tests', () {
    test('calculateDistanceHaversine computes accurate ground distance', () {
      const p1 = GpsCoordinate(latitude: 37.7749, longitude: -122.4194);
      const p2 = GpsCoordinate(latitude: 37.7755, longitude: -122.4194);

      final distanceMeters = GeodeticCalculator.calculateDistanceHaversine(p1, p2);
      expect(distanceMeters, greaterThan(60.0));
      expect(distanceMeters, lessThan(70.0));
    });

    test('calculatePolygonAreaGeodetic computes WGS-84 area for outdoor land parcel', () {
      const polygon = [
        GpsCoordinate(latitude: 37.7749, longitude: -122.4194),
        GpsCoordinate(latitude: 37.7755, longitude: -122.4194),
        GpsCoordinate(latitude: 37.7755, longitude: -122.4185),
        GpsCoordinate(latitude: 37.7749, longitude: -122.4185),
      ];

      final areaSqMeters = GeodeticCalculator.calculatePolygonAreaGeodetic(polygon);
      expect(areaSqMeters, greaterThan(5000.0));
      expect(areaSqMeters, lessThan(6000.0));
    });
  });
}
