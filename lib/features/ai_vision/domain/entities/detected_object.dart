import 'dart:math';

/// Category of detected objects — covers all requested object types.
enum ObjectCategory {
  // ── Furniture ──
  chair, table, desk, sofa, bed, shelf, cabinet, drawer, wardrobe,
  // ── Vehicles ──
  car, bike, motorcycle, truck, bus, van, bicycle,
  // ── Construction ──
  brick, tile, roofSheet, pole, beam, column, pipe, rebar, scaffold,
  // ── Building elements ──
  door, window, wall, floor, ceiling, roof, staircase, elevator,
  // ── Nature ──
  tree, plant, flower, bush, grass,
  // ── People & Animals ──
  person, animal, dog, cat,
  // ── Inventory ──
  box, package, pallet, container, crate, barrel, sack,
  // ── Infrastructure ──
  solarPanel, sign, fence, gate, lamp, hydrant,
  // ── Other ──
  unknown,
}

/// Bounding box in image coordinates (0–1 normalized).
class BoundingBox {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const BoundingBox({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  double get width => right - left;
  double get height => bottom - top;
  double get area => width * height;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  /// Intersection-over-Union for duplicate detection.
  double iou(BoundingBox other) {
    final xA = max(left, other.left);
    final yA = max(top, other.top);
    final xB = min(right, other.right);
    final yB = min(bottom, other.bottom);
    final interArea = max(0.0, xB - xA) * max(0.0, yB - yA);
    final unionArea = area + other.area - interArea;
    return unionArea > 0 ? interArea / unionArea : 0.0;
  }

  Map<String, dynamic> toJson() => {
        'left': left,
        'top': top,
        'right': right,
        'bottom': bottom,
      };

  factory BoundingBox.fromJson(Map<String, dynamic> m) => BoundingBox(
        left: (m['left'] as num).toDouble(),
        top: (m['top'] as num).toDouble(),
        right: (m['right'] as num).toDouble(),
        bottom: (m['bottom'] as num).toDouble(),
      );
}

/// A single detected object in an image.
class DetectedObject {
  final String label;
  final ObjectCategory category;
  final double confidence;
  final BoundingBox boundingBox;
  final int trackingId;

  // ── Estimated real-world dimensions (if depth info available) ──
  final double? estimatedWidthMeters;
  final double? estimatedHeightMeters;
  final double? estimatedDepthMeters;
  final double? estimatedDistanceMeters;

  const DetectedObject({
    required this.label,
    required this.category,
    required this.confidence,
    required this.boundingBox,
    this.trackingId = -1,
    this.estimatedWidthMeters,
    this.estimatedHeightMeters,
    this.estimatedDepthMeters,
    this.estimatedDistanceMeters,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'category': category.name,
        'confidence': confidence,
        'boundingBox': boundingBox.toJson(),
        'trackingId': trackingId,
        'estimatedWidthMeters': estimatedWidthMeters,
        'estimatedHeightMeters': estimatedHeightMeters,
        'estimatedDepthMeters': estimatedDepthMeters,
        'estimatedDistanceMeters': estimatedDistanceMeters,
      };

  factory DetectedObject.fromJson(Map<String, dynamic> m) => DetectedObject(
        label: m['label'] as String,
        category: ObjectCategory.values.firstWhere(
          (e) => e.name == (m['category'] as String?),
          orElse: () => ObjectCategory.unknown,
        ),
        confidence: (m['confidence'] as num).toDouble(),
        boundingBox:
            BoundingBox.fromJson(m['boundingBox'] as Map<String, dynamic>),
        trackingId: m['trackingId'] as int? ?? -1,
        estimatedWidthMeters:
            (m['estimatedWidthMeters'] as num?)?.toDouble(),
        estimatedHeightMeters:
            (m['estimatedHeightMeters'] as num?)?.toDouble(),
        estimatedDepthMeters:
            (m['estimatedDepthMeters'] as num?)?.toDouble(),
        estimatedDistanceMeters:
            (m['estimatedDistanceMeters'] as num?)?.toDouble(),
      );
}

/// Count result for a specific object category.
class ObjectCount {
  final ObjectCategory category;
  final int count;
  final double averageConfidence;
  final List<BoundingBox> positions;
  final int duplicatesRemoved;

  const ObjectCount({
    required this.category,
    required this.count,
    required this.averageConfidence,
    this.positions = const [],
    this.duplicatesRemoved = 0,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'count': count,
        'averageConfidence': averageConfidence,
        'duplicatesRemoved': duplicatesRemoved,
      };
}

/// Complete detection result from a single image or frame.
class DetectionResult {
  final List<DetectedObject> objects;
  final int imageWidth;
  final int imageHeight;
  final Duration processingTime;
  final DateTime timestamp;
  final String modelUsed;

  const DetectionResult({
    required this.objects,
    required this.imageWidth,
    required this.imageHeight,
    required this.processingTime,
    required this.timestamp,
    this.modelUsed = 'ml_kit_default',
  });

  /// Count objects by category with deduplication.
  List<ObjectCount> countByCategory({double iouThreshold = 0.5}) {
    final grouped = <ObjectCategory, List<DetectedObject>>{};
    for (final obj in objects) {
      grouped.putIfAbsent(obj.category, () => []).add(obj);
    }

    return grouped.entries.map((entry) {
      final objs = entry.value;
      final deduplicated = _removeDuplicates(objs, iouThreshold);
      final avgConf = deduplicated.isEmpty
          ? 0.0
          : deduplicated.fold<double>(0, (s, o) => s + o.confidence) /
              deduplicated.length;

      return ObjectCount(
        category: entry.key,
        count: deduplicated.length,
        averageConfidence: avgConf,
        positions: deduplicated.map((o) => o.boundingBox).toList(),
        duplicatesRemoved: objs.length - deduplicated.length,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  /// Total unique object count.
  int get totalCount =>
      countByCategory().fold(0, (sum, c) => sum + c.count);

  /// Density: objects per unit area of image.
  double get objectDensity =>
      imageWidth > 0 && imageHeight > 0
          ? objects.length / (imageWidth * imageHeight).toDouble()
          : 0.0;

  /// Non-max suppression to remove overlapping detections.
  static List<DetectedObject> _removeDuplicates(
      List<DetectedObject> objects, double iouThreshold) {
    if (objects.isEmpty) return objects;

    final sorted = List<DetectedObject>.from(objects)
      ..sort((a, b) => b.confidence.compareTo(a.confidence));

    final kept = <DetectedObject>[];
    final suppressed = List<bool>.filled(sorted.length, false);

    for (int i = 0; i < sorted.length; i++) {
      if (suppressed[i]) continue;
      kept.add(sorted[i]);
      for (int j = i + 1; j < sorted.length; j++) {
        if (!suppressed[j] &&
            sorted[i].boundingBox.iou(sorted[j].boundingBox) >
                iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }

  Map<String, dynamic> toJson() => {
        'objects': objects.map((o) => o.toJson()).toList(),
        'imageWidth': imageWidth,
        'imageHeight': imageHeight,
        'processingTimeMs': processingTime.inMilliseconds,
        'timestamp': timestamp.toIso8601String(),
        'modelUsed': modelUsed,
        'totalCount': totalCount,
      };
}

/// Segmentation mask for a detected object.
class SegmentationMask {
  final int width;
  final int height;
  final List<int> maskData; // 0 = background, 1-N = object ID
  final ObjectCategory category;
  final double confidence;

  const SegmentationMask({
    required this.width,
    required this.height,
    required this.maskData,
    required this.category,
    this.confidence = 0.0,
  });

  /// Pixel count belonging to this object.
  int get objectPixelCount =>
      maskData.where((v) => v > 0).length;

  /// Object area as fraction of total image.
  double get areaFraction =>
      width > 0 && height > 0
          ? objectPixelCount / (width * height)
          : 0.0;
}

/// OCR text block detected in an image.
class TextBlock {
  final String text;
  final BoundingBox boundingBox;
  final double confidence;
  final String language;

  const TextBlock({
    required this.text,
    required this.boundingBox,
    this.confidence = 0.0,
    this.language = 'en',
  });

  Map<String, dynamic> toJson() => {
        'text': text,
        'boundingBox': boundingBox.toJson(),
        'confidence': confidence,
        'language': language,
      };
}

/// Barcode/QR detection result.
class BarcodeResult {
  final String rawValue;
  final String format; // QR, EAN-13, Code128, etc.
  final BoundingBox boundingBox;

  const BarcodeResult({
    required this.rawValue,
    required this.format,
    required this.boundingBox,
  });

  Map<String, dynamic> toJson() => {
        'rawValue': rawValue,
        'format': format,
        'boundingBox': boundingBox.toJson(),
      };
}

/// Image label (classification) result.
class ImageLabel {
  final String label;
  final double confidence;
  final int index;

  const ImageLabel({
    required this.label,
    required this.confidence,
    this.index = 0,
  });

  Map<String, dynamic> toJson() => {
        'label': label,
        'confidence': confidence,
        'index': index,
      };
}
