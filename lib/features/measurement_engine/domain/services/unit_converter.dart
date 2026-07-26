import '../entities/measurement_unit.dart';

class UnitConverter {
  static const double metersToFeetRatio = 3.28084;
  static const double metersToInchesRatio = 39.3701;
  static const double metersToYardsRatio = 1.09361;

  static const double sqMetersToSqFeetRatio = 10.7639;
  static const double sqMetersToSqInchesRatio = 1550.0;
  static const double sqMetersToSqYardsRatio = 1.19599;

  static const double sqMetersPerAcre = 4046.86;
  static const double sqMetersPerHectare = 10000.0;
  static const double sqMetersPerCent = 40.4686;
  static const double sqMetersPerGuntha = 101.17;

  static double convertDistance({
    required double valueMeters,
    required DistanceUnit targetUnit,
  }) {
    switch (targetUnit) {
      case DistanceUnit.meters:
        return valueMeters;
      case DistanceUnit.feet:
        return valueMeters * metersToFeetRatio;
      case DistanceUnit.inches:
        return valueMeters * metersToInchesRatio;
      case DistanceUnit.yards:
        return valueMeters * metersToYardsRatio;
    }
  }

  static double convertArea({
    required double valueSqMeters,
    required AreaUnit targetUnit,
  }) {
    switch (targetUnit) {
      case AreaUnit.squareMeters:
        return valueSqMeters;
      case AreaUnit.squareFeet:
        return valueSqMeters * sqMetersToSqFeetRatio;
      case AreaUnit.squareInches:
        return valueSqMeters * sqMetersToSqInchesRatio;
      case AreaUnit.squareYards:
        return valueSqMeters * sqMetersToSqYardsRatio;
      case AreaUnit.acres:
        return valueSqMeters / sqMetersPerAcre;
      case AreaUnit.hectares:
        return valueSqMeters / sqMetersPerHectare;
      case AreaUnit.cents:
        return valueSqMeters / sqMetersPerCent;
      case AreaUnit.guntha:
        return valueSqMeters / sqMetersPerGuntha;
    }
  }
}
