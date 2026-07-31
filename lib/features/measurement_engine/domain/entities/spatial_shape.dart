import 'dart:math';
import '../services/geodetic_calculator.dart';

class Point3D {
  final double x;
  final double y;
  final double z;

  const Point3D(this.x, this.y, [this.z = 0.0]);

  double distanceTo(Point3D other) {
    final dx = x - other.x;
    final dy = y - other.y;
    final dz = z - other.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }
}

enum ShapeType {
  rectangle,
  square,
  triangle,
  circle,
  ellipse,
  trapezoid,
  polygon,
  room,
  wall,
  opening,
  plot,
  building,
  corridor,
  staircase,
  // ── Universal shapes ──
  cylinder,
  sphere,
  box,
  cone,
  frustum,
  lShape,
  tShape,
  uShape,
  arch,
  roofGable,
  roofHip,
  roofFlat,
  roofDome,
  excavation,
  pipe,
  pool,
}

abstract class SpatialShape {
  final ShapeType type;
  const SpatialShape(this.type);

  double calculateAreaInSquareMeters();
  double calculatePerimeterInMeters();
  double calculateVolumeInCubicMeters() => 0.0;

  /// Total outer surface area (for 3D shapes).
  double calculateSurfaceArea() => calculateAreaInSquareMeters();

  /// Lateral (side-only) surface area, excluding top/bottom.
  double calculateLateralArea() => 0.0;

