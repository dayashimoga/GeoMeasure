import '../entities/measurement_unit.dart';

class UnitConverter {
  // ── Distance conversion ratios (from meters) ──
  static const double metersToFeetRatio = 3.28084;
  static const double metersToInchesRatio = 39.3701;
  static const double metersToYardsRatio = 1.09361;
  static const double metersToCentimetersRatio = 100.0;
  static const double metersToKilometersRatio = 0.001;
  static const double metersToMilesRatio = 0.000621371;

  // ── Area conversion ratios (from square meters) ──
  static const double sqMetersToSqFeetRatio = 10.7639;
  static const double sqMetersToSqInchesRatio = 1550.0;
  static const double sqMetersToSqYardsRatio = 1.19599;
  static const double sqMetersPerAcre = 4046.86;
  static const double sqMetersPerHectare = 10000.0;
  static const double sqMetersPerCent = 40.4686;
  static const double sqMetersPerGuntha = 101.17;
  static const double sqMetersPerBigha = 2529.29;
  static const double sqMetersPerKanal = 505.857;
  static const double sqMetersPerMarla = 25.2929;
  static const double sqMetersPerPyeong = 3.30579;
  static const double sqMetersPerTsubo = 3.30579;
  static const double sqMetersPerDunam = 1000.0;
  static const double sqMetersPerArpent = 3418.89;
  static const double sqMetersPerSqKilometer = 1000000.0;
  static const double sqMetersPerSqMile = 2589988.11;

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
      case DistanceUnit.centimeters:
        return valueMeters * metersToCentimetersRatio;
      case DistanceUnit.kilometers:
        return valueMeters * metersToKilometersRatio;
      case DistanceUnit.miles:
        return valueMeters * metersToMilesRatio;
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
      case AreaUnit.bigha:
        return valueSqMeters / sqMetersPerBigha;
      case AreaUnit.kanal:
        return valueSqMeters / sqMetersPerKanal;
      case AreaUnit.marla:
        return valueSqMeters / sqMetersPerMarla;
      case AreaUnit.pyeong:
        return valueSqMeters / sqMetersPerPyeong;
      case AreaUnit.tsubo:
        return valueSqMeters / sqMetersPerTsubo;
      case AreaUnit.dunam:
        return valueSqMeters / sqMetersPerDunam;
      case AreaUnit.arpent:
        return valueSqMeters / sqMetersPerArpent;
      case AreaUnit.squareKilometers:
        return valueSqMeters / sqMetersPerSqKilometer;
      case AreaUnit.squareMiles:
        return valueSqMeters / sqMetersPerSqMile;
    }
  }

  /// Human-readable display name for a distance unit.
  static String distanceUnitLabel(DistanceUnit unit) {
    switch (unit) {
      case DistanceUnit.meters:
        return 'm';
      case DistanceUnit.feet:
        return 'ft';
      case DistanceUnit.inches:
        return 'in';
      case DistanceUnit.yards:
        return 'yd';
      case DistanceUnit.centimeters:
        return 'cm';
      case DistanceUnit.kilometers:
        return 'km';
      case DistanceUnit.miles:
        return 'mi';
    }
  }

  /// Human-readable display name for an area unit.
  static String areaUnitLabel(AreaUnit unit) {
    switch (unit) {
      case AreaUnit.squareMeters:
        return 'm²';
      case AreaUnit.squareFeet:
        return 'ft²';
      case AreaUnit.squareInches:
        return 'in²';
      case AreaUnit.squareYards:
        return 'yd²';
      case AreaUnit.acres:
        return 'ac';
      case AreaUnit.hectares:
        return 'ha';
      case AreaUnit.cents:
        return 'cents';
      case AreaUnit.guntha:
        return 'guntha';
      case AreaUnit.bigha:
        return 'bigha';
      case AreaUnit.kanal:
        return 'kanal';
      case AreaUnit.marla:
        return 'marla';
      case AreaUnit.pyeong:
        return 'pyeong';
      case AreaUnit.tsubo:
        return 'tsubo';
      case AreaUnit.dunam:
        return 'dunam';
      case AreaUnit.arpent:
        return 'arpent';
      case AreaUnit.squareKilometers:
        return 'km²';
      case AreaUnit.squareMiles:
        return 'mi²';
    }
  }
}
