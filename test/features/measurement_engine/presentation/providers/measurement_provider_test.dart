import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:geomeasure/features/measurement_engine/data/datasources/measurement_local_datasource.dart';
import 'package:geomeasure/features/measurement_engine/data/repositories/measurement_repository_impl.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/usecases/execute_measurement_usecase.dart';
import 'package:geomeasure/features/measurement_engine/presentation/providers/measurement_provider.dart';

void main() {
  group('MeasurementProvider', () {
    late MeasurementProvider provider;

    setUp(() {
      final dataSource = MeasurementLocalDataSourceImpl();
      final repository = MeasurementRepositoryImpl(dataSource);
      final useCase = ExecuteMeasurementUseCase();
      provider = MeasurementProvider(
        executeMeasurementUseCase: useCase,
        repository: repository,
      );
    });

    test('calculateMeasurement stores result and appends to history', () {
      provider.calculateMeasurement(
        shape: const RectangleShape(lengthMeters: 10, widthMeters: 5),
        profile: CapabilityProfile.fallbackManual(),
        shapeName: 'Test Room',
      );
      expect(provider.lastResult, isNotNull);
      expect(provider.history.length, 1);
      expect(provider.lastResult!.shapeName, 'Test Room');
    });

    test('G13 fix: updateUnits recalculates last measurement', () {
      provider.calculateMeasurement(
        shape: const RectangleShape(lengthMeters: 10, widthMeters: 5),
        profile: CapabilityProfile.fallbackManual(),
      );
      final areaInSqM = provider.lastResult!.area;

      provider.updateUnits(areaUnit: AreaUnit.squareFeet);
      expect(provider.lastResult!.areaUnit, AreaUnit.squareFeet);
      expect(provider.lastResult!.area, greaterThan(areaInSqM));
    });

    test('exportCurrentToDxf returns DXF string', () {
      provider.calculateMeasurement(
        shape: const RectangleShape(lengthMeters: 5, widthMeters: 3),
        profile: CapabilityProfile.fallbackManual(),
      );
      expect(provider.exportCurrentToDxf(), contains('ENTITIES'));
    });

    test('exportHistoryToCsv returns CSV with header', () {
      provider.calculateMeasurement(
        shape: const RectangleShape(lengthMeters: 5, widthMeters: 3),
        profile: CapabilityProfile.fallbackManual(),
      );
      final csv = provider.exportHistoryToCsv();
      expect(csv, contains('ID,Technique'));
    });
  });
}
