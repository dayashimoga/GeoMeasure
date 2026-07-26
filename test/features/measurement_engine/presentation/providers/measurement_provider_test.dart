import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:meassure_app/features/measurement_engine/data/datasources/measurement_local_datasource.dart';
import 'package:meassure_app/features/measurement_engine/data/repositories/measurement_repository_impl.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:meassure_app/features/measurement_engine/domain/usecases/execute_measurement_usecase.dart';
import 'package:meassure_app/features/measurement_engine/presentation/providers/measurement_provider.dart';

void main() {
  group('MeasurementProvider State & Export Tests', () {
    test('calculateMeasurement computes result and stores history', () {
      final dataSource = MeasurementLocalDataSourceImpl();
      final repository = MeasurementRepositoryImpl(dataSource);
      final useCase = ExecuteMeasurementUseCase();
      final provider = MeasurementProvider(
        executeMeasurementUseCase: useCase,
        repository: repository,
      );

      provider.updateUnits(areaUnit: AreaUnit.squareMeters, distanceUnit: DistanceUnit.meters);

      provider.calculateMeasurement(
        shape: const RectangleShape(lengthMeters: 10, widthMeters: 5),
        profile: CapabilityProfile.fallbackManual(),
      );

      expect(provider.lastResult, isNotNull);
      expect(provider.history.length, equals(1));
      expect(provider.exportCurrentToDxf(), contains('ENTITIES'));
    });
  });
}
