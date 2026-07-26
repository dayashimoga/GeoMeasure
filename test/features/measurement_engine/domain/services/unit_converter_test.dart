import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:meassure_app/features/measurement_engine/domain/services/unit_converter.dart';

void main() {
  group('UnitConverter Tests', () {
    test('converts distance from meters to feet correctly', () {
      final feet = UnitConverter.convertDistance(
        valueMeters: 10.0,
        targetUnit: DistanceUnit.feet,
      );
      expect(feet, closeTo(32.8084, 0.001));
    });

    test('converts area from sq meters to acres, hectares, cents, guntha', () {
      const sqMeters = 10000.0; // 1 Hectare

      final hectares = UnitConverter.convertArea(
        valueSqMeters: sqMeters,
        targetUnit: AreaUnit.hectares,
      );
      expect(hectares, closeTo(1.0, 0.001));

      final acres = UnitConverter.convertArea(
        valueSqMeters: sqMeters,
        targetUnit: AreaUnit.acres,
      );
      expect(acres, closeTo(2.47105, 0.01));

      final cents = UnitConverter.convertArea(
        valueSqMeters: 40.4686,
        targetUnit: AreaUnit.cents,
      );
      expect(cents, closeTo(1.0, 0.001));

      final guntha = UnitConverter.convertArea(
        valueSqMeters: 101.17,
        targetUnit: AreaUnit.guntha,
      );
      expect(guntha, closeTo(1.0, 0.001));
    });
  });
}
