import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:meassure_app/features/measurement_engine/domain/usecases/execute_measurement_usecase.dart';

void main() {
  group('ExecuteMeasurementUseCase Tests', () {
    test('executes measurement and returns converted result with algorithm precision', () {
      final useCase = ExecuteMeasurementUseCase();
      final profile = CapabilityProfile.fallbackManual();

      final result = useCase(
        ExecuteMeasurementParams(
          shape: const RectangleShape(lengthMeters: 10, widthMeters: 5),
          profile: profile,
          areaUnit: AreaUnit.squareFeet,
          distanceUnit: DistanceUnit.feet,
        ),
      );

      expect(result.algorithmUsed, equals(MeasurementAlgorithm.manual));
      expect(result.area, closeTo(538.195, 0.1)); // 50 sq meters in sq feet
      expect(result.perimeter, closeTo(98.425, 0.1)); // 30 meters in feet
      expect(result.estimatedAccuracyPercentage, equals(80.0));
    });
  });
}