  /// Validates shape inputs. Returns null if valid, or error message string.
  String? validate() => null;
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Existing shapes (unchanged contracts)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class RectangleShape extends SpatialShape {
  final double lengthMeters;
  final double widthMeters;

  const RectangleShape({required this.lengthMeters, required this.widthMeters})
      : super(ShapeType.rectangle);

  @override
  String? validate() {
    if (lengthMeters <= 0 || widthMeters <= 0) {
      return 'Rectangle dimensions must be positive';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() => lengthMeters * widthMeters;

  @override
  double calculatePerimeterInMeters() => 2 * (lengthMeters + widthMeters);
}

class CircleShape extends SpatialShape {
  final double radiusMeters;

  const CircleShape({required this.radiusMeters}) : super(ShapeType.circle);

  @override
  String? validate() {
    if (radiusMeters <= 0) return 'Circle radius must be positive';
    return null;
  }

  @override
  double calculateAreaInSquareMeters() => pi * radiusMeters * radiusMeters;

  @override
  double calculatePerimeterInMeters() => 2 * pi * radiusMeters;
}

class TriangleShape extends SpatialShape {
  final double sideA;
  final double sideB;
  final double sideC;

  const TriangleShape({
    required this.sideA,
    required this.sideB,
    required this.sideC,
  }) : super(ShapeType.triangle);

  @override
  String? validate() {
    if (sideA <= 0 || sideB <= 0 || sideC <= 0) {
      return 'Triangle sides must be positive';
    }
    if (sideA + sideB <= sideC ||
        sideA + sideC <= sideB ||
        sideB + sideC <= sideA) {
      return 'Triangle inequality violated: sum of any two sides must exceed the third';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() {
    if (validate() != null) return 0.0;
    final s = (sideA + sideB + sideC) / 2.0;
    return sqrt(s * (s - sideA) * (s - sideB) * (s - sideC));
  }

  @override
  double calculatePerimeterInMeters() => sideA + sideB + sideC;
}

class IrregularPolygonShape extends SpatialShape {
  final List<Point3D> vertices;

  const IrregularPolygonShape({required this.vertices})
      : super(ShapeType.polygon);

  @override
  String? validate() {
    if (vertices.length < 3) return 'Polygon requires at least 3 vertices';
    return null;
  }

  @override
  double calculateAreaInSquareMeters() {
    if (vertices.length < 3) return 0.0;
    double areaSum = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      final j = (i + 1) % vertices.length;
      areaSum += vertices[i].x * vertices[j].y;
      areaSum -= vertices[j].x * vertices[i].y;
    }
    return (areaSum.abs()) / 2.0;
  }

  @override
  double calculatePerimeterInMeters() {
    if (vertices.length < 2) return 0.0;
    double perimeter = 0.0;
    for (int i = 0; i < vertices.length; i++) {
      final j = (i + 1) % vertices.length;
      perimeter += vertices[i].distanceTo(vertices[j]);
    }
    return perimeter;
  }
}

class WallOpening {
  final String label;
  final double widthMeters;
  final double heightMeters;

  const WallOpening({
    required this.label,
    required this.widthMeters,
    required this.heightMeters,
  });

  double get areaInSquareMeters => widthMeters * heightMeters;
}

class WallShape extends SpatialShape {
  final double lengthMeters;
  final double heightMeters;
  final List<WallOpening> openings;

  const WallShape({
    required this.lengthMeters,
    required this.heightMeters,
    this.openings = const [],
  }) : super(ShapeType.wall);

  double get grossAreaInSquareMeters => lengthMeters * heightMeters;

  double get openingsTotalAreaInSquareMeters {
    return openings.fold(0.0, (sum, op) => sum + op.areaInSquareMeters);
  }

  @override
  String? validate() {
    if (lengthMeters <= 0 || heightMeters <= 0) {
      return 'Wall dimensions must be positive';
    }
    if (openingsTotalAreaInSquareMeters > grossAreaInSquareMeters) {
      return 'Openings area exceeds wall area';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() {
    final netArea = grossAreaInSquareMeters - openingsTotalAreaInSquareMeters;
    return netArea > 0 ? netArea : 0.0;
  }

  @override
  double calculatePerimeterInMeters() => 2 * (lengthMeters + heightMeters);
}

class RoomShape extends IrregularPolygonShape {
  final double heightMeters;

  const RoomShape({
    required super.vertices,
    required this.heightMeters,
  });

  @override
  String? validate() {
    final baseValidation = super.validate();
    if (baseValidation != null) return baseValidation;
    if (heightMeters <= 0) return 'Room height must be positive';
    return null;
  }

  @override
  double calculateVolumeInCubicMeters() {
    return calculateAreaInSquareMeters() * heightMeters;
  }

  /// Floor area = base polygon area.
  double get floorArea => calculateAreaInSquareMeters();

  /// Ceiling area = same as floor for standard rooms.
  double get ceilingArea => calculateAreaInSquareMeters();

  /// Total wall surface area.
  double get wallArea => calculatePerimeterInMeters() * heightMeters;

  @override
  double calculateSurfaceArea() => floorArea + ceilingArea + wallArea;
}

class PlotShape extends SpatialShape {
  final List<GpsCoordinate> coordinates;

  const PlotShape({required this.coordinates}) : super(ShapeType.plot);

  @override
  String? validate() {
    if (coordinates.length < 3) {
      return 'Plot requires at least 3 GPS coordinates';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() {
    return GeodeticCalculator.calculatePolygonAreaGeodetic(coordinates);
  }

  @override
  double calculatePerimeterInMeters() {
    if (coordinates.length < 2) return 0.0;
    double perimeter = 0.0;
    for (int i = 0; i < coordinates.length; i++) {
      final next = (i + 1) % coordinates.length;
      perimeter += GeodeticCalculator.calculateDistanceHaversine(
        coordinates[i],
        coordinates[next],
      );
    }
    return perimeter;
  }
}

class BuildingShape extends SpatialShape {
  final SpatialShape baseFootprint;
  final int numberOfFloors;
  final double floorHeightMeters;

  const BuildingShape({
    required this.baseFootprint,
    required this.numberOfFloors,
    required this.floorHeightMeters,
  }) : super(ShapeType.building);

  @override
  String? validate() {
    if (numberOfFloors <= 0) return 'Building must have at least 1 floor';
    if (floorHeightMeters <= 0) return 'Floor height must be positive';
    return baseFootprint.validate();
  }

  /// Total built-up area across all floors.
  @override
  double calculateAreaInSquareMeters() {
    return baseFootprint.calculateAreaInSquareMeters() * numberOfFloors;
  }

  @override
  double calculatePerimeterInMeters() {
    return baseFootprint.calculatePerimeterInMeters();
  }

  @override
  double calculateVolumeInCubicMeters() {
    return baseFootprint.calculateAreaInSquareMeters() *
        numberOfFloors *
        floorHeightMeters;
  }

  /// Building ground footprint.
  double get footprintArea => baseFootprint.calculateAreaInSquareMeters();

  /// Total height of the building.
  double get totalHeight => numberOfFloors * floorHeightMeters;

  /// Total exterior wall surface area for all floors.
  double calculateTotalWallSurfaceArea() {
    return baseFootprint.calculatePerimeterInMeters() *
        floorHeightMeters *
        numberOfFloors;
  }

  @override
  double calculateSurfaceArea() {
    return footprintArea + // roof
        footprintArea + // ground floor
        calculateTotalWallSurfaceArea();
  }
}

class SquareShape extends SpatialShape {
  final double sideMeters;

  const SquareShape({required this.sideMeters}) : super(ShapeType.square);

  @override
  String? validate() {
    if (sideMeters <= 0) return 'Square side must be positive';
    return null;
  }

  @override
  double calculateAreaInSquareMeters() => sideMeters * sideMeters;

  @override
  double calculatePerimeterInMeters() => 4 * sideMeters;
}

class EllipseShape extends SpatialShape {
  final double semiMajorMeters;
  final double semiMinorMeters;

  const EllipseShape({
    required this.semiMajorMeters,
    required this.semiMinorMeters,
  }) : super(ShapeType.ellipse);

  @override
  String? validate() {
    if (semiMajorMeters <= 0 || semiMinorMeters <= 0) {
      return 'Ellipse axes must be positive';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() =>
      pi * semiMajorMeters * semiMinorMeters;

  @override
  double calculatePerimeterInMeters() {
    // Ramanujan's approximation for ellipse perimeter
    final a = semiMajorMeters;
    final b = semiMinorMeters;
    final h = ((a - b) * (a - b)) / ((a + b) * (a + b));
    return pi * (a + b) * (1 + (3 * h) / (10 + sqrt(4 - 3 * h)));
  }
}

class TrapezoidShape extends SpatialShape {
  final double parallelSideA;
  final double parallelSideB;
  final double heightMeters;

  const TrapezoidShape({
    required this.parallelSideA,
    required this.parallelSideB,
    required this.heightMeters,
  }) : super(ShapeType.trapezoid);

  @override
  String? validate() {
    if (parallelSideA <= 0 || parallelSideB <= 0 || heightMeters <= 0) {
      return 'Trapezoid dimensions must be positive';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() =>
      (parallelSideA + parallelSideB) / 2 * heightMeters;

  @override
  double calculatePerimeterInMeters() {
    final offset = (parallelSideA - parallelSideB).abs() / 2;
    final sideLen = sqrt(offset * offset + heightMeters * heightMeters);
    return parallelSideA + parallelSideB + 2 * sideLen;
  }
}

class CorridorShape extends SpatialShape {
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;

  const CorridorShape({
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
  }) : super(ShapeType.corridor);

  @override
  String? validate() {
    if (lengthMeters <= 0 || widthMeters <= 0 || heightMeters <= 0) {
      return 'Corridor dimensions must be positive';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() => lengthMeters * widthMeters;

  @override
  double calculatePerimeterInMeters() => 2 * (lengthMeters + widthMeters);

  @override
  double calculateVolumeInCubicMeters() =>
      lengthMeters * widthMeters * heightMeters;

  double calculateWallSurfaceArea() =>
      2 * (lengthMeters + widthMeters) * heightMeters;

  @override
  double calculateSurfaceArea() =>
      2 * calculateAreaInSquareMeters() + calculateWallSurfaceArea();
}

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// NEW: Universal 3D Shapes
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Cylinder/Tank/Silo — radius + height.
class CylinderShape extends SpatialShape {
  final double radiusMeters;
  final double heightMeters;

  const CylinderShape({
    required this.radiusMeters,
    required this.heightMeters,
  }) : super(ShapeType.cylinder);

  @override
  String? validate() {
    if (radiusMeters <= 0 || heightMeters <= 0) {
      return 'Cylinder dimensions must be positive';
    }
    return null;
  }

  /// Cross-section area (top circle).
  @override
  double calculateAreaInSquareMeters() => pi * radiusMeters * radiusMeters;

  /// Circumference of the base.
  @override
  double calculatePerimeterInMeters() => 2 * pi * radiusMeters;

  @override
  double calculateVolumeInCubicMeters() =>
      pi * radiusMeters * radiusMeters * heightMeters;

  /// 2πrh — lateral (side) surface area.
  @override
  double calculateLateralArea() => 2 * pi * radiusMeters * heightMeters;

  /// Total surface = 2 circles + lateral.
  @override
  double calculateSurfaceArea() =>
      2 * calculateAreaInSquareMeters() + calculateLateralArea();

  double get diameterMeters => 2 * radiusMeters;
}

/// Sphere/Dome/Ball.
class SphereShape extends SpatialShape {
  final double radiusMeters;

  const SphereShape({required this.radiusMeters}) : super(ShapeType.sphere);

  @override
  String? validate() {
    if (radiusMeters <= 0) return 'Sphere radius must be positive';
    return null;
  }

  /// Great circle area.
  @override
  double calculateAreaInSquareMeters() => pi * radiusMeters * radiusMeters;

  /// Great circle circumference.
  @override
  double calculatePerimeterInMeters() => 2 * pi * radiusMeters;

  @override
  double calculateVolumeInCubicMeters() =>
      (4.0 / 3.0) * pi * radiusMeters * radiusMeters * radiusMeters;

  /// 4πr².
  @override
  double calculateSurfaceArea() => 4 * pi * radiusMeters * radiusMeters;

  double get diameterMeters => 2 * radiusMeters;
}

/// Cuboid — length × width × height. Packages, furniture, containers.
class CuboidShape extends SpatialShape {
  final double lengthMeters;
  final double widthMeters;
  final double heightMeters;

  const CuboidShape({
    required this.lengthMeters,
    required this.widthMeters,
    required this.heightMeters,
  }) : super(ShapeType.box);

  @override
  String? validate() {
    if (lengthMeters <= 0 || widthMeters <= 0 || heightMeters <= 0) {
      return 'Box dimensions must be positive';
    }
    return null;
  }

  /// Floor/base area.
  @override
  double calculateAreaInSquareMeters() => lengthMeters * widthMeters;

  @override
  double calculatePerimeterInMeters() => 2 * (lengthMeters + widthMeters);

  @override
  double calculateVolumeInCubicMeters() =>
      lengthMeters * widthMeters * heightMeters;

  /// 4 side faces.
  @override
  double calculateLateralArea() =>
      2 * (lengthMeters + widthMeters) * heightMeters;

  /// 6 faces total.
  @override
  double calculateSurfaceArea() =>
      2 *
      (lengthMeters * widthMeters +
          lengthMeters * heightMeters +
          widthMeters * heightMeters);

  /// Diagonal of the box.
  double get diagonalMeters => sqrt(lengthMeters * lengthMeters +
      widthMeters * widthMeters +
      heightMeters * heightMeters);
}

/// Cone — pointy top (funnel, traffic cone, conical roof).
class ConeShape extends SpatialShape {
  final double radiusMeters;
  final double heightMeters;

  const ConeShape({
    required this.radiusMeters,
    required this.heightMeters,
  }) : super(ShapeType.cone);

  @override
  String? validate() {
    if (radiusMeters <= 0 || heightMeters <= 0) {
      return 'Cone dimensions must be positive';
    }
    return null;
  }

  double get slantHeight =>
      sqrt(radiusMeters * radiusMeters + heightMeters * heightMeters);

  @override
  double calculateAreaInSquareMeters() => pi * radiusMeters * radiusMeters;

  @override
  double calculatePerimeterInMeters() => 2 * pi * radiusMeters;

  @override
  double calculateVolumeInCubicMeters() =>
      (1.0 / 3.0) * pi * radiusMeters * radiusMeters * heightMeters;

  @override
  double calculateLateralArea() => pi * radiusMeters * slantHeight;

  @override
  double calculateSurfaceArea() =>
      calculateAreaInSquareMeters() + calculateLateralArea();
}

/// Frustum — truncated cone (bucket, lampshade, cooling tower).
class FrustumShape extends SpatialShape {
  final double topRadiusMeters;
  final double bottomRadiusMeters;
  final double heightMeters;

  const FrustumShape({
    required this.topRadiusMeters,
    required this.bottomRadiusMeters,
    required this.heightMeters,
  }) : super(ShapeType.frustum);

  @override
  String? validate() {
    if (topRadiusMeters < 0 || bottomRadiusMeters <= 0 || heightMeters <= 0) {
      return 'Frustum dimensions must be positive';
    }
    return null;
  }

  double get slantHeight {
    final dr = bottomRadiusMeters - topRadiusMeters;
    return sqrt(dr * dr + heightMeters * heightMeters);
  }

  @override
  double calculateAreaInSquareMeters() =>
      pi * bottomRadiusMeters * bottomRadiusMeters;

  @override
  double calculatePerimeterInMeters() => 2 * pi * bottomRadiusMeters;

  @override
  double calculateVolumeInCubicMeters() {
    final r = bottomRadiusMeters;
    final R = topRadiusMeters;
    return (pi * heightMeters / 3.0) * (r * r + R * R + r * R);
  }

  @override
  double calculateLateralArea() =>
      pi * (topRadiusMeters + bottomRadiusMeters) * slantHeight;

  @override
  double calculateSurfaceArea() =>
      pi * topRadiusMeters * topRadiusMeters +
      pi * bottomRadiusMeters * bottomRadiusMeters +
      calculateLateralArea();
}

/// L-shaped room — two connected rectangles.
class LShapeRoom extends SpatialShape {
  final double longLengthMeters;
  final double longWidthMeters;
  final double shortLengthMeters;
  final double shortWidthMeters;
  final double heightMeters;

  const LShapeRoom({
    required this.longLengthMeters,
    required this.longWidthMeters,
    required this.shortLengthMeters,
    required this.shortWidthMeters,
    required this.heightMeters,
  }) : super(ShapeType.lShape);

  @override
  String? validate() {
    if (longLengthMeters <= 0 ||
        longWidthMeters <= 0 ||
        shortLengthMeters <= 0 ||
        shortWidthMeters <= 0 ||
        heightMeters <= 0) {
      return 'L-shape dimensions must be positive';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() =>
      (longLengthMeters * longWidthMeters) +
      (shortLengthMeters * shortWidthMeters);

  @override
  double calculatePerimeterInMeters() =>
      2 * (longLengthMeters + longWidthMeters + shortLengthMeters) -
      shortWidthMeters;

  @override
  double calculateVolumeInCubicMeters() =>
      calculateAreaInSquareMeters() * heightMeters;

  double get wallArea => calculatePerimeterInMeters() * heightMeters;

  @override
  double calculateSurfaceArea() => 2 * calculateAreaInSquareMeters() + wallArea;
}

/// Arch/Semicircular shape — bridges, doorways.
class ArchShape extends SpatialShape {
  final double spanMeters; // width of the arch
  final double riseMeters; // height from base to crown
  final double depthMeters; // depth/thickness of the arch

  const ArchShape({
    required this.spanMeters,
    required this.riseMeters,
    required this.depthMeters,
  }) : super(ShapeType.arch);

  @override
  String? validate() {
    if (spanMeters <= 0 || riseMeters <= 0 || depthMeters <= 0) {
      return 'Arch dimensions must be positive';
    }
    return null;
  }

  double get radiusMeters {
    // For a circular segment: R = (S²/(8H)) + H/2
    return (spanMeters * spanMeters) / (8 * riseMeters) + riseMeters / 2;
  }

  /// Arc length using the radius and central angle.
  double get arcLength {
    final r = radiusMeters;
    final halfSpan = spanMeters / 2;
    final theta = 2 * asin(halfSpan / r);
    return r * theta;
  }

  /// Frontal area of the arch segment.
  @override
  double calculateAreaInSquareMeters() {
    final r = radiusMeters;
    final halfSpan = spanMeters / 2;
    final theta = 2 * asin(halfSpan / r);
    // Circular segment area = (r²/2)(θ - sin(θ))
    return (r * r / 2) * (theta - sin(theta));
  }

  @override
  double calculatePerimeterInMeters() => arcLength + spanMeters;

  @override
  double calculateVolumeInCubicMeters() =>
      calculateAreaInSquareMeters() * depthMeters;

  @override
  double calculateSurfaceArea() =>
      2 * calculateAreaInSquareMeters() + arcLength * depthMeters;
}

/// Gable Roof — two rectangular slopes meeting at a ridge.
class GableRoofShape extends SpatialShape {
  final double ridgeLengthMeters;
  final double spanMeters; // building width
  final double riseMeters; // ridge height above eaves
  final double overHangMeters; // eave overhang

  const GableRoofShape({
    required this.ridgeLengthMeters,
    required this.spanMeters,
    required this.riseMeters,
    this.overHangMeters = 0.0,
  }) : super(ShapeType.roofGable);

  @override
  String? validate() {
    if (ridgeLengthMeters <= 0 || spanMeters <= 0 || riseMeters <= 0) {
      return 'Roof dimensions must be positive';
    }
    return null;
  }

  /// Roof pitch angle in degrees.
  double get pitchDegrees => atan2(riseMeters, spanMeters / 2) * 180 / pi;

  /// Slope length (rafter length per side).
  double get slopeLength {
    final half = spanMeters / 2 + overHangMeters;
    return sqrt(half * half + riseMeters * riseMeters);
  }

  /// Total roof surface area (both slopes).
  @override
  double calculateAreaInSquareMeters() =>
      2 * slopeLength * (ridgeLengthMeters + 2 * overHangMeters);

  /// Plan area (horizontal projection).
  double get planArea =>
      (spanMeters + 2 * overHangMeters) *
      (ridgeLengthMeters + 2 * overHangMeters);

  @override
  double calculatePerimeterInMeters() =>
      2 * (ridgeLengthMeters + spanMeters) + 4 * overHangMeters;

  @override
  double calculateVolumeInCubicMeters() =>
      (spanMeters * riseMeters / 2) * ridgeLengthMeters;
}

/// Hip Roof — slopes on all 4 sides.
class HipRoofShape extends SpatialShape {
  final double lengthMeters;
  final double widthMeters;
  final double riseMeters;

  const HipRoofShape({
    required this.lengthMeters,
    required this.widthMeters,
    required this.riseMeters,
  }) : super(ShapeType.roofHip);

  @override
  String? validate() {
    if (lengthMeters <= 0 || widthMeters <= 0 || riseMeters <= 0) {
      return 'Hip roof dimensions must be positive';
    }
    return null;
  }

  double get pitchDegrees => atan2(riseMeters, widthMeters / 2) * 180 / pi;

  double get commonRafterLength =>
      sqrt((widthMeters / 2) * (widthMeters / 2) + riseMeters * riseMeters);

  double get ridgeLength => lengthMeters - widthMeters;

  /// Total roof surface: 2 trapezoids (long sides) + 2 triangles (short sides).
  @override
  double calculateAreaInSquareMeters() {
    final rl = ridgeLength > 0 ? ridgeLength : 0.0;
    final slopeLong = commonRafterLength;
    // Two trapezoidal faces (if ridge > 0)
    final trapArea = 2 * ((lengthMeters + rl) / 2) * slopeLong;
    // Two triangular faces
    final hipLength =
        sqrt((widthMeters / 2) * (widthMeters / 2) + riseMeters * riseMeters);
    final triArea = 2 * (widthMeters * hipLength / 2);
    return trapArea + triArea;
  }

  @override
  double calculatePerimeterInMeters() => 2 * (lengthMeters + widthMeters);

  @override
  double calculateVolumeInCubicMeters() {
    // Volume under hip roof ≈ base area × rise / 3
    return lengthMeters * widthMeters * riseMeters / 3;
  }
}

/// Excavation — trapezoidal prism (cut in ground).
class ExcavationShape extends SpatialShape {
  final double lengthMeters;
  final double topWidthMeters;
  final double bottomWidthMeters;
  final double depthMeters;

  const ExcavationShape({
    required this.lengthMeters,
    required this.topWidthMeters,
    required this.bottomWidthMeters,
    required this.depthMeters,
  }) : super(ShapeType.excavation);

  @override
  String? validate() {
    if (lengthMeters <= 0 ||
        topWidthMeters <= 0 ||
        bottomWidthMeters <= 0 ||
        depthMeters <= 0) {
      return 'Excavation dimensions must be positive';
    }
    return null;
  }

  /// Cross-section area (trapezoidal).
  @override
  double calculateAreaInSquareMeters() =>
      (topWidthMeters + bottomWidthMeters) / 2 * depthMeters;

  @override
  double calculatePerimeterInMeters() =>
      2 * lengthMeters + topWidthMeters + bottomWidthMeters;

  /// Excavation volume = cross-section × length.
  @override
  double calculateVolumeInCubicMeters() =>
      calculateAreaInSquareMeters() * lengthMeters;

  /// Cut volume (same as total volume for excavation).
  double get cutVolume => calculateVolumeInCubicMeters();

  /// Fill volume = total excavation minus the structure placed inside.
  double fillVolume(double structureVolume) =>
      calculateVolumeInCubicMeters() - structureVolume;
}

/// Pipe — hollow cylinder (water pipe, sewer, duct).
class PipeShape extends SpatialShape {
  final double outerRadiusMeters;
  final double innerRadiusMeters;
  final double lengthMeters;

  const PipeShape({
    required this.outerRadiusMeters,
    required this.innerRadiusMeters,
    required this.lengthMeters,
  }) : super(ShapeType.pipe);

  @override
  String? validate() {
    if (outerRadiusMeters <= 0 || innerRadiusMeters < 0 || lengthMeters <= 0) {
      return 'Pipe dimensions must be positive';
    }
    if (innerRadiusMeters >= outerRadiusMeters) {
      return 'Inner radius must be less than outer radius';
    }
    return null;
  }

  double get wallThickness => outerRadiusMeters - innerRadiusMeters;

  /// Cross-section area of the pipe wall (annular).
  @override
  double calculateAreaInSquareMeters() =>
      pi *
      (outerRadiusMeters * outerRadiusMeters -
          innerRadiusMeters * innerRadiusMeters);

  /// Inner bore area.
  double get innerBoreArea => pi * innerRadiusMeters * innerRadiusMeters;

  @override
  double calculatePerimeterInMeters() =>
      2 * pi * outerRadiusMeters + 2 * pi * innerRadiusMeters;

  /// Volume of the pipe material (wall).
  @override
  double calculateVolumeInCubicMeters() =>
      calculateAreaInSquareMeters() * lengthMeters;

  /// Volume of fluid/air the pipe can carry.
  double get innerVolume => innerBoreArea * lengthMeters;

  /// Outer surface area.
  @override
  double calculateSurfaceArea() =>
      2 * pi * outerRadiusMeters * lengthMeters +
      2 * pi * innerRadiusMeters * lengthMeters +
      2 * calculateAreaInSquareMeters();
}

/// Swimming Pool — rectangular with sloping bottom.
class PoolShape extends SpatialShape {
  final double lengthMeters;
  final double widthMeters;
  final double shallowDepthMeters;
  final double deepDepthMeters;

  const PoolShape({
    required this.lengthMeters,
    required this.widthMeters,
    required this.shallowDepthMeters,
    required this.deepDepthMeters,
  }) : super(ShapeType.pool);

  @override
  String? validate() {
    if (lengthMeters <= 0 ||
        widthMeters <= 0 ||
        shallowDepthMeters <= 0 ||
        deepDepthMeters <= 0) {
      return 'Pool dimensions must be positive';
    }
    return null;
  }

  double get averageDepth => (shallowDepthMeters + deepDepthMeters) / 2;

  /// Pool surface area (water surface).
  @override
  double calculateAreaInSquareMeters() => lengthMeters * widthMeters;

  @override
  double calculatePerimeterInMeters() => 2 * (lengthMeters + widthMeters);

  /// Water volume using average depth.
  @override
  double calculateVolumeInCubicMeters() =>
      lengthMeters * widthMeters * averageDepth;

  /// Water volume in litres.
  double get waterVolumeLitres => calculateVolumeInCubicMeters() * 1000;

  /// Bottom slope length.
  double get bottomSlopeLength {
    final dd = deepDepthMeters - shallowDepthMeters;
    return sqrt(lengthMeters * lengthMeters + dd * dd);
  }

  /// Total internal surface area (floor + walls).
  @override
  double calculateSurfaceArea() {
    final floor = bottomSlopeLength * widthMeters;
    final longWalls = 2 * lengthMeters * averageDepth;
    final shortWalls =
        widthMeters * shallowDepthMeters + widthMeters * deepDepthMeters;
    return floor + longWalls + shortWalls;
  }
}

/// T-shaped room — main rectangle with a perpendicular wing.
///
/// Layout (top-down view):
/// ```
///     ┌─────────┐
///     │  wing    │  wingLength × wingWidth
///     └──┬───┬──┘
///        │   │
///        │   │  mainLength × mainWidth
///        │   │
///        └───┘
/// ```
class TShapeRoom extends SpatialShape {
  final double mainLengthMeters;
  final double mainWidthMeters;
  final double wingLengthMeters;
  final double wingWidthMeters;
  final double heightMeters;

  const TShapeRoom({
    required this.mainLengthMeters,
    required this.mainWidthMeters,
    required this.wingLengthMeters,
    required this.wingWidthMeters,
    required this.heightMeters,
  }) : super(ShapeType.tShape);

  @override
  String? validate() {
    if (mainLengthMeters <= 0 ||
        mainWidthMeters <= 0 ||
        wingLengthMeters <= 0 ||
        wingWidthMeters <= 0 ||
        heightMeters <= 0) {
      return 'T-shape dimensions must be positive';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() =>
      (mainLengthMeters * mainWidthMeters) +
      (wingLengthMeters * wingWidthMeters);

  @override
  double calculatePerimeterInMeters() =>
      2 * mainLengthMeters +
      2 * wingLengthMeters +
      2 * (wingWidthMeters - mainWidthMeters).abs();

  @override
  double calculateVolumeInCubicMeters() =>
      calculateAreaInSquareMeters() * heightMeters;

  double get wallArea => calculatePerimeterInMeters() * heightMeters;

  @override
  double calculateSurfaceArea() => 2 * calculateAreaInSquareMeters() + wallArea;
}

/// U-shaped room — main rectangle with two parallel wings.
///
/// Layout (top-down view):
/// ```
/// ┌───┐       ┌───┐
/// │   │       │   │  wingLength × wingWidth (×2)
/// │   │       │   │
/// │   └───────┘   │
/// │   mainLength  │  mainLength × mainWidth
/// └───────────────┘
/// ```
class UShapeRoom extends SpatialShape {
  final double mainLengthMeters;
  final double mainWidthMeters;
  final double wingLengthMeters;
  final double wingWidthMeters;
  final double heightMeters;

  const UShapeRoom({
    required this.mainLengthMeters,
    required this.mainWidthMeters,
    required this.wingLengthMeters,
    required this.wingWidthMeters,
    required this.heightMeters,
  }) : super(ShapeType.uShape);

  @override
  String? validate() {
    if (mainLengthMeters <= 0 ||
        mainWidthMeters <= 0 ||
        wingLengthMeters <= 0 ||
        wingWidthMeters <= 0 ||
        heightMeters <= 0) {
      return 'U-shape dimensions must be positive';
    }
    return null;
  }

  @override
  double calculateAreaInSquareMeters() =>
      (mainLengthMeters * mainWidthMeters) +
      2 * (wingLengthMeters * wingWidthMeters);

  @override
  double calculatePerimeterInMeters() =>
      2 * mainLengthMeters + 4 * wingLengthMeters + 2 * wingWidthMeters;

  @override
  double calculateVolumeInCubicMeters() =>
      calculateAreaInSquareMeters() * heightMeters;

  /// Total open courtyard area between the wings.
  double get courtyardArea {
    final innerWidth = mainWidthMeters - 2 * wingWidthMeters;
    return innerWidth > 0 ? innerWidth * wingLengthMeters : 0.0;
  }

  double get wallArea => calculatePerimeterInMeters() * heightMeters;

  @override
  double calculateSurfaceArea() => 2 * calculateAreaInSquareMeters() + wallArea;
}
