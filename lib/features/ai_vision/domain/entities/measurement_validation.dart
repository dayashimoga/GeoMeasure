import '../../../measurement_engine/domain/entities/precision_mode.dart';

/// Comprehensive measurement validation metadata.
///
/// Every measurement should provide transparency about its
/// accuracy, method, and conditions.
class MeasurementValidation {
  /// Overall confidence in the measurement (0.0–1.0).
  final double confidenceScore;

  /// Estimated accuracy in the measurement unit.
  final double estimatedAccuracy;

  /// Error margin (±) in meters.
  final double errorMarginMeters;

  /// Which sensor(s) produced the measurement.
  final String sensorUsed;

  /// The algorithm or method used.
  final String measurementMethod;

  /// Device calibration status.
  final CalibrationStatus calibrationStatus;

  /// Precision mode used.
  final PrecisionMode precisionMode;

  /// Timestamp of measurement.
  final DateTime timestamp;

  /// Environmental conditions during measurement.
  final EnvironmentalConditions? environment;

  /// Number of samples averaged.
  final int sampleCount;

  /// Standard deviation across samples (lower = more consistent).
  final double standardDeviation;

  const MeasurementValidation({
    required this.confidenceScore,
    required this.estimatedAccuracy,
    this.errorMarginMeters = 0.0,
    this.sensorUsed = 'device_default',
    this.measurementMethod = 'direct',
    this.calibrationStatus = CalibrationStatus.uncalibrated,
    this.precisionMode = PrecisionMode.balanced,
    required this.timestamp,
    this.environment,
    this.sampleCount = 1,
    this.standardDeviation = 0.0,
  });

  /// Quality grade based on confidence and accuracy.
  MeasurementGrade get grade {
    if (confidenceScore >= 0.95 && errorMarginMeters <= 0.01) {
      return MeasurementGrade.surveyGrade;
    }
    if (confidenceScore >= 0.90 && errorMarginMeters <= 0.05) {
      return MeasurementGrade.highAccuracy;
    }
    if (confidenceScore >= 0.75 && errorMarginMeters <= 0.2) {
      return MeasurementGrade.standard;
    }
    if (confidenceScore >= 0.5) {
      return MeasurementGrade.estimate;
    }
    return MeasurementGrade.rough;
  }

  Map<String, dynamic> toJson() => {
        'confidenceScore': confidenceScore,
        'estimatedAccuracy': estimatedAccuracy,
        'errorMarginMeters': errorMarginMeters,
        'sensorUsed': sensorUsed,
        'measurementMethod': measurementMethod,
        'calibrationStatus': calibrationStatus.name,
        'precisionMode': precisionMode.name,
        'timestamp': timestamp.toIso8601String(),
        'sampleCount': sampleCount,
        'standardDeviation': standardDeviation,
        'grade': grade.name,
      };

  factory MeasurementValidation.fromJson(Map<String, dynamic> m) =>
      MeasurementValidation(
        confidenceScore: (m['confidenceScore'] as num).toDouble(),
        estimatedAccuracy: (m['estimatedAccuracy'] as num).toDouble(),
        errorMarginMeters: (m['errorMarginMeters'] as num?)?.toDouble() ?? 0.0,
        sensorUsed: m['sensorUsed'] as String? ?? 'device_default',
        measurementMethod: m['measurementMethod'] as String? ?? 'direct',
        calibrationStatus: CalibrationStatus.values.firstWhere(
          (e) => e.name == (m['calibrationStatus'] as String?),
          orElse: () => CalibrationStatus.uncalibrated,
        ),
        precisionMode: PrecisionMode.values.firstWhere(
          (e) => e.name == (m['precisionMode'] as String?),
          orElse: () => PrecisionMode.balanced,
        ),
        timestamp: DateTime.tryParse(m['timestamp'] as String? ?? '') ??
            DateTime.now(),
        sampleCount: m['sampleCount'] as int? ?? 1,
        standardDeviation: (m['standardDeviation'] as num?)?.toDouble() ?? 0.0,
      );
}

enum CalibrationStatus {
  uncalibrated,
  autoCalibratedGood,
  autoCalibratedFair,
  manuallyCalibratedRecent,
  manuallyCalibratedStale,
  calibrationRequired,
}

enum MeasurementGrade {
  /// ±1cm or better, 95%+ confidence.
  surveyGrade,

  /// ±5cm, 90%+ confidence.
  highAccuracy,

  /// ±20cm, 75%+ confidence.
  standard,

  /// ±50cm, 50%+ confidence.
  estimate,

  /// >50cm error, below 50% confidence.
  rough,
}

/// Environmental conditions affecting measurement quality.
class EnvironmentalConditions {
  final double? lightLevel; // lux
  final double? temperature; // celsius
  final bool? isOutdoor;
  final bool? isMoving;
  final double? vibrationLevel;

  const EnvironmentalConditions({
    this.lightLevel,
    this.temperature,
    this.isOutdoor,
    this.isMoving,
    this.vibrationLevel,
  });

  Map<String, dynamic> toJson() => {
        'lightLevel': lightLevel,
        'temperature': temperature,
        'isOutdoor': isOutdoor,
        'isMoving': isMoving,
        'vibrationLevel': vibrationLevel,
      };
}
