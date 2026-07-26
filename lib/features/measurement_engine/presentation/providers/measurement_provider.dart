import 'package:flutter/foundation.dart';
import '../../../capability_detection/domain/entities/capability_profile.dart';
import '../../domain/entities/measurement_result.dart';
import '../../domain/entities/measurement_unit.dart';
import '../../domain/entities/spatial_shape.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../../domain/services/csv_exporter.dart';
import '../../domain/services/dxf_exporter.dart';
import '../../domain/services/geojson_exporter.dart';
import '../../domain/usecases/execute_measurement_usecase.dart';

class MeasurementProvider extends ChangeNotifier {
  final ExecuteMeasurementUseCase executeMeasurementUseCase;
  final MeasurementRepository? repository;

  AreaUnit _targetAreaUnit = AreaUnit.squareMeters;
  DistanceUnit _targetDistanceUnit = DistanceUnit.meters;
  MeasurementResult? _lastResult;
  SpatialShape? _lastShape;
  List<MeasurementResult> _history = [];

  AreaUnit get targetAreaUnit => _targetAreaUnit;
  DistanceUnit get targetDistanceUnit => _targetDistanceUnit;
  MeasurementResult? get lastResult => _lastResult;
  SpatialShape? get lastShape => _lastShape;
  List<MeasurementResult> get history => _history;

  MeasurementProvider({
    required this.executeMeasurementUseCase,
    this.repository,
  });

  void updateUnits({AreaUnit? areaUnit, DistanceUnit? distanceUnit}) {
    if (areaUnit != null) _targetAreaUnit = areaUnit;
    if (distanceUnit != null) _targetDistanceUnit = distanceUnit;

    // Recalculate last measurement if present
    if (_lastShape != null && _lastResult != null) {
      // Re-run with updated unit selections
    }
    notifyListeners();
  }

  void calculateMeasurement({
    required SpatialShape shape,
    required CapabilityProfile profile,
  }) {
    _lastShape = shape;
    _lastResult = executeMeasurementUseCase(
      ExecuteMeasurementParams(
        shape: shape,
        profile: profile,
        areaUnit: _targetAreaUnit,
        distanceUnit: _targetDistanceUnit,
      ),
    );
    if (_lastResult != null) {
      _history.add(_lastResult!);
      if (repository != null) {
        repository!.saveMeasurementResult(
          DateTime.now().millisecondsSinceEpoch.toString(),
          _lastResult!,
        );
      }
    }
    notifyListeners();
  }

  String exportCurrentToDxf() {
    if (_lastShape == null) return '';
    return DxfExporter.generateDxf(_lastShape!);
  }

  String exportPlotToGeoJson() {
    if (_lastShape is PlotShape) {
      return GeoJsonExporter.generateGeoJson(_lastShape as PlotShape);
    }
    return '';
  }

  String exportHistoryToCsv() {
    return CsvExporter.generateCsv(_history);
  }
}
