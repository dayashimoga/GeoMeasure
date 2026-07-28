import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/sensor_fusion.dart';

/// Simulated sensor data streams for testing sensor fusion accuracy.
///
/// Tests verify that SensorFusionEngine correctly fuses multiple sensor
/// inputs, handles noise, degraded sensors, and produces accurate results.
void main() {
  group('SensorFusionEngine — Simulation', () {
    late SensorFusionEngine engine;

    setUp(() {
      engine = SensorFusionEngine(maxBufferSize: 50);
    });

    test('initial state is zero', () {
      final state = engine.currentState;
      expect(state.position.x, equals(0.0));
      expect(state.position.y, equals(0.0));
      expect(state.sensorCount, equals(0));
      expect(state.confidence, equals(0.0));
    });

    test('single GPS reading updates position', () {
      final state = engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 12.9716, y: 77.5946, z: 920),
        accuracyMeters: 3.0,
        timestamp: DateTime.now(),
      ));
      expect(state.position.x, closeTo(12.9716, 0.01));
      expect(state.position.y, closeTo(77.5946, 0.01));
      expect(state.sensorCount, equals(1));
      expect(state.primarySensor, equals('gps'));
    });

    test('multi-sensor fusion improves accuracy', () {
      // GPS reading (accuracy 5m)
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 10, y: 20, z: 0),
        accuracyMeters: 5.0,
        timestamp: DateTime.now(),
      ));

      // LiDAR reading (accuracy 0.02m)
      final fused = engine.addReading(SensorReading(
        sensorType: SensorType.lidar,
        position: const Position3D(x: 10.1, y: 20.1, z: 0),
        accuracyMeters: 0.02,
        timestamp: DateTime.now(),
      ));

      // Fused accuracy should be better than single sensor
      expect(fused.accuracyMeters, lessThan(5.0));
      expect(fused.sensorCount, equals(2));
      expect(fused.primarySensor, equals('lidar'));
    });

    test('LiDAR dominates position in fusion', () {
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: 5.0,
        timestamp: DateTime.now(),
      ));

      final fused = engine.addReading(SensorReading(
        sensorType: SensorType.lidar,
        position: const Position3D(x: 100, y: 100, z: 0),
        accuracyMeters: 0.02,
        timestamp: DateTime.now(),
      ));

      // LiDAR has weight 8.0, GPS weight 3.0 → position biased toward LiDAR
      expect(fused.position.x, greaterThan(50)); // Closer to LiDAR's 100
    });

    test('heading fusion uses circular mean', () {
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: 5.0,
        heading: 10.0,
        timestamp: DateTime.now(),
      ));

      final fused = engine.addReading(SensorReading(
        sensorType: SensorType.magnetometer,
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: 1.0,
        heading: 350.0, // Close to 0° on other side
        timestamp: DateTime.now(),
      ));

      // Circular mean of 10° and 350° should be near 0°
      expect(fused.heading, isNotNull);
      final h = fused.heading!;
      expect(h < 20 || h > 340, isTrue,
          reason: 'Heading should be near 0° (circular mean of 10° and 350°)');
    });

    test('velocity fusion weighted average', () {
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: 3.0,
        velocity: 5.0,
        timestamp: DateTime.now(),
      ));

      final fused = engine.addReading(SensorReading(
        sensorType: SensorType.imu,
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: 1.0,
        velocity: 5.5,
        timestamp: DateTime.now(),
      ));

      expect(fused.velocity, isNotNull);
      expect(fused.velocity!, closeTo(5.25, 0.5));
    });

    test('reset clears all state', () {
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 10, y: 20, z: 0),
        accuracyMeters: 3.0,
        timestamp: DateTime.now(),
      ));
      engine.reset();
      expect(engine.currentState.sensorCount, equals(0));
      expect(engine.currentState.confidence, equals(0.0));
    });

    test('buffer overflow trims oldest readings', () {
      final smallEngine = SensorFusionEngine(maxBufferSize: 3);
      for (int i = 0; i < 5; i++) {
        smallEngine.addReading(SensorReading(
          sensorType: SensorType.gps,
          position: Position3D(x: i.toDouble(), y: 0, z: 0),
          accuracyMeters: 3.0,
          timestamp: DateTime.now(),
        ));
      }
      // Latest reading (x=4) should dominate since older are trimmed
      expect(smallEngine.currentState.position.x, closeTo(4.0, 0.1));
    });

    test('confidence increases with more sensor types', () {
      final s1 = engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 10, y: 20, z: 0),
        accuracyMeters: 3.0,
        timestamp: DateTime.now(),
      ));

      final s2 = engine.addReading(SensorReading(
        sensorType: SensorType.lidar,
        position: const Position3D(x: 10, y: 20, z: 0),
        accuracyMeters: 0.02,
        timestamp: DateTime.now(),
      ));

      expect(s2.confidence, greaterThan(s1.confidence));
    });

    test('distance between two fused states', () {
      final a = FusedState(
        position: const Position3D(x: 0, y: 0, z: 0),
        accuracyMeters: 1.0,
        sensorCount: 1,
        primarySensor: 'gps',
        confidence: 0.5,
        timestamp: DateTime.now(),
      );
      final b = FusedState(
        position: const Position3D(x: 3, y: 4, z: 0),
        accuracyMeters: 1.0,
        sensorCount: 1,
        primarySensor: 'gps',
        confidence: 0.5,
        timestamp: DateTime.now(),
      );
      expect(SensorFusionEngine.distance(a, b), closeTo(5.0, 0.01));
    });

    test('all 9 sensor types produce valid fusion', () {
      final now = DateTime.now();
      for (final type in SensorType.values) {
        engine.addReading(SensorReading(
          sensorType: type,
          position: const Position3D(x: 10, y: 20, z: 5),
          accuracyMeters: 1.0,
          heading: 180.0,
          velocity: 2.0,
          timestamp: now,
        ));
      }
      final state = engine.currentState;
      expect(state.sensorCount, equals(9));
      expect(state.position.x, closeTo(10, 0.1));
      expect(state.heading, isNotNull);
      expect(state.velocity, isNotNull);
      expect(state.confidence, greaterThan(0.3));
    });

    test('simulated walk produces consistent tracking', () {
      // Simulate walking 10 meters north
      for (int step = 0; step < 10; step++) {
        engine.addReading(SensorReading(
          sensorType: SensorType.gps,
          position: Position3D(x: 0, y: step.toDouble(), z: 0),
          accuracyMeters: 3.0,
          heading: 0.0, // North
          velocity: 1.0,
          timestamp: DateTime.now(),
        ));
      }
      final state = engine.currentState;
      expect(state.position.y, closeTo(9.0, 0.5));
      expect(state.heading, closeTo(0.0, 5.0));
    });

    test('noisy GPS readings get smoothed', () {
      // GPS with noise ±2m
      final positions = [10.0, 12.0, 9.0, 11.0, 10.5, 10.0, 10.2, 9.8];
      for (final x in positions) {
        engine.addReading(SensorReading(
          sensorType: SensorType.gps,
          position: Position3D(x: x, y: 20, z: 0),
          accuracyMeters: 3.0,
          timestamp: DateTime.now(),
        ));
      }
      // Final fused position should be near 10 (the mean)
      expect(engine.currentState.position.x, closeTo(10.0, 1.0));
    });

    test('degraded sensor (high accuracy value) gets low weight', () {
      // Good GPS
      engine.addReading(SensorReading(
        sensorType: SensorType.gps,
        position: const Position3D(x: 10, y: 20, z: 0),
        accuracyMeters: 2.0,
        timestamp: DateTime.now(),
      ));

      // Degraded barometer (position-less, heading-less)
      engine.addReading(SensorReading(
        sensorType: SensorType.barometer,
        accuracyMeters: 100.0,
        timestamp: DateTime.now(),
      ));

      // GPS should still dominate
      expect(engine.currentState.primarySensor, equals('gps'));
    });
  });
}
