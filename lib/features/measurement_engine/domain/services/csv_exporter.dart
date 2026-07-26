import '../entities/measurement_result.dart';

class CsvExporter {
  /// Generates CSV Schedule for dimensional bill of materials and measurement summaries
  static String generateCsv(List<MeasurementResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('ID,Technique,ShapeType,ShapeName,Area,AreaUnit,Perimeter,DistanceUnit,Volume,AccuracyPercentage,Timestamp');

    for (int i = 0; i < results.length; i++) {
      final res = results[i];
      buffer.writeln(
        '${i + 1},"${res.algorithmUsed.name}","${res.shapeType.name}","${res.shapeName}",${res.area.toStringAsFixed(3)},"${res.areaUnit.name}",${res.perimeter.toStringAsFixed(3)},"${res.distanceUnit.name}",${res.volume.toStringAsFixed(3)},${res.estimatedAccuracyPercentage.toStringAsFixed(1)},"${res.timestamp.toIso8601String()}"',
      );
    }

    return buffer.toString();
  }
}
