import '../entities/measurement_result.dart';

abstract class MeasurementRepository {
  Future<void> saveMeasurementResult(String id, MeasurementResult result);
  Future<List<MeasurementResult>> getSavedMeasurementResults();
}
