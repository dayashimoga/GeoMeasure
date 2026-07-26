import 'dart:math';
import 'dart:typed_data';

/// Photogrammetry pipeline — multi-image 3D reconstruction.
///
/// Processes sets of overlapping images with known camera parameters
/// to extract 3D point clouds and surface measurements.
/// Pure Dart implementation — no native dependencies.
class PhotogrammetryPipeline {
  /// Detect matching feature points between two images.
  ///
  /// Uses a simplified FAST corner detector + NCC patch matching.
  static List<FeatureMatch> matchFeatures(
    Uint8List image1Gray,
    Uint8List image2Gray,
    int width,
    int height, {
    int patchSize = 11,
    double matchThreshold = 0.7,
  }) {
    final corners1 = _detectFastCorners(image1Gray, width, height);
    final corners2 = _detectFastCorners(image2Gray, width, height);
    final matches = <FeatureMatch>[];
    final half = patchSize ~/ 2;

    for (final c1 in corners1) {
      if (c1.x < half || c1.y < half ||
          c1.x >= width - half || c1.y >= height - half) {
        continue;
      }

      double bestScore = -1;
      FeaturePoint? bestMatch;

      for (final c2 in corners2) {
        if (c2.x < half || c2.y < half ||
            c2.x >= width - half || c2.y >= height - half) {
          continue;
        }

        // NCC (normalized cross-correlation) between patches
        final ncc = _patchNcc(
          image1Gray, c1.x, c1.y,
          image2Gray, c2.x, c2.y,
          width, patchSize,
        );

        if (ncc > bestScore) {
          bestScore = ncc;
          bestMatch = c2;
        }
      }

      if (bestScore >= matchThreshold && bestMatch != null) {
        matches.add(FeatureMatch(
          p1: c1,
          p2: bestMatch,
          score: bestScore,
        ));
      }
    }

    return matches;
  }

  /// Triangulate 3D points from matched features and camera parameters.
  static List<PgPoint3D> triangulate(
    List<FeatureMatch> matches,
    CameraIntrinsics camera,
    CameraPose pose1,
    CameraPose pose2,
  ) {
    final points = <PgPoint3D>[];

    for (final match in matches) {
      final x1 = (match.p1.x - camera.cx) / camera.fx;
      final y1 = (match.p1.y - camera.cy) / camera.fy;
      final x2 = (match.p2.x - camera.cx) / camera.fx;
      final y2 = (match.p2.y - camera.cy) / camera.fy;

      final point = _triangulatePoint(x1, y1, pose1, x2, y2, pose2);
      if (point != null) {
        points.add(point);
      }
    }

    return points;
  }

  /// Compute scale factor from a known reference distance.
  static double computeScaleFactor(
    PgPoint3D a,
    PgPoint3D b,
    double knownDistanceMeters,
  ) {
    final computedDist = a.distanceTo(b);
    if (computedDist <= 0) return 1.0;
    return knownDistanceMeters / computedDist;
  }

  /// Estimate surface area from a 3D point cloud.
  static double estimateSurfaceArea(List<PgPoint3D> points) {
    if (points.length < 3) return 0.0;

    final cx = points.fold<double>(0, (s, p) => s + p.x) / points.length;
    final cy = points.fold<double>(0, (s, p) => s + p.y) / points.length;

    final sorted = List<PgPoint3D>.from(points)
      ..sort((a, b) {
        final angleA = atan2(a.y - cy, a.x - cx);
        final angleB = atan2(b.y - cy, b.x - cx);
        return angleA.compareTo(angleB);
      });

    double area = 0;
    for (int i = 0; i < sorted.length; i++) {
      final j = (i + 1) % sorted.length;
      area += sorted[i].x * sorted[j].y;
      area -= sorted[j].x * sorted[i].y;
    }

    return area.abs() / 2;
  }

  /// Measure distance between two 3D points (scaled).
  static double measureDistance(PgPoint3D a, PgPoint3D b, double scaleFactor) =>
      a.distanceTo(b) * scaleFactor;

  /// Public wrapper for FAST corner detection (for testing).
  static List<FeaturePoint> detectFastCornersPublic(
    Uint8List gray,
    int width,
    int height, {
    int threshold = 30,
    int maxCorners = 500,
  }) =>
      _detectFastCorners(gray, width, height,
          threshold: threshold, maxCorners: maxCorners);

  // ── FAST corner detector ─────────────────────────────────────

  static List<FeaturePoint> _detectFastCorners(
    Uint8List gray,
    int width,
    int height, {
    int threshold = 30,
    int maxCorners = 500,
  }) {
    final corners = <FeaturePoint>[];
    const offsets = [
      [0, -3], [1, -3], [2, -2], [3, -1],
      [3, 0], [3, 1], [2, 2], [1, 3],
      [0, 3], [-1, 3], [-2, 2], [-3, 1],
      [-3, 0], [-3, -1], [-2, -2], [-1, -3],
    ];

    for (int y = 3; y < height - 3; y++) {
      for (int x = 3; x < width - 3; x++) {
        final center = gray[y * width + x];
        int brighter = 0, darker = 0;

        for (final idx in [0, 4, 8, 12]) {
          final px = gray[(y + offsets[idx][1]) * width + (x + offsets[idx][0])];
          if (px > center + threshold) brighter++;
          if (px < center - threshold) darker++;
        }

        if (brighter < 3 && darker < 3) continue;

        int contiguousBright = 0, contiguousDark = 0;
        int maxBright = 0, maxDark = 0;
        for (int i = 0; i < 32; i++) {
          final idx = i % 16;
          final px = gray[(y + offsets[idx][1]) * width +
              (x + offsets[idx][0])];
          if (px > center + threshold) {
            contiguousBright++;
            contiguousDark = 0;
          } else if (px < center - threshold) {
            contiguousDark++;
            contiguousBright = 0;
          } else {
            contiguousBright = 0;
            contiguousDark = 0;
          }
          if (contiguousBright > maxBright) maxBright = contiguousBright;
          if (contiguousDark > maxDark) maxDark = contiguousDark;
        }

        if (maxBright >= 9 || maxDark >= 9) {
          corners.add(FeaturePoint(
            x: x,
            y: y,
            response: (maxBright > maxDark ? maxBright : maxDark).toDouble(),
          ));
        }
      }
    }

    corners.sort((a, b) => b.response.compareTo(a.response));
    return corners.take(maxCorners).toList();
  }

