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
  final String shapeName;

  const ExecuteMeasurementParams({
    required this.shape,
    required this.profile,
    this.distanceUnit = DistanceUnit.meters,
    this.areaUnit = AreaUnit.squareMeters,
    this.shapeName = '',
  });
}

class ExecuteMeasurementUseCase {
  MeasurementResult call(ExecuteMeasurementParams params) {
    // E4: Validate shape inputs
    final validationError = params.shape.validate();
    if (validationError != null) {
      return MeasurementResult(
        area: 0,
        areaUnit: params.areaUnit,
        perimeter: 0,
        distanceUnit: params.distanceUnit,
        volume: 0,
        algorithmUsed: MeasurementAlgorithm.manual,
        estimatedAccuracyPercentage: 0,
        shapeType: params.shape.type,
        shapeName: 'INVALID: $validationError',
      );
    }

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

    double accuracy;
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
      shapeType: params.shape.type,
      shapeName: params.shapeName,
    );
  }
}
