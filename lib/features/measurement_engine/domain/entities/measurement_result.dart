import 'measurement_algorithm.dart';
import 'measurement_unit.dart';
import 'spatial_shape.dart';

class MeasurementResult {
  final double area;
  final AreaUnit areaUnit;
  final double perimeter;
  final DistanceUnit distanceUnit;
  final double volume;
  final MeasurementAlgorithm algorithmUsed;
  final double estimatedAccuracyPercentage;
  final DateTime timestamp;
  final ShapeType shapeType;
  final String shapeName;

  MeasurementResult({
    required this.area,
    required this.areaUnit,
    required this.perimeter,
    required this.distanceUnit,
    required this.volume,
    required this.algorithmUsed,
    required this.estimatedAccuracyPercentage,
    DateTime? timestamp,
    required this.shapeType,
    this.shapeName = '',
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'area': area,
        'areaUnit': areaUnit.name,
        'perimeter': perimeter,
        'distanceUnit': distanceUnit.name,
        'volume': volume,
        'algorithmUsed': algorithmUsed.name,
        'estimatedAccuracyPercentage': estimatedAccuracyPercentage,
        'timestamp': timestamp.toIso8601String(),
        'shapeType': shapeType.name,
        'shapeName': shapeName,
      };

  factory MeasurementResult.fromJson(Map<String, dynamic> map) {
    return MeasurementResult(
      area: (map['area'] as num).toDouble(),
      areaUnit: AreaUnit.values.firstWhere((e) => e.name == map['areaUnit']),
      perimeter: (map['perimeter'] as num).toDouble(),
      distanceUnit: DistanceUnit.values.firstWhere((e) => e.name == map['distanceUnit']),
      volume: (map['volume'] as num).toDouble(),
      algorithmUsed: MeasurementAlgorithm.values.firstWhere((e) => e.name == map['algorithmUsed']),
      estimatedAccuracyPercentage: (map['estimatedAccuracyPercentage'] as num).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      shapeType: ShapeType.values.firstWhere(
        (e) => e.name == map['shapeType'],
        orElse: () => ShapeType.rectangle,
      ),
      shapeName: map['shapeName'] as String? ?? '',
    );
  }
}
