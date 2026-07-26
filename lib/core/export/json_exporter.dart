import 'dart:convert';
import '../../features/measurement_engine/domain/entities/measurement_result.dart';
import '../../features/estimation/domain/entities/material_estimate.dart';

/// JSON exporter for measurements and reports.
///
/// Exports MeasurementResult lists, QuantityTakeoffs, and CostEstimates
/// as formatted JSON strings.
class JsonExporter {
  /// Export a single measurement result as pretty JSON.
  static String exportResult(MeasurementResult result) {
    return const JsonEncoder.withIndent('  ').convert(result.toJson());
  }

  /// Export a list of measurement results as a JSON array.
  static String exportHistory(List<MeasurementResult> results) {
    final list = results.map((r) => r.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'count': results.length,
      'measurements': list,
    });
  }

  /// Export a quantity take-off as JSON.
  static String exportTakeoff(QuantityTakeoff takeoff) {
    return const JsonEncoder.withIndent('  ').convert(takeoff.toJson());
  }

  /// Export a cost estimate as JSON.
  static String exportCostEstimate(CostEstimate estimate) {
    return const JsonEncoder.withIndent('  ').convert({
      'costEstimate': estimate.toJson(),
      'materials': estimate.materials.toJson(),
      'generatedAt': DateTime.now().toIso8601String(),
    });
  }

  /// Export any serializable map as pretty JSON.
  static String exportMap(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
