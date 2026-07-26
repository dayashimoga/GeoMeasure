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
  static double calculateDistanceHaversine(
    GpsCoordinate p1,
    GpsCoordinate p2,
  ) {
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

  /// Calculates surface area of a GPS boundary polygon projected onto mean-latitude tangent plane in square meters
  static double calculatePolygonAreaGeodetic(List<GpsCoordinate> polygon) {
    if (polygon.length < 3) return 0.0;

    final int count = polygon.length;
    double meanLat = 0.0;
    double meanLon = 0.0;

    for (final pt in polygon) {
      meanLat += pt.latitude;
      meanLon += pt.longitude;
    }
    meanLat /= count;
    meanLon /= count;

    final lat0Rad = _degreesToRadians(meanLat);
    final lon0Rad = _degreesToRadians(meanLon);
    final cosLat0 = cos(lat0Rad);

    final List<Point> projectedPoints = [];
    for (final pt in polygon) {
      final latRad = _degreesToRadians(pt.latitude);
      final lonRad = _degreesToRadians(pt.longitude);

      final x = equatorialRadiusA * (lonRad - lon0Rad) * cosLat0;
      final y = equatorialRadiusA * (latRad - lat0Rad);
      projectedPoints.add(Point(x, y));
    }

    double areaSum = 0.0;
    for (int i = 0; i < count; i++) {
      final j = (i + 1) % count;
      areaSum += projectedPoints[i].x * projectedPoints[j].y;
      areaSum -= projectedPoints[j].x * projectedPoints[i].y;
    }

    return (areaSum.abs()) / 2.0;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180.0;
  }
}
