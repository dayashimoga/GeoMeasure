import 'dart:convert';
import '../../domain/entities/measurement_result.dart';
import '../../domain/entities/measurement_unit.dart';
import '../../domain/entities/measurement_algorithm.dart';

abstract class MeasurementLocalDataSource {
  Future<void> saveMeasurement(String id, MeasurementResult result);
  Future<List<MeasurementResult>> getAllSavedMeasurements();
}

class MeasurementLocalDataSourceImpl implements MeasurementLocalDataSource {
  final Map<String, String> _inMemoryStore = {};

  @override
  Future<void> saveMeasurement(String id, MeasurementResult result) async {
    final Map<String, dynamic> jsonMap = {
      'id': id,
      'area': result.area,
      'areaUnit': result.areaUnit.name,
      'perimeter': result.perimeter,
      'distanceUnit': result.distanceUnit.name,
      'volume': result.volume,
      'algorithmUsed': result.algorithmUsed.name,
      'estimatedAccuracyPercentage': result.estimatedAccuracyPercentage,
    };
    _inMemoryStore[id] = jsonEncode(jsonMap);
  }

  @override
  Future<List<MeasurementResult>> getAllSavedMeasurements() async {
    final List<MeasurementResult> list = [];
    for (final jsonStr in _inMemoryStore.values) {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      list.add(
        MeasurementResult(
          area: (map['area'] as num).toDouble(),
          areaUnit: AreaUnit.values.firstWhere((e) => e.name == map['areaUnit']),
          perimeter: (map['perimeter'] as num).toDouble(),
          distanceUnit: DistanceUnit.values.firstWhere((e) => e.name == map['distanceUnit']),
          volume: (map['volume'] as num).toDouble(),
          algorithmUsed: MeasurementAlgorithm.values.firstWhere((e) => e.name == map['algorithmUsed']),
          estimatedAccuracyPercentage: (map['estimatedAccuracyPercentage'] as num).toDouble(),
        ),
      );
    }
    return list;
  }
}
