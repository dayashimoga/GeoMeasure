import 'measurement_algorithm.dart';
import 'measurement_unit.dart';
import 'precision_mode.dart';
import 'spatial_shape.dart';

/// Comprehensive measurement result with full validation metadata.
class MeasurementResult {
  // ── Core measurements ──
  final double area;
  final AreaUnit areaUnit;
  final double perimeter;
  final DistanceUnit distanceUnit;
  final double volume;

  // ── Extended measurements ──
  final double surfaceArea;
  final double lateralArea;
  final double wallArea;
  final double floorArea;
  final double ceilingArea;
  final double roofArea;
  final double footprintArea;
  final double excavationVolume;
  final double fillVolume;
  final double cutVolume;
  final double thickness;
  final double depth;
  final double elevation;

  // ── Metadata ──
  final MeasurementAlgorithm algorithmUsed;
  final double estimatedAccuracyPercentage;
  final DateTime timestamp;
  final ShapeType shapeType;
  final String shapeName;

  // ── Validation ──
  final double confidenceScore;
  final double errorMarginMeters;
  final String sensorUsed;
  final String measurementMethod;
  final String calibrationStatus;
  final PrecisionMode precisionMode;

  MeasurementResult({
    required this.area,
    required this.areaUnit,
    required this.perimeter,
    required this.distanceUnit,
    required this.volume,
    this.surfaceArea = 0.0,
    this.lateralArea = 0.0,
    this.wallArea = 0.0,
    this.floorArea = 0.0,
    this.ceilingArea = 0.0,
    this.roofArea = 0.0,
    this.footprintArea = 0.0,
    this.excavationVolume = 0.0,
    this.fillVolume = 0.0,
    this.cutVolume = 0.0,
    this.thickness = 0.0,
    this.depth = 0.0,
    this.elevation = 0.0,
    required this.algorithmUsed,
    required this.estimatedAccuracyPercentage,
    DateTime? timestamp,
    required this.shapeType,
    this.shapeName = '',
    this.confidenceScore = 0.0,
    this.errorMarginMeters = 0.0,
    this.sensorUsed = 'unknown',
    this.measurementMethod = 'direct',
    this.calibrationStatus = 'uncalibrated',
    this.precisionMode = PrecisionMode.balanced,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a comprehensive result from a SpatialShape.
  factory MeasurementResult.fromShape({
    required SpatialShape shape,
    required MeasurementAlgorithm algorithm,
    required double accuracy,
    String name = '',
    PrecisionMode precision = PrecisionMode.balanced,
    String sensor = 'device',
    String method = 'direct',
    String calibration = 'auto',
    double confidence = 0.0,
    double errorMargin = 0.0,
  }) {
    double wallA = 0, floorA = 0, ceilA = 0, roofA = 0, footA = 0;
    double excV = 0, thick = 0, dep = 0;

    if (shape is RoomShape) {
      wallA = shape.wallArea;
      floorA = shape.floorArea;
      ceilA = shape.ceilingArea;
    } else if (shape is BuildingShape) {
      wallA = shape.calculateTotalWallSurfaceArea();
      footA = shape.footprintArea;
      roofA = shape.footprintArea; // flat roof approximation
    } else if (shape is ExcavationShape) {
      excV = shape.cutVolume;
      dep = shape.depthMeters;
    } else if (shape is PipeShape) {
      thick = shape.wallThickness;
    } else if (shape is PoolShape) {
      dep = shape.averageDepth;
      floorA = shape.calculateAreaInSquareMeters();
    } else if (shape is GableRoofShape) {
      roofA = shape.calculateAreaInSquareMeters();
    } else if (shape is HipRoofShape) {
      roofA = shape.calculateAreaInSquareMeters();
    }

    return MeasurementResult(
      area: shape.calculateAreaInSquareMeters(),
      areaUnit: AreaUnit.squareMeters,
      perimeter: shape.calculatePerimeterInMeters(),
      distanceUnit: DistanceUnit.meters,
      volume: shape.calculateVolumeInCubicMeters(),
      surfaceArea: shape.calculateSurfaceArea(),
      lateralArea: shape.calculateLateralArea(),
      wallArea: wallA,
      floorArea: floorA,
      ceilingArea: ceilA,
      roofArea: roofA,
      footprintArea: footA,
      excavationVolume: excV,
      thickness: thick,
      depth: dep,
      algorithmUsed: algorithm,
      estimatedAccuracyPercentage: accuracy,
      shapeType: shape.type,
      shapeName: name,
      confidenceScore: confidence,
      errorMarginMeters: errorMargin,
      sensorUsed: sensor,
      measurementMethod: method,
      calibrationStatus: calibration,
      precisionMode: precision,
    );
  }

  Map<String, dynamic> toJson() => {
        'area': area,
        'areaUnit': areaUnit.name,
        'perimeter': perimeter,
        'distanceUnit': distanceUnit.name,
        'volume': volume,
        'surfaceArea': surfaceArea,
        'lateralArea': lateralArea,
        'wallArea': wallArea,
        'floorArea': floorArea,
        'ceilingArea': ceilingArea,
        'roofArea': roofArea,
        'footprintArea': footprintArea,
        'excavationVolume': excavationVolume,
        'fillVolume': fillVolume,
        'cutVolume': cutVolume,
        'thickness': thickness,
        'depth': depth,
        'elevation': elevation,
        'algorithmUsed': algorithmUsed.name,
        'estimatedAccuracyPercentage': estimatedAccuracyPercentage,
        'timestamp': timestamp.toIso8601String(),
        'shapeType': shapeType.name,
        'shapeName': shapeName,
        'confidenceScore': confidenceScore,
        'errorMarginMeters': errorMarginMeters,
        'sensorUsed': sensorUsed,
        'measurementMethod': measurementMethod,
        'calibrationStatus': calibrationStatus,
        'precisionMode': precisionMode.name,
      };

  factory MeasurementResult.fromJson(Map<String, dynamic> map) {
    return MeasurementResult(
      area: (map['area'] as num).toDouble(),
      areaUnit: AreaUnit.values.firstWhere((e) => e.name == map['areaUnit']),
      perimeter: (map['perimeter'] as num).toDouble(),
      distanceUnit: DistanceUnit.values.firstWhere(
        (e) => e.name == map['distanceUnit'],
      ),
      volume: (map['volume'] as num).toDouble(),
      surfaceArea: (map['surfaceArea'] as num?)?.toDouble() ?? 0.0,
      lateralArea: (map['lateralArea'] as num?)?.toDouble() ?? 0.0,
      wallArea: (map['wallArea'] as num?)?.toDouble() ?? 0.0,
      floorArea: (map['floorArea'] as num?)?.toDouble() ?? 0.0,
      ceilingArea: (map['ceilingArea'] as num?)?.toDouble() ?? 0.0,
      roofArea: (map['roofArea'] as num?)?.toDouble() ?? 0.0,
      footprintArea: (map['footprintArea'] as num?)?.toDouble() ?? 0.0,
      excavationVolume: (map['excavationVolume'] as num?)?.toDouble() ?? 0.0,
      fillVolume: (map['fillVolume'] as num?)?.toDouble() ?? 0.0,
      cutVolume: (map['cutVolume'] as num?)?.toDouble() ?? 0.0,
      thickness: (map['thickness'] as num?)?.toDouble() ?? 0.0,
      depth: (map['depth'] as num?)?.toDouble() ?? 0.0,
      elevation: (map['elevation'] as num?)?.toDouble() ?? 0.0,
      algorithmUsed: MeasurementAlgorithm.values.firstWhere(
        (e) => e.name == map['algorithmUsed'],
      ),
      estimatedAccuracyPercentage:
          (map['estimatedAccuracyPercentage'] as num).toDouble(),
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      shapeType: ShapeType.values.firstWhere(
        (e) => e.name == map['shapeType'],
        orElse: () => ShapeType.rectangle,
      ),
      shapeName: map['shapeName'] as String? ?? '',
      confidenceScore: (map['confidenceScore'] as num?)?.toDouble() ?? 0.0,
      errorMarginMeters: (map['errorMarginMeters'] as num?)?.toDouble() ?? 0.0,
      sensorUsed: map['sensorUsed'] as String? ?? 'unknown',
      measurementMethod: map['measurementMethod'] as String? ?? 'direct',
      calibrationStatus: map['calibrationStatus'] as String? ?? 'uncalibrated',
      precisionMode: PrecisionMode.values.firstWhere(
        (e) => e.name == (map['precisionMode'] as String?),
        orElse: () => PrecisionMode.balanced,
      ),
    );
  }
}
