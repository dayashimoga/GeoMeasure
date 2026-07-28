import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';

/// GPS simulation tests — verifies GPS tracking, waypoint management,
/// path distance calculation, and polygon area computation with
/// simulated GPS coordinate sequences.
void main() {
  group('GPS Simulation — Path Tracking', () {
    test('simulated straight-line walk calculates correct distance', () {
      // Walk ~111m due north (0.001° latitude ≈ 111m)
      final start = GpsCoordinate(latitude: 12.9716, longitude: 77.5946);
      final end = GpsCoordinate(latitude: 12.9726, longitude: 77.5946);
      final distance = GeodeticCalculator.calculateDistanceHaversine(start, end);
      expect(distance, closeTo(111, 5)); // ~111m per 0.001°
    });

    test('simulated rectangular walk returns to start', () {
      // Walk a rectangle: N → E → S → W
      final waypoints = [
        GpsCoordinate(latitude: 12.0, longitude: 77.0),
        GpsCoordinate(latitude: 12.001, longitude: 77.0),    // N
        GpsCoordinate(latitude: 12.001, longitude: 77.001),  // E
        GpsCoordinate(latitude: 12.0, longitude: 77.001),    // S
        GpsCoordinate(latitude: 12.0, longitude: 77.0),      // W (return)
      ];

      double totalDistance = 0;
      for (int i = 0; i < waypoints.length - 1; i++) {
        totalDistance += GeodeticCalculator.calculateDistanceHaversine(
            waypoints[i], waypoints[i + 1]);
      }
      // Perimeter of ~111m × ~111m rectangle ≈ 444m
      expect(totalDistance, closeTo(444, 30));
    });

    test('simulated GPS polygon area matches expected', () {
      // ~111m × ~111m square ≈ 12,321 m²
      final polygon = [
        GpsCoordinate(latitude: 0.0, longitude: 0.0),
        GpsCoordinate(latitude: 0.001, longitude: 0.0),
        GpsCoordinate(latitude: 0.001, longitude: 0.001),
        GpsCoordinate(latitude: 0.0, longitude: 0.001),
      ];
      final area = GeodeticCalculator.calculatePolygonAreaGeodetic(polygon);
      expect(area, greaterThan(10000));
      expect(area, lessThan(15000));
    });

    test('simulated GPS triangle area is roughly half rectangle', () {
      final triangle = [
        GpsCoordinate(latitude: 0.0, longitude: 0.0),
        GpsCoordinate(latitude: 0.001, longitude: 0.0),
        GpsCoordinate(latitude: 0.0, longitude: 0.001),
      ];
      final rect = [
        GpsCoordinate(latitude: 0.0, longitude: 0.0),
        GpsCoordinate(latitude: 0.001, longitude: 0.0),
        GpsCoordinate(latitude: 0.001, longitude: 0.001),
        GpsCoordinate(latitude: 0.0, longitude: 0.001),
      ];
      final triArea = GeodeticCalculator.calculatePolygonAreaGeodetic(triangle);
      final rectArea = GeodeticCalculator.calculatePolygonAreaGeodetic(rect);
      expect(triArea, closeTo(rectArea / 2, rectArea * 0.1));
    });

    test('simulated waypoint-to-waypoint bearing is correct', () {
      // Walking due north
      final p1 = GpsCoordinate(latitude: 12.0, longitude: 77.0);
      final p2 = GpsCoordinate(latitude: 13.0, longitude: 77.0);
      expect(GeodeticCalculator.calculateBearing(p1, p2), closeTo(0, 1));

      // Walking due east
      final p3 = GpsCoordinate(latitude: 12.0, longitude: 77.0);
      final p4 = GpsCoordinate(latitude: 12.0, longitude: 78.0);
      expect(GeodeticCalculator.calculateBearing(p3, p4), closeTo(90, 1));
    });

    test('simulated elevation profile along path', () {
      final path = [
        GpsCoordinate(latitude: 12.0, longitude: 77.0, altitudeMeters: 100),
        GpsCoordinate(latitude: 12.001, longitude: 77.0, altitudeMeters: 150),
        GpsCoordinate(latitude: 12.002, longitude: 77.0, altitudeMeters: 130),
        GpsCoordinate(latitude: 12.003, longitude: 77.0, altitudeMeters: 200),
        GpsCoordinate(latitude: 12.004, longitude: 77.0, altitudeMeters: 180),
      ];
      // Gain: +50, -20, +70, -20 => 120m gain
      expect(GeodeticCalculator.calculateElevationGain(path), equals(120.0));
    });

    test('simulated slope along steep hill', () {
      final base = GpsCoordinate(latitude: 12.0, longitude: 77.0, altitudeMeters: 100);
      final top = GpsCoordinate(latitude: 12.0001, longitude: 77.0, altitudeMeters: 110);
      final slopeDeg = GeodeticCalculator.calculateSlopeDegrees(base, top);
      expect(slopeDeg, greaterThan(0));
      final slopePct = GeodeticCalculator.calculateSlopePercent(base, top);
      expect(slopePct, greaterThan(0));
    });
  });

  group('GPS Simulation — Noisy Coordinates', () {
    test('noisy GPS readings still produce reasonable polygon area', () {
      // 100m × 100m plot with GPS noise ±0.00001° (~1m)
      final polygon = [
        GpsCoordinate(latitude: 0.00001, longitude: -0.00001),
        GpsCoordinate(latitude: 0.00091, longitude: 0.00001),
        GpsCoordinate(latitude: 0.00089, longitude: 0.00091),
        GpsCoordinate(latitude: -0.00001, longitude: 0.00089),
      ];
      final area = GeodeticCalculator.calculatePolygonAreaGeodetic(polygon);
      expect(area, greaterThan(8000));
      expect(area, lessThan(15000));
    });

    test('anti-clockwise polygon produces same area', () {
      final cw = [
        GpsCoordinate(latitude: 0.0, longitude: 0.0),
        GpsCoordinate(latitude: 0.001, longitude: 0.0),
        GpsCoordinate(latitude: 0.001, longitude: 0.001),
        GpsCoordinate(latitude: 0.0, longitude: 0.001),
      ];
      final ccw = cw.reversed.toList();
      final cwArea = GeodeticCalculator.calculatePolygonAreaGeodetic(cw);
      final ccwArea = GeodeticCalculator.calculatePolygonAreaGeodetic(ccw);
      expect(cwArea, closeTo(ccwArea, cwArea * 0.01));
    });

    test('long distance (cross-city) calculation', () {
      // Bangalore to Mysore ≈ ~140km
      final blr = GpsCoordinate(latitude: 12.9716, longitude: 77.5946);
      final mys = GpsCoordinate(latitude: 12.2958, longitude: 76.6394);
      final distance = GeodeticCalculator.calculateDistanceHaversine(blr, mys);
      expect(distance, greaterThan(120000)); // > 120km
      expect(distance, lessThan(160000)); // < 160km
    });

    test('antipodal distance is close to half earth circumference', () {
      final p1 = GpsCoordinate(latitude: 0, longitude: 0);
      final p2 = GpsCoordinate(latitude: 0, longitude: 180);
      final distance = GeodeticCalculator.calculateDistanceHaversine(p1, p2);
      // Half circumference ≈ 20,037km
      expect(distance, closeTo(20037000, 500000));
    });
  });
}
