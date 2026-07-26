enum MeasurementAlgorithm {
  lidar,
  depthSensor,
  arCoreArKit,
  visualSlam,
  gpsImu,
  manual,
}

extension MeasurementAlgorithmPriority on MeasurementAlgorithm {
  int get priorityIndex {
    switch (this) {
      case MeasurementAlgorithm.lidar:
        return 1;
      case MeasurementAlgorithm.depthSensor:
        return 2;
      case MeasurementAlgorithm.arCoreArKit:
        return 3;
      case MeasurementAlgorithm.visualSlam:
        return 4;
      case MeasurementAlgorithm.gpsImu:
        return 5;
      case MeasurementAlgorithm.manual:
        return 6;
    }
  }

  String get displayName {
    switch (this) {
      case MeasurementAlgorithm.lidar:
        return 'Hardware LiDAR';
      case MeasurementAlgorithm.depthSensor:
        return 'ToF Depth Sensor';
      case MeasurementAlgorithm.arCoreArKit:
        return 'ARCore / ARKit Visual-Inertial';
      case MeasurementAlgorithm.visualSlam:
        return 'Visual SLAM (Camera + AI)';
      case MeasurementAlgorithm.gpsImu:
        return 'GPS + Compass + IMU Outdoor';
      case MeasurementAlgorithm.manual:
        return 'Manual Input Fallback';
    }
  }
}
