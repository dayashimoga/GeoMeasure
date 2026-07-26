import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/usecases/execute_measurement_usecase.dart';

void main() {
  group('ExecuteMeasurementUseCase', () {
    test('executes measurement with manual fallback profile', () {
      final useCase = ExecuteMeasurementUseCase();
      final result = useCase(ExecuteMeasurementParams(
        shape: const RectangleShape(lengthMeters: 10, widthMeters: 5),
        profile: CapabilityProfile.fallbackManual(),
        areaUnit: AreaUnit.squareFeet,
        distanceUnit: DistanceUnit.feet,
        shapeName: 'Living Room',
      ));

      expect(result.algorithmUsed, MeasurementAlgorithm.manual);
      expect(result.area, closeTo(538.195, 0.5));
      expect(result.perimeter, closeTo(98.425, 0.5));
      expect(result.estimatedAccuracyPercentage, 80.0);
      expect(result.shapeType, ShapeType.rectangle);
      expect(result.shapeName, 'Living Room');
    });

    test('returns zero result with INVALID label for degenerate shape', () {
      final useCase = ExecuteMeasurementUseCase();
      final result = useCase(ExecuteMeasurementParams(
        shape: const TriangleShape(sideA: 1, sideB: 2, sideC: 3),
        profile: CapabilityProfile.fallbackManual(),
      ));

      expect(result.area, 0);
      expect(result.perimeter, 0);
      expect(result.estimatedAccuracyPercentage, 0);
      expect(result.shapeName, contains('INVALID'));
    });
  });
}
