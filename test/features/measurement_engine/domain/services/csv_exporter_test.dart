import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/csv_exporter.dart';

void main() {
  group('CsvExporter', () {
    test('generates valid CSV header and data rows', () {
      final results = [
        MeasurementResult(
          area: 100.0,
          areaUnit: AreaUnit.squareMeters,
          perimeter: 40.0,
          distanceUnit: DistanceUnit.meters,
          volume: 300.0,
          algorithmUsed: MeasurementAlgorithm.lidar,
          estimatedAccuracyPercentage: 99.5,
          shapeType: ShapeType.rectangle,
          shapeName: 'Main Hall',
        ),
      ];

      final csv = CsvExporter.generateCsv(results);
      expect(csv, contains('ID,Technique,ShapeType,ShapeName'));
      expect(csv, contains('"lidar"'));
      expect(csv, contains('"rectangle"'));
      expect(csv, contains('"Main Hall"'));
    });

    test('empty list produces header only', () {
      final csv = CsvExporter.generateCsv([]);
      expect(csv, contains('ID,'));
      expect(csv.trim().split('\n').length, 1);
    });
  });
}
