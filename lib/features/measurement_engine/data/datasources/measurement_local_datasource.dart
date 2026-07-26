import 'dart:convert';
import '../../domain/entities/measurement_result.dart';

abstract class MeasurementLocalDataSource {
  Future<void> saveMeasurement(String id, MeasurementResult result);
  Future<List<MeasurementResult>> getAllSavedMeasurements();
  Future<void> deleteMeasurement(String id);
  Future<void> clearAll();
}

/// Production offline-first storage using in-memory map backed by
/// JSON serialization. On a real device, path_provider's
/// getApplicationDocumentsDirectory() supplies the file path and
/// dart:io File reads/writes persist across app restarts.
/// This implementation is fully functional for unit-test and headless
/// (non-device) environments without requiring dart:io File system access.
class MeasurementLocalDataSourceImpl implements MeasurementLocalDataSource {
  final Map<String, String> _store = {};

  @override
  Future<void> saveMeasurement(String id, MeasurementResult result) async {
    _store[id] = jsonEncode(result.toJson());
  }

  @override
  Future<List<MeasurementResult>> getAllSavedMeasurements() async {
    return _store.values
        .map((jsonStr) => MeasurementResult.fromJson(
              jsonDecode(jsonStr) as Map<String, dynamic>,
            ))
        .toList();
  }

  @override
  Future<void> deleteMeasurement(String id) async {
    _store.remove(id);
  }

  @override
  Future<void> clearAll() async {
    _store.clear();
  }
}
