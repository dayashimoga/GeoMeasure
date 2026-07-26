import 'dart:math';
import '../entities/spatial_shape.dart';

/// Calculates angles, slopes, and elevation differences.
class AngleCalculator {
  /// Angle between two vectors defined by three points (vertex at p2).
  /// Returns angle in degrees [0, 180].
  static double angleBetweenPoints(Point3D p1, Point3D p2, Point3D p3) {
    final v1x = p1.x - p2.x;
    final v1y = p1.y - p2.y;
    final v1z = p1.z - p2.z;

    final v2x = p3.x - p2.x;
    final v2y = p3.y - p2.y;
    final v2z = p3.z - p2.z;

    final dot = v1x * v2x + v1y * v2y + v1z * v2z;
    final mag1 = sqrt(v1x * v1x + v1y * v1y + v1z * v1z);
    final mag2 = sqrt(v2x * v2x + v2y * v2y + v2z * v2z);

    if (mag1 == 0 || mag2 == 0) return 0.0;

    final cosAngle = (dot / (mag1 * mag2)).clamp(-1.0, 1.0);
    return acos(cosAngle) * 180.0 / pi;
  }

  /// Interior angles of a polygon at each vertex.
  static List<double> polygonInteriorAngles(List<Point3D> vertices) {
    if (vertices.length < 3) return [];

    final n = vertices.length;
    final angles = <double>[];

    for (int i = 0; i < n; i++) {
      final prev = vertices[(i - 1 + n) % n];
      final curr = vertices[i];
      final next = vertices[(i + 1) % n];
      angles.add(angleBetweenPoints(prev, curr, next));
    }

    return angles;
  }

  /// Slope angle in degrees between two points (rise/run).
  static double slopeAngle(Point3D from, Point3D to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final horizontalDistance = sqrt(dx * dx + dy * dy);
    final verticalDifference = to.z - from.z;

    if (horizontalDistance == 0) return verticalDifference >= 0 ? 90.0 : -90.0;
    return atan2(verticalDifference, horizontalDistance) * 180.0 / pi;
  }

  /// Slope as a percentage (rise/run * 100).
  static double slopePercentage(Point3D from, Point3D to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final horizontalDistance = sqrt(dx * dx + dy * dy);
    final verticalDifference = to.z - from.z;

    if (horizontalDistance == 0) return double.infinity;
    return (verticalDifference / horizontalDistance) * 100.0;
  }

  /// Elevation difference between two points.
  static double elevationDifference(Point3D from, Point3D to) {
    return to.z - from.z;
  }

  /// Bearing (azimuth) from one point to another in degrees [0, 360).
  static double bearing(Point3D from, Point3D to) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final angle = atan2(dx, dy) * 180.0 / pi;
    return (angle + 360.0) % 360.0;
  }
}
