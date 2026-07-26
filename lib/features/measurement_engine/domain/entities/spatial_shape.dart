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
  triangle,
  circle,
  polygon,
  room,
  wall,
  opening,
  plot,
  building,
}

abstract class SpatialShape {
  final ShapeType type;
  const SpatialShape(this.type);

  double calculateAreaInSquareMeters();
  double calculatePerimeterInMeters();
  double calculateVolumeInCubicMeters() => 0.0;

  /// Validates shape inputs. Returns null if valid, or error message string.
  String? validate() => null;
}

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
}

class PlotShape extends SpatialShape {
  final List<GpsCoordinate> coordinates;

  const PlotShape({required this.coordinates}) : super(ShapeType.plot);

  @override
  String? validate() {
    if (coordinates.length < 3) return 'Plot requires at least 3 GPS coordinates';
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
    return baseFootprint.calculateAreaInSquareMeters() * numberOfFloors * floorHeightMeters;
  }

  /// Total exterior wall surface area for all floors (E5).
  double calculateTotalWallSurfaceArea() {
    return baseFootprint.calculatePerimeterInMeters() * floorHeightMeters * numberOfFloors;
  }
}
