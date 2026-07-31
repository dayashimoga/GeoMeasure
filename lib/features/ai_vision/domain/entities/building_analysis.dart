import 'dart:math';
import '../../../measurement_engine/domain/entities/spatial_shape.dart';

/// Roof type classification.
enum RoofType { flat, gable, hip, mansard, gambrel, shed, dome, unknown }

/// Comprehensive building analysis result.
class BuildingAnalysis {
  // ── Dimensions ──
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;
  final int numberOfFloors;
  final double floorHeightMeters;

  // ── Roof ──
  final RoofType roofType;
  final double roofPitchDegrees;
  final double roofAreaSqm;

  // ── Openings ──
  final int windowCount;
  final int doorCount;

  // ── Areas ──
  final double footprintAreaSqm;
  final double totalFloorAreaSqm;
  final double builtUpAreaSqm;
  final double totalWallAreaSqm;
  final double openAreaSqm;
  final double parkingAreaSqm;
  final double plotAreaSqm;

  // ── Ratios ──
  final double floorAreaRatio; // FAR = total floor area / plot area
  final double plotCoverage; // footprint / plot area

  // ── Boundary ──
  final double perimeterMeters;

  const BuildingAnalysis({
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
    required this.numberOfFloors,
    this.floorHeightMeters = 3.0,
    this.roofType = RoofType.flat,
    this.roofPitchDegrees = 0.0,
    this.roofAreaSqm = 0.0,
    this.windowCount = 0,
    this.doorCount = 0,
    this.footprintAreaSqm = 0.0,
    this.totalFloorAreaSqm = 0.0,
    this.builtUpAreaSqm = 0.0,
    this.totalWallAreaSqm = 0.0,
    this.openAreaSqm = 0.0,
    this.parkingAreaSqm = 0.0,
    this.plotAreaSqm = 0.0,
    this.floorAreaRatio = 0.0,
    this.plotCoverage = 0.0,
    this.perimeterMeters = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'lengthMeters': lengthMeters,
        'widthMeters': widthMeters,
        'heightMeters': heightMeters,
        'numberOfFloors': numberOfFloors,
        'floorHeightMeters': floorHeightMeters,
        'roofType': roofType.name,
        'roofPitchDegrees': roofPitchDegrees,
        'roofAreaSqm': roofAreaSqm,
        'windowCount': windowCount,
        'doorCount': doorCount,
        'footprintAreaSqm': footprintAreaSqm,
        'totalFloorAreaSqm': totalFloorAreaSqm,
        'builtUpAreaSqm': builtUpAreaSqm,
        'totalWallAreaSqm': totalWallAreaSqm,
        'openAreaSqm': openAreaSqm,
        'parkingAreaSqm': parkingAreaSqm,
        'plotAreaSqm': plotAreaSqm,
        'floorAreaRatio': floorAreaRatio,
        'plotCoverage': plotCoverage,
        'perimeterMeters': perimeterMeters,
      };

  factory BuildingAnalysis.fromJson(Map<String, dynamic> m) => BuildingAnalysis(
        lengthMeters: (m['lengthMeters'] as num).toDouble(),
        widthMeters: (m['widthMeters'] as num).toDouble(),
        heightMeters: (m['heightMeters'] as num).toDouble(),
        numberOfFloors: m['numberOfFloors'] as int,
        floorHeightMeters: (m['floorHeightMeters'] as num?)?.toDouble() ?? 3.0,
        roofType: RoofType.values.firstWhere(
          (e) => e.name == (m['roofType'] as String?),
          orElse: () => RoofType.flat,
        ),
        roofPitchDegrees: (m['roofPitchDegrees'] as num?)?.toDouble() ?? 0.0,
        roofAreaSqm: (m['roofAreaSqm'] as num?)?.toDouble() ?? 0.0,
        windowCount: m['windowCount'] as int? ?? 0,
        doorCount: m['doorCount'] as int? ?? 0,
        footprintAreaSqm: (m['footprintAreaSqm'] as num?)?.toDouble() ?? 0.0,
        totalFloorAreaSqm: (m['totalFloorAreaSqm'] as num?)?.toDouble() ?? 0.0,
        builtUpAreaSqm: (m['builtUpAreaSqm'] as num?)?.toDouble() ?? 0.0,
        totalWallAreaSqm: (m['totalWallAreaSqm'] as num?)?.toDouble() ?? 0.0,
        openAreaSqm: (m['openAreaSqm'] as num?)?.toDouble() ?? 0.0,
        parkingAreaSqm: (m['parkingAreaSqm'] as num?)?.toDouble() ?? 0.0,
        plotAreaSqm: (m['plotAreaSqm'] as num?)?.toDouble() ?? 0.0,
        floorAreaRatio: (m['floorAreaRatio'] as num?)?.toDouble() ?? 0.0,
        plotCoverage: (m['plotCoverage'] as num?)?.toDouble() ?? 0.0,
        perimeterMeters: (m['perimeterMeters'] as num?)?.toDouble() ?? 0.0,
      );
}

/// Building analysis calculator — pure math, no ML required.
class BuildingAnalyzer {
  /// Analyse a building from its shape and plot data.
  static BuildingAnalysis analyze({
    required BuildingShape building,
    double plotAreaSqm = 0.0,
    double parkingAreaSqm = 0.0,
    int windowCount = 0,
    int doorCount = 0,
    RoofType roofType = RoofType.flat,
    double roofPitchDegrees = 0.0,
  }) {
    final footprint = building.footprintArea;
    final totalFloor = building.calculateAreaInSquareMeters();
    final wallArea = building.calculateTotalWallSurfaceArea();
    final perimeter = building.calculatePerimeterInMeters();
    final height = building.totalHeight;

    // Roof area calculation based on type
    double roofArea;
    if (roofPitchDegrees > 0 && roofType != RoofType.flat) {
      final pitchRad = roofPitchDegrees * pi / 180;
      roofArea = footprint / cos(pitchRad);
    } else {
      roofArea = footprint; // flat roof
    }

    // Open area = plot - footprint - parking
    final openArea = plotAreaSqm > 0
        ? (plotAreaSqm - footprint - parkingAreaSqm).clamp(0.0, plotAreaSqm)
        : 0.0;

    // FAR = total floor area / plot area
    final far = plotAreaSqm > 0 ? totalFloor / plotAreaSqm : 0.0;
    // Plot coverage = footprint / plot area
    final coverage = plotAreaSqm > 0 ? footprint / plotAreaSqm : 0.0;

    return BuildingAnalysis(
      lengthMeters: perimeter / 2, // approximation
      widthMeters: footprint > 0 ? footprint / (perimeter / 2) : 0,
      heightMeters: height,
      numberOfFloors: building.numberOfFloors,
      floorHeightMeters: building.floorHeightMeters,
      roofType: roofType,
      roofPitchDegrees: roofPitchDegrees,
      roofAreaSqm: roofArea,
      windowCount: windowCount,
      doorCount: doorCount,
      footprintAreaSqm: footprint,
      totalFloorAreaSqm: totalFloor,
      builtUpAreaSqm: totalFloor,
      totalWallAreaSqm: wallArea,
      openAreaSqm: openArea,
      parkingAreaSqm: parkingAreaSqm,
      plotAreaSqm: plotAreaSqm,
      floorAreaRatio: far,
      plotCoverage: coverage,
      perimeterMeters: perimeter,
    );
  }

  /// Estimate floor count from total height and assumed floor height.
  static int estimateFloors(double totalHeight, {double floorHeight = 3.0}) =>
      (totalHeight / floorHeight).round().clamp(1, 200);

  /// Calculate floor area ratio.
  static double calculateFAR(double totalFloorArea, double plotArea) =>
      plotArea > 0 ? totalFloorArea / plotArea : 0.0;
}
