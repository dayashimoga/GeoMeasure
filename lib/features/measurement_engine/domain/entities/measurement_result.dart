import 'measurement_algorithm.dart';
import 'measurement_unit.dart';

class MeasurementResult {
  final double area;
  final AreaUnit areaUnit;
  final double perimeter;
  final DistanceUnit distanceUnit;
  final double volume;
  final MeasurementAlgorithm algorithmUsed;
  final double estimatedAccuracyPercentage;

  const MeasurementResult({
    required this.area,
    required this.areaUnit,
    required this.perimeter,
    required this.distanceUnit,
    required this.volume,
    required this.algorithmUsed,
    required this.estimatedAccuracyPercentage,
  });
}
