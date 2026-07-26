import '../../../capability_detection/domain/entities/capability_profile.dart';
import '../../../capability_detection/domain/entities/sensor_type.dart';
import '../entities/measurement_algorithm.dart';

class AlgorithmSelector {
  /// Selects the highest-accuracy algorithm available given the device profile.
  /// Applies thermal throttle and low-battery guards before hardware checks.
  static MeasurementAlgorithm selectOptimalAlgorithm(
    CapabilityProfile profile,
  ) {
    if (!profile.permissionsGranted) {
      return MeasurementAlgorithm.manual;
    }

    // Thermal throttle guard — critical thermal state forces manual
    if (profile.thermalState == ThermalState.critical) {
      return MeasurementAlgorithm.manual;
    }

    // Low battery guard — below 10% forces GPS or manual to save power
    if (profile.batteryLevel < 0.10) {
      if (profile.hasGps && profile.hasCompass) {
        return MeasurementAlgorithm.gpsImu;
      }
      return MeasurementAlgorithm.manual;
    }

    // Serious thermal — skip heavy compute (LiDAR/Depth/AR), allow GPS or manual
    if (profile.thermalState == ThermalState.serious) {
      if (profile.hasGps && profile.hasCompass) {
        return MeasurementAlgorithm.gpsImu;
      }
      return MeasurementAlgorithm.manual;
    }

    // Standard priority hierarchy
    if (profile.hasLidar) {
      return MeasurementAlgorithm.lidar;
    }

    if (profile.hasDepthSensor) {
      return MeasurementAlgorithm.depthSensor;
    }

    if (profile.hasArCore || profile.hasArKit) {
      return MeasurementAlgorithm.arCoreArKit;
    }

    if (profile.hasCamera) {
      return MeasurementAlgorithm.visualSlam;
    }

    if (profile.hasGps && profile.hasCompass) {
      return MeasurementAlgorithm.gpsImu;
    }

    return MeasurementAlgorithm.manual;
  }
}
