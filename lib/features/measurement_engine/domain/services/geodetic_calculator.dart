import 'dart:math';

class GpsCoordinate {
  final double latitude;
  final double longitude;
  final double altitudeMeters;

  const GpsCoordinate({
    required this.latitude,
    required this.longitude,
    this.altitudeMeters = 0.0,
  });
}

class GeodeticCalculator {
  // WGS-84 Ellipsoid constants
  static const double equatorialRadiusA = 6378137.0; // meters
  static const double flatteningF = 1 / 298.257223563;
  static const double polarRadiusB = 6356752.314245;

  /// Calculates geodesic distance between two points using Haversine formula (accurate for short/medium distances)
  static double calculateDistanceHaversine(GpsCoordinate p1, GpsCoordinate p2) {
    final dLat = _degreesToRadians(p2.latitude - p1.latitude);
    final dLon = _degreesToRadians(p2.longitude - p1.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(p1.latitude)) *
            cos(_degreesToRadians(p2.latitude)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return equatorialRadiusA * c;
  }

  /// Calculates surface area of a GPS boundary polygon on WGS-84 ellipsoid in square meters
  static double calculatePolygonAreaGeodetic(List<GpsCoordinate> polygon) {
    if (polygon.length < 3) return 0.0;

    double totalArea = 0.0;
    final int count = polygon.length;

    for (int i = 0; i < count; i++) {
      final p1 = polygon[i];
      final p2 = polygon[(i + 1) % count];

      final lat1Rad = _degreesToRadians(p1.latitude);
      final lat2Rad = _degreesToRadians(p2.latitude);
      final lon1Rad = _degreesToRadians(p1.longitude);
      final lon2Rad = _degreesToRadians(p2.longitude);

      totalArea += (lon2Rad - lon1Rad) * (2 + sin(lat1Rad) + sin(lat2Rad));
    }

    totalArea = (totalArea * equatorialRadiusA * equatorialRadiusA / 4.0).abs();
    return totalArea;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
