import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/data/datasources/measurement_local_datasource.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';

void main() {
  group('MeasurementLocalDataSource — Persistence Round-Trip', () {
    late MeasurementLocalDataSourceImpl dataSource;

    setUp(() {
      dataSource = MeasurementLocalDataSourceImpl();
    });

    test('save and retrieve measurement result with toJson/fromJson', () async {
      final result = MeasurementResult(
        area: 50.0,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 30.0,
        distanceUnit: DistanceUnit.meters,
        volume: 150.0,
        algorithmUsed: MeasurementAlgorithm.arCoreArKit,
        estimatedAccuracyPercentage: 95.0,
        shapeType: ShapeType.room,
        shapeName: 'Bedroom',
      );

      await dataSource.saveMeasurement('test-1', result);
      final loaded = await dataSource.getAllSavedMeasurements();

      expect(loaded.length, 1);
      expect(loaded.first.area, 50.0);
      expect(loaded.first.algorithmUsed, MeasurementAlgorithm.arCoreArKit);
      expect(loaded.first.shapeType, ShapeType.room);
      expect(loaded.first.shapeName, 'Bedroom');
    });

    test('delete removes single measurement', () async {
      final result = MeasurementResult(
        area: 10,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 20,
        distanceUnit: DistanceUnit.meters,
        volume: 0,
        algorithmUsed: MeasurementAlgorithm.manual,
        estimatedAccuracyPercentage: 80,
        shapeType: ShapeType.rectangle,
      );

      await dataSource.saveMeasurement('a', result);
      await dataSource.saveMeasurement('b', result);
      await dataSource.deleteMeasurement('a');

      final loaded = await dataSource.getAllSavedMeasurements();
      expect(loaded.length, 1);
    });

    test('clearAll removes everything', () async {
      final result = MeasurementResult(
        area: 10,
        areaUnit: AreaUnit.squareMeters,
        perimeter: 20,
        distanceUnit: DistanceUnit.meters,
        volume: 0,
        algorithmUsed: MeasurementAlgorithm.manual,
        estimatedAccuracyPercentage: 80,
        shapeType: ShapeType.rectangle,
      );

      await dataSource.saveMeasurement('x', result);
      await dataSource.clearAll();

      final loaded = await dataSource.getAllSavedMeasurements();
      expect(loaded, isEmpty);
    });
  });
}