  /// Normalized cross-correlation between two patches.
  static double _patchNcc(
    Uint8List img1, int x1, int y1,
    Uint8List img2, int x2, int y2,
    int width, int patchSize,
  ) {
    final half = patchSize ~/ 2;
    double sum1 = 0, sum2 = 0;
    double sq1 = 0, sq2 = 0, cross = 0;
    int n = 0;

    for (int dy = -half; dy <= half; dy++) {
      for (int dx = -half; dx <= half; dx++) {
        final v1 = img1[(y1 + dy) * width + (x1 + dx)].toDouble();
        final v2 = img2[(y2 + dy) * width + (x2 + dx)].toDouble();
        sum1 += v1;
        sum2 += v2;
        sq1 += v1 * v1;
        sq2 += v2 * v2;
        cross += v1 * v2;
        n++;
      }
    }

    final mean1 = sum1 / n;
    final mean2 = sum2 / n;
    final var1 = sq1 / n - mean1 * mean1;
    final var2 = sq2 / n - mean2 * mean2;
    final covar = cross / n - mean1 * mean2;

    if (var1 <= 0 || var2 <= 0) return 0.0;
    return covar / (sqrt(var1) * sqrt(var2));
  }

  /// DLT point triangulation from two views.
  static PgPoint3D? _triangulatePoint(
    double x1, double y1, CameraPose pose1,
    double x2, double y2, CameraPose pose2,
  ) {
    final d1 = pose1.rotatePoint(PgPoint3D(x: x1, y: y1, z: 1.0));
    final d2 = pose2.rotatePoint(PgPoint3D(x: x2, y: y2, z: 1.0));

    final w0x = pose1.tx - pose2.tx;
    final w0y = pose1.ty - pose2.ty;
    final w0z = pose1.tz - pose2.tz;

    final a = d1.x * d1.x + d1.y * d1.y + d1.z * d1.z;
    final b = d1.x * d2.x + d1.y * d2.y + d1.z * d2.z;
    final c = d2.x * d2.x + d2.y * d2.y + d2.z * d2.z;
    final d = d1.x * w0x + d1.y * w0y + d1.z * w0z;
    final e = d2.x * w0x + d2.y * w0y + d2.z * w0z;

    final denom = a * c - b * b;
    if (denom.abs() < 1e-10) return null;

    final t1 = (b * e - c * d) / denom;
    final t2 = (a * e - b * d) / denom;

    return PgPoint3D(
      x: ((pose1.tx + d1.x * t1) + (pose2.tx + d2.x * t2)) / 2,
      y: ((pose1.ty + d1.y * t1) + (pose2.ty + d2.y * t2)) / 2,
      z: ((pose1.tz + d1.z * t1) + (pose2.tz + d2.z * t2)) / 2,
    );
  }
}

/// A 3D point used in photogrammetry (prefixed to avoid collision
/// with sensor_fusion Position3D).
class PgPoint3D {
  final double x, y, z;
  const PgPoint3D({required this.x, required this.y, required this.z});

  double distanceTo(PgPoint3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  Map<String, double> toJson() => {'x': x, 'y': y, 'z': z};
}

/// Feature point in an image.
class FeaturePoint {
  final int x, y;
  final double response;
  const FeaturePoint({required this.x, required this.y, required this.response});
}

/// A match between two feature points.
class FeatureMatch {
  final FeaturePoint p1, p2;
  final double score;
  const FeatureMatch({required this.p1, required this.p2, required this.score});
}

/// Camera intrinsic parameters.
class CameraIntrinsics {
  final double fx, fy, cx, cy;
  final int width, height;

  const CameraIntrinsics({
    required this.fx,
    required this.fy,
    required this.cx,
    required this.cy,
    required this.width,
    required this.height,
  });

  factory CameraIntrinsics.fromFov(
      double fovDegrees, int width, int height) {
    final fx = (width / 2) / tan(fovDegrees * pi / 360);
    return CameraIntrinsics(
      fx: fx,
      fy: fx,
      cx: width / 2.0,
      cy: height / 2.0,
      width: width,
      height: height,
    );
  }
}

/// Camera pose (rotation + translation).
class CameraPose {
  final List<double> rotation;
  final double tx, ty, tz;

  const CameraPose({
    required this.rotation,
    required this.tx,
    required this.ty,
    required this.tz,
  });

  factory CameraPose.identity() => const CameraPose(
        rotation: [1, 0, 0, 0, 1, 0, 0, 0, 1],
        tx: 0,
        ty: 0,
        tz: 0,
      );

  PgPoint3D rotatePoint(PgPoint3D p) => PgPoint3D(
        x: rotation[0] * p.x + rotation[1] * p.y + rotation[2] * p.z,
        y: rotation[3] * p.x + rotation[4] * p.y + rotation[5] * p.z,
        z: rotation[6] * p.x + rotation[7] * p.y + rotation[8] * p.z,
      );
}
