import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:meassure_app/features/measurement_engine/domain/services/csv_exporter.dart';

void main() {
  group('CsvExporter Tests', () {
    test('generates valid CSV content header and data row', () {
      final results = [
        const MeasurementResult(
          area: 100.0,
          areaUnit: AreaUnit.squareMeters,
          perimeter: 40.0,
          distanceUnit: DistanceUnit.meters,
          volume: 300.0,
          algorithmUsed: MeasurementAlgorithm.lidar,
          estimatedAccuracyPercentage: 99.5,
        ),
      ];

      final csvStr = CsvExporter.generateCsv(results);

      expect(csvStr, contains('ID,Technique,Area,AreaUnit,Perimeter,DistanceUnit,Volume,AccuracyPercentage'));
      expect(csvStr, contains('1,"lidar",100.000,"squareMeters",40.000,"meters",300.000,99.5'));
    });
  });
}
