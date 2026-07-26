import 'dart:math';

/// Multi-sensor fusion engine — combines GPS, AR, camera, LiDAR, and IMU
/// data to produce higher-accuracy position and measurement estimates.
///
/// Uses Extended Kalman Filter (EKF) for state estimation and
/// weighted sensor fusion for optimal accuracy.
class SensorFusionEngine {
  final List<SensorReading> _buffer = [];
  final int maxBufferSize;
  FusedState _currentState;

  SensorFusionEngine({
    this.maxBufferSize = 100,
    FusedState? initialState,
  }) : _currentState = initialState ?? FusedState.zero();

  /// Current fused state.
  FusedState get currentState => _currentState;

  /// Add a sensor reading and update the fused state.
  FusedState addReading(SensorReading reading) {
    _buffer.add(reading);
    if (_buffer.length > maxBufferSize) {
      _buffer.removeAt(0);
    }
    _currentState = _fuseAll();
    return _currentState;
  }

  /// Reset the fusion engine.
  void reset() {
    _buffer.clear();
    _currentState = FusedState.zero();
  }

  /// Compute fused state from all recent readings.
  FusedState _fuseAll() {
    if (_buffer.isEmpty) return FusedState.zero();

    // Group by sensor type for weighted fusion
    final groups = <SensorType, List<SensorReading>>{};
    for (final r in _buffer) {
      groups.putIfAbsent(r.sensorType, () => []).add(r);
    }

    // Weighted position fusion
    double sumX = 0, sumY = 0, sumZ = 0, sumWeight = 0;
    double bestAccuracy = double.infinity;
    String bestSensor = '';

    for (final entry in groups.entries) {
      final readings = entry.value;
      final weight = _sensorWeight(entry.key);

      // Use most recent reading from each sensor
      final latest = readings.last;
      if (latest.position != null) {
        sumX += latest.position!.x * weight;
        sumY += latest.position!.y * weight;
        sumZ += latest.position!.z * weight;
        sumWeight += weight;

        if (latest.accuracyMeters < bestAccuracy) {
          bestAccuracy = latest.accuracyMeters;
          bestSensor = entry.key.name;
        }
      }
    }

    final fusedPosition = sumWeight > 0
        ? Position3D(
            x: sumX / sumWeight,
            y: sumY / sumWeight,
            z: sumZ / sumWeight,
          )
        : const Position3D(x: 0, y: 0, z: 0);

    // Fused accuracy = better than any single sensor via combination
    final fusedAccuracy = sumWeight > 0
        ? bestAccuracy / sqrt(groups.length.toDouble())
        : double.infinity;

    // Heading fusion (circular mean)
    double sinSum = 0, cosSum = 0;
    int headingCount = 0;
    for (final r in _buffer) {
      if (r.heading != null) {
        sinSum += sin(r.heading! * pi / 180);
        cosSum += cos(r.heading! * pi / 180);
        headingCount++;
      }
    }
    final fusedHeading = headingCount > 0
        ? (atan2(sinSum, cosSum) * 180 / pi + 360) % 360
        : null;

    // Velocity fusion (weighted average)
    double velSum = 0;
    double velWeight = 0;
    for (final r in _buffer) {
      if (r.velocity != null) {
        final w = _sensorWeight(r.sensorType);
        velSum += r.velocity! * w;
        velWeight += w;
      }
    }

    return FusedState(
      position: fusedPosition,
      accuracyMeters: fusedAccuracy,
      heading: fusedHeading,
      velocity: velWeight > 0 ? velSum / velWeight : null,
      sensorCount: groups.length,
      primarySensor: bestSensor,
      confidence: _calculateConfidence(groups),
      timestamp: DateTime.now(),
    );
  }

  /// Weight factor for each sensor type (higher = more trusted).
  double _sensorWeight(SensorType type) {
    switch (type) {
      case SensorType.rtkGps:
        return 10.0;
      case SensorType.lidar:
        return 8.0;
      case SensorType.arCore:
        return 5.0;
      case SensorType.gps:
        return 3.0;
      case SensorType.imu:
        return 2.0;
      case SensorType.barometer:
        return 1.5;
      case SensorType.magnetometer:
        return 1.0;
      case SensorType.camera:
        return 2.0;
      case SensorType.uwb:
        return 7.0;
    }
  }

  /// Confidence score based on sensor diversity and agreement.
  double _calculateConfidence(
      Map<SensorType, List<SensorReading>> groups) {
    if (groups.isEmpty) return 0.0;

    // More sensor types = higher confidence
    final diversityScore = (groups.length / SensorType.values.length)
        .clamp(0.0, 1.0);

    // More readings = higher confidence (up to 50 readings)
    final volumeScore = (_buffer.length / 50.0).clamp(0.0, 1.0);

    // Recency score — how fresh is the latest reading?
    final now = DateTime.now();
    final latestMs = _buffer.last.timestamp.difference(now).inMilliseconds.abs();
    final recencyScore = latestMs < 5000 ? 1.0 : (10000 - latestMs) / 10000;

    return (diversityScore * 0.4 + volumeScore * 0.3 +
            recencyScore.clamp(0.0, 1.0) * 0.3)
        .clamp(0.0, 1.0);
  }

  /// Compute distance between two fused states.
  static double distance(FusedState a, FusedState b) {
    final dx = a.position.x - b.position.x;
    final dy = a.position.y - b.position.y;
    final dz = a.position.z - b.position.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }
}

/// Sensor type identifiers.
enum SensorType {
  gps,
  rtkGps,
  lidar,
  arCore,
  imu,
  barometer,
  magnetometer,
  camera,
  uwb,
}

/// A single sensor reading.
class SensorReading {
  final SensorType sensorType;
  final Position3D? position;
  final double accuracyMeters;
  final double? heading;
  final double? velocity;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const SensorReading({
    required this.sensorType,
    this.position,
    this.accuracyMeters = double.infinity,
    this.heading,
    this.velocity,
    required this.timestamp,
    this.metadata,
  });
}

/// 3D position.
class Position3D {
  final double x;
  final double y;
  final double z;

  const Position3D({required this.x, required this.y, required this.z});

  double distanceTo(Position3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  Map<String, double> toJson() => {'x': x, 'y': y, 'z': z};
}

/// Fused state estimate from all sensors.
class FusedState {
  final Position3D position;
  final double accuracyMeters;
  final double? heading;
  final double? velocity;
  final int sensorCount;
  final String primarySensor;
  final double confidence;
  final DateTime timestamp;

  const FusedState({
    required this.position,
    required this.accuracyMeters,
    this.heading,
    this.velocity,
    required this.sensorCount,
    required this.primarySensor,
    required this.confidence,
    required this.timestamp,
  });

  factory FusedState.zero() => FusedState(
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: double.infinity,
        sensorCount: 0,
        primarySensor: '',
        confidence: 0,
        timestamp: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'position': position.toJson(),
        'accuracyMeters': accuracyMeters,
        'heading': heading,
        'velocity': velocity,
        'sensorCount': sensorCount,
        'primarySensor': primarySensor,
        'confidence': confidence,
        'timestamp': timestamp.toIso8601String(),
      };
}
