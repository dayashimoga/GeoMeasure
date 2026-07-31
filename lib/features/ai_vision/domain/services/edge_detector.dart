import 'dart:math';
import 'dart:typed_data';

/// Pure Dart edge detection — Sobel and Harris algorithms.
///
/// Operates on grayscale image data represented as a flat list of pixel
/// intensity values (0–255). No ML or platform dependencies.
class EdgeDetector {
  /// Sobel edge detection on a grayscale image.
  ///
  /// Returns an edge magnitude map (0–255) where bright pixels indicate edges.
  static Uint8List detectEdgesSobel(
    List<int> grayscale,
    int width,
    int height,
  ) {
    final output = Uint8List(width * height);

    // Sobel kernels
    const gx = [-1, 0, 1, -2, 0, 2, -1, 0, 1];
    const gy = [-1, -2, -1, 0, 0, 0, 1, 2, 1];

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        int sumX = 0, sumY = 0;
        int ki = 0;
        for (int ky = -1; ky <= 1; ky++) {
          for (int kx = -1; kx <= 1; kx++) {
            final pixel = grayscale[(y + ky) * width + (x + kx)];
            sumX += pixel * gx[ki];
            sumY += pixel * gy[ki];
            ki++;
          }
        }
        final magnitude = sqrt(sumX * sumX + sumY * sumY).toInt().clamp(0, 255);
        output[y * width + x] = magnitude;
      }
    }

    return output;
  }

  /// Harris corner detection on a grayscale image.
  ///
  /// Returns list of (x, y) corner positions with response strength.
  static List<CornerPoint> detectCornersHarris(
    List<int> grayscale,
    int width,
    int height, {
    double k = 0.04,
    double threshold = 0.01,
    int windowSize = 3,
  }) {
    // Compute image gradients (Sobel Ix, Iy)
    final ix = Float64List(width * height);
    final iy = Float64List(width * height);

    for (int y = 1; y < height - 1; y++) {
      for (int x = 1; x < width - 1; x++) {
        ix[y * width + x] =
            (grayscale[y * width + x + 1] - grayscale[y * width + x - 1])
                    .toDouble() /
                2;
        iy[y * width + x] =
            (grayscale[(y + 1) * width + x] - grayscale[(y - 1) * width + x])
                    .toDouble() /
                2;
      }
    }

    // Compute Harris response
    final response = Float64List(width * height);
    final half = windowSize ~/ 2;
    double maxResponse = 0;

    for (int y = half + 1; y < height - half - 1; y++) {
      for (int x = half + 1; x < width - half - 1; x++) {
        double sxx = 0, syy = 0, sxy = 0;
        for (int wy = -half; wy <= half; wy++) {
          for (int wx = -half; wx <= half; wx++) {
            final idx = (y + wy) * width + (x + wx);
            sxx += ix[idx] * ix[idx];
            syy += iy[idx] * iy[idx];
            sxy += ix[idx] * iy[idx];
          }
        }
        // Harris response: det(M) - k * trace(M)²
        final det = sxx * syy - sxy * sxy;
        final trace = sxx + syy;
        final r = det - k * trace * trace;
        response[y * width + x] = r;
        if (r > maxResponse) maxResponse = r;
      }
    }

    // Threshold and collect corners
    final corners = <CornerPoint>[];
    final minResponse = maxResponse * threshold;

    for (int y = half + 1; y < height - half - 1; y++) {
      for (int x = half + 1; x < width - half - 1; x++) {
        final r = response[y * width + x];
        if (r < minResponse) continue;

        // Non-max suppression (3×3)
        bool isMax = true;
        for (int dy = -1; dy <= 1 && isMax; dy++) {
          for (int dx = -1; dx <= 1 && isMax; dx++) {
            if (dx == 0 && dy == 0) continue;
            if (response[(y + dy) * width + (x + dx)] > r) isMax = false;
          }
        }
        if (isMax) {
          corners.add(CornerPoint(x: x, y: y, response: r));
        }
      }
    }

    // Sort by strength descending
    corners.sort((a, b) => b.response.compareTo(a.response));
    return corners;
  }

  /// Detect horizontal and vertical lines from edge image.
  ///
  /// Returns list of line segments found via run-length analysis.
  static List<LineSegment> detectLines(
    Uint8List edgeMap,
    int width,
    int height, {
    int minLength = 20,
    int edgeThreshold = 128,
  }) {
    final lines = <LineSegment>[];

    // Horizontal line detection
    for (int y = 0; y < height; y++) {
      int runStart = -1;
      for (int x = 0; x < width; x++) {
        final isEdge = edgeMap[y * width + x] >= edgeThreshold;
        if (isEdge && runStart < 0) {
          runStart = x;
        } else if (!isEdge && runStart >= 0) {
          if (x - runStart >= minLength) {
            lines.add(LineSegment(
              x1: runStart,
              y1: y,
              x2: x - 1,
              y2: y,
            ));
          }
          runStart = -1;
        }
      }
      if (runStart >= 0 && width - runStart >= minLength) {
        lines.add(LineSegment(x1: runStart, y1: y, x2: width - 1, y2: y));
      }
    }

    // Vertical line detection
    for (int x = 0; x < width; x++) {
      int runStart = -1;
      for (int y = 0; y < height; y++) {
        final isEdge = edgeMap[y * width + x] >= edgeThreshold;
        if (isEdge && runStart < 0) {
          runStart = y;
        } else if (!isEdge && runStart >= 0) {
          if (y - runStart >= minLength) {
            lines.add(LineSegment(
              x1: x,
              y1: runStart,
              x2: x,
              y2: y - 1,
            ));
          }
          runStart = -1;
        }
      }
      if (runStart >= 0 && height - runStart >= minLength) {
        lines.add(LineSegment(x1: x, y1: runStart, x2: x, y2: height - 1));
      }
    }

    return lines;
  }

  /// Convert RGBA pixel data to grayscale.
  static List<int> rgbaToGrayscale(Uint8List rgba, int width, int height) {
    final gray = List<int>.filled(width * height, 0);
    for (int i = 0; i < width * height; i++) {
      final r = rgba[i * 4];
      final g = rgba[i * 4 + 1];
      final b = rgba[i * 4 + 2];
      // ITU-R BT.601 luma
      gray[i] = (0.299 * r + 0.587 * g + 0.114 * b).round().clamp(0, 255);
    }
    return gray;
  }
}

/// A detected corner point.
class CornerPoint {
  final int x;
  final int y;
  final double response;

  const CornerPoint({required this.x, required this.y, required this.response});

  Map<String, dynamic> toJson() => {'x': x, 'y': y, 'response': response};
}

/// A detected line segment.
class LineSegment {
  final int x1, y1, x2, y2;

  const LineSegment({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
  });

  double get length =>
      sqrt((x2 - x1) * (x2 - x1) + (y2 - y1) * (y2 - y1).toDouble());

  bool get isHorizontal => y1 == y2;
  bool get isVertical => x1 == x2;

  Map<String, dynamic> toJson() =>
      {'x1': x1, 'y1': y1, 'x2': x2, 'y2': y2, 'length': length};
}
