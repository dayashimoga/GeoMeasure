import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/unit_converter.dart';

void main() {
  group('UnitConverter — Distance', () {
    test('meters to feet', () {
      expect(
        UnitConverter.convertDistance(
          valueMeters: 10,
          targetUnit: DistanceUnit.feet,
        ),
        closeTo(32.808, 0.01),
      );
    });

    test('meters to inches', () {
      expect(
        UnitConverter.convertDistance(
          valueMeters: 1,
          targetUnit: DistanceUnit.inches,
        ),
        closeTo(39.370, 0.01),
      );
    });

    test('meters to yards', () {
      expect(
        UnitConverter.convertDistance(
          valueMeters: 1,
          targetUnit: DistanceUnit.yards,
        ),
        closeTo(1.0936, 0.001),
      );
    });

    test('meters to meters (identity)', () {
      expect(
        UnitConverter.convertDistance(
          valueMeters: 42.0,
          targetUnit: DistanceUnit.meters,
        ),
        42.0,
      );
    });
  });

  group('UnitConverter — Area', () {
    test('sq meters to sq feet', () {
      expect(
        UnitConverter.convertArea(
          valueSqMeters: 1,
          targetUnit: AreaUnit.squareFeet,
        ),
        closeTo(10.7639, 0.01),
      );
    });

    test('10000 sq meters = 1 hectare', () {
      expect(
        UnitConverter.convertArea(
          valueSqMeters: 10000,
          targetUnit: AreaUnit.hectares,
        ),
        closeTo(1.0, 0.001),
      );
    });

    test('10000 sq meters ≈ 2.471 acres', () {
      expect(
        UnitConverter.convertArea(
          valueSqMeters: 10000,
          targetUnit: AreaUnit.acres,
        ),
        closeTo(2.471, 0.01),
      );
    });

    test('40.4686 sq meters = 1 cent', () {
      expect(
        UnitConverter.convertArea(
          valueSqMeters: 40.4686,
          targetUnit: AreaUnit.cents,
        ),
        closeTo(1.0, 0.001),
      );
    });

    test('101.17 sq meters = 1 guntha', () {
      expect(
        UnitConverter.convertArea(
          valueSqMeters: 101.17,
          targetUnit: AreaUnit.guntha,
        ),
        closeTo(1.0, 0.001),
      );
    });

    test('sq meters to sq inches', () {
      expect(
        UnitConverter.convertArea(
          valueSqMeters: 1,
          targetUnit: AreaUnit.squareInches,
        ),
        closeTo(1550.0, 1.0),
      );
    });

    test('sq meters to sq yards', () {
      expect(
        UnitConverter.convertArea(
          valueSqMeters: 1,
          targetUnit: AreaUnit.squareYards,
        ),
        closeTo(1.196, 0.01),
      );
    });
  });
}
