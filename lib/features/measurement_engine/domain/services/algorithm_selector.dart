import '../../../capability_detection/domain/entities/capability_profile.dart';
import '../entities/measurement_algorithm.dart';

class AlgorithmSelector {
  static MeasurementAlgorithm selectOptimalAlgorithm(CapabilityProfile profile) {
    if (!profile.permissionsGranted) {
      return MeasurementAlgorithm.manual;
    }

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
