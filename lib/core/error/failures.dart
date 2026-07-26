abstract class Failure {
  final String message;
  const Failure(this.message);
}

class HardwareDetectionFailure extends Failure {
  const HardwareDetectionFailure(super.message);
}

class MeasurementFailure extends Failure {
  const MeasurementFailure(super.message);
}

class InvalidGeometryFailure extends Failure {
  const InvalidGeometryFailure(super.message);
}
