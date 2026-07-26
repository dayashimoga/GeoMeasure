import '../../../capability_detection/domain/entities/capability_profile.dart';
import '../entities/measurement_algorithm.dart';
import '../entities/measurement_result.dart';
import '../entities/measurement_unit.dart';
import '../entities/spatial_shape.dart';
import '../services/algorithm_selector.dart';
import '../services/unit_converter.dart';

class ExecuteMeasurementParams {
  final SpatialShape shape;
  final CapabilityProfile profile;
  final DistanceUnit distanceUnit;
  final AreaUnit areaUnit;

  const ExecuteMeasurementParams({
    required this.shape,
    required this.profile,
    this.distanceUnit = DistanceUnit.meters,
    this.areaUnit = AreaUnit.squareMeters,
  });
}

class ExecuteMeasurementUseCase {
  MeasurementResult call(ExecuteMeasurementParams params) {
    final algorithm = AlgorithmSelector.selectOptimalAlgorithm(params.profile);

    final rawAreaSqMeters = params.shape.calculateAreaInSquareMeters();
    final rawPerimeterMeters = params.shape.calculatePerimeterInMeters();
    final rawVolumeCubicMeters = params.shape.calculateVolumeInCubicMeters();

    final convertedArea = UnitConverter.convertArea(
      valueSqMeters: rawAreaSqMeters,
      targetUnit: params.areaUnit,
    );

    final convertedPerimeter = UnitConverter.convertDistance(
      valueMeters: rawPerimeterMeters,
      targetUnit: params.distanceUnit,
    );

    double accuracy = 99.0;
    switch (algorithm) {
      case MeasurementAlgorithm.lidar:
        accuracy = 99.5;
        break;
      case MeasurementAlgorithm.depthSensor:
        accuracy = 97.0;
        break;
      case MeasurementAlgorithm.arCoreArKit:
        accuracy = 95.0;
        break;
      case MeasurementAlgorithm.visualSlam:
        accuracy = 90.0;
        break;
      case MeasurementAlgorithm.gpsImu:
        accuracy = 85.0;
        break;
      case MeasurementAlgorithm.manual:
        accuracy = 80.0;
        break;
    }

    return MeasurementResult(
      area: convertedArea,
      areaUnit: params.areaUnit,
      perimeter: convertedPerimeter,
      distanceUnit: params.distanceUnit,
      volume: rawVolumeCubicMeters,
      algorithmUsed: algorithm,
      estimatedAccuracyPercentage: accuracy,
    );
  }
}
