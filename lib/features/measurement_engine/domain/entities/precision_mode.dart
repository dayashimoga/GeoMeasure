/// Precision mode for measurement operations.
///
/// Determines accuracy target, sensor selection, sample count, and timeout.
/// The measurement engine automatically selects the best available mode
/// based on device capabilities.
enum PrecisionMode {
  /// Fastest results. Single sample. ±50cm accuracy typical.
  fast,

  /// Default mode. 3-5 samples averaged. ±10cm accuracy typical.
  balanced,

  /// Maximum on-device accuracy. 10+ samples. ±2cm accuracy typical.
  highAccuracy,

  /// Survey-grade. Requires external GNSS or RTK base station.
  /// ±1cm accuracy typical.
  professionalSurvey,

  /// RTK-corrected GPS. Requires NTRIP connection.
  /// ±2cm horizontal, ±3cm vertical.
  rtkGps,

  /// LiDAR time-of-flight sensor. ±1mm at short range.
  lidar,

  /// User manually verifies and adjusts every measurement.
  /// Accuracy depends on user skill.
  manualVerification,
}

/// Configuration for a precision mode.
class PrecisionConfig {
  final PrecisionMode mode;
  final double accuracyTargetMeters;
  final int sampleCount;
  final Duration timeout;
  final bool requiresCalibration;
  final bool requiresExternalHardware;
  final String description;

  const PrecisionConfig({
    required this.mode,
    required this.accuracyTargetMeters,
    required this.sampleCount,
    required this.timeout,
    this.requiresCalibration = false,
    this.requiresExternalHardware = false,
    required this.description,
  });

  /// Default configurations for each precision mode.
  static const Map<PrecisionMode, PrecisionConfig> defaults = {
    PrecisionMode.fast: PrecisionConfig(
      mode: PrecisionMode.fast,
      accuracyTargetMeters: 0.5,
      sampleCount: 1,
      timeout: Duration(seconds: 2),
      description: 'Single-shot measurement for quick estimates',
    ),
    PrecisionMode.balanced: PrecisionConfig(
      mode: PrecisionMode.balanced,
      accuracyTargetMeters: 0.1,
      sampleCount: 5,
      timeout: Duration(seconds: 10),
      description: 'Averaged multi-sample for reliable results',
    ),
    PrecisionMode.highAccuracy: PrecisionConfig(
      mode: PrecisionMode.highAccuracy,
      accuracyTargetMeters: 0.02,
      sampleCount: 15,
      timeout: Duration(seconds: 30),
      requiresCalibration: true,
      description: 'High-precision mode using all available sensors',
    ),
    PrecisionMode.professionalSurvey: PrecisionConfig(
      mode: PrecisionMode.professionalSurvey,
      accuracyTargetMeters: 0.01,
      sampleCount: 30,
      timeout: Duration(seconds: 60),
      requiresCalibration: true,
      requiresExternalHardware: true,
      description: 'Survey-grade with external GNSS receiver',
    ),
    PrecisionMode.rtkGps: PrecisionConfig(
      mode: PrecisionMode.rtkGps,
      accuracyTargetMeters: 0.02,
      sampleCount: 20,
      timeout: Duration(seconds: 45),
      requiresExternalHardware: true,
      description: 'RTK-corrected GPS via NTRIP caster',
    ),
    PrecisionMode.lidar: PrecisionConfig(
      mode: PrecisionMode.lidar,
      accuracyTargetMeters: 0.001,
      sampleCount: 10,
      timeout: Duration(seconds: 5),
      description: 'LiDAR time-of-flight for mm precision',
    ),
    PrecisionMode.manualVerification: PrecisionConfig(
      mode: PrecisionMode.manualVerification,
      accuracyTargetMeters: 0.05,
      sampleCount: 1,
      timeout: Duration(minutes: 5),
      description: 'User verifies each measurement point',
    ),
  };

  /// Get the default config for a mode.
  static PrecisionConfig forMode(PrecisionMode mode) =>
      defaults[mode] ?? defaults[PrecisionMode.balanced]!;

  Map<String, dynamic> toJson() => {
        'mode': mode.name,
        'accuracyTargetMeters': accuracyTargetMeters,
        'sampleCount': sampleCount,
        'timeoutMs': timeout.inMilliseconds,
        'requiresCalibration': requiresCalibration,
        'requiresExternalHardware': requiresExternalHardware,
        'description': description,
      };
}
