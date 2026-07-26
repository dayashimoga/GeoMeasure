import '../../domain/entities/measurement_result.dart';
import '../../domain/repositories/measurement_repository.dart';
import '../datasources/measurement_local_datasource.dart';

class MeasurementRepositoryImpl implements MeasurementRepository {
  final MeasurementLocalDataSource dataSource;

  MeasurementRepositoryImpl(this.dataSource);

  @override
  Future<void> saveMeasurementResult(
    String id,
    MeasurementResult result,
  ) async {
    await dataSource.saveMeasurement(id, result);
  }

  @override
  Future<List<MeasurementResult>> getSavedMeasurementResults() async {
    return await dataSource.getAllSavedMeasurements();
  }

  @override
  Future<void> deleteMeasurementResult(String id) async {
    await dataSource.deleteMeasurement(id);
  }

  @override
  Future<void> clearAllResults() async {
    await dataSource.clearAll();
  }
}
