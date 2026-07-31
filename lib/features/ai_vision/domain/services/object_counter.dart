import '../entities/detected_object.dart';

/// Object counting service with deduplication and density estimation.
///
/// Processes DetectionResult to produce aggregated counts by category
/// with IoU-based duplicate removal.
class ObjectCounter {
  final double iouThreshold;
  final double minConfidence;

  const ObjectCounter({
    this.iouThreshold = 0.5,
    this.minConfidence = 0.3,
  });

  /// Count objects from a detection result, filtering by confidence
  /// and removing duplicates via non-max suppression.
  List<ObjectCount> count(DetectionResult result) {
    // Filter by minimum confidence
    final filtered =
        result.objects.where((o) => o.confidence >= minConfidence).toList();

    // Group by category
    final grouped = <ObjectCategory, List<DetectedObject>>{};
    for (final obj in filtered) {
      grouped.putIfAbsent(obj.category, () => []).add(obj);
    }

    // Deduplicate each group and create counts
    return grouped.entries.map((entry) {
      final deduped = _nonMaxSuppression(entry.value);
      final avgConf = deduped.isEmpty
          ? 0.0
          : deduped.fold<double>(0, (s, o) => s + o.confidence) /
              deduped.length;

      return ObjectCount(
        category: entry.key,
        count: deduped.length,
        averageConfidence: avgConf,
        positions: deduped.map((o) => o.boundingBox).toList(),
        duplicatesRemoved: entry.value.length - deduped.length,
      );
    }).toList()
      ..sort((a, b) => b.count.compareTo(a.count));
  }

  /// Estimate density: objects per square meter given a known
  /// reference area visible in the image.
  double estimateDensity(List<ObjectCount> counts, double referenceAreaSqm) {
    if (referenceAreaSqm <= 0) return 0.0;
    final total = counts.fold<int>(0, (s, c) => s + c.count);
    return total / referenceAreaSqm;
  }

  /// Count objects of a specific category.
  int countCategory(DetectionResult result, ObjectCategory category) {
    final objs = result.objects
        .where((o) => o.category == category && o.confidence >= minConfidence)
        .toList();
    return _nonMaxSuppression(objs).length;
  }

  /// Multi-frame aggregated count — average across N frames
  /// for more stable results.
  Map<ObjectCategory, double> averageAcrossFrames(
      List<DetectionResult> frames) {
    final totals = <ObjectCategory, List<int>>{};
    for (final frame in frames) {
      final counts = count(frame);
      for (final c in counts) {
        totals.putIfAbsent(c.category, () => []).add(c.count);
      }
    }

    return totals.map((cat, values) {
      final avg = values.fold<int>(0, (s, v) => s + v) / values.length;
      return MapEntry(cat, avg);
    });
  }

  List<DetectedObject> _nonMaxSuppression(List<DetectedObject> objects) {
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
            sorted[i].boundingBox.iou(sorted[j].boundingBox) > iouThreshold) {
          suppressed[j] = true;
        }
      }
    }
    return kept;
  }
}
