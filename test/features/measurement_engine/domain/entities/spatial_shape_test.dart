import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';

void main() {
  group('RectangleShape', () {
    test('computes area and perimeter correctly', () {
      const r = RectangleShape(lengthMeters: 10, widthMeters: 5);
      expect(r.calculateAreaInSquareMeters(), 50.0);
      expect(r.calculatePerimeterInMeters(), 30.0);
      expect(r.validate(), isNull);
    });

    test('validation rejects zero dimensions', () {
      const r = RectangleShape(lengthMeters: 0, widthMeters: 5);
      expect(r.validate(), isNotNull);
    });

    test('validation rejects negative dimensions', () {
      const r = RectangleShape(lengthMeters: -1, widthMeters: 5);
      expect(r.validate(), isNotNull);
    });
  });

  group('CircleShape', () {
    test('computes area and perimeter correctly', () {
      const c = CircleShape(radiusMeters: 2.0);
      expect(c.calculateAreaInSquareMeters(), closeTo(pi * 4, 0.01));
      expect(c.calculatePerimeterInMeters(), closeTo(2 * pi * 2, 0.01));
      expect(c.validate(), isNull);
    });

    test('validation rejects zero radius', () {
      const c = CircleShape(radiusMeters: 0);
      expect(c.validate(), isNotNull);
    });

    test('validation rejects negative radius', () {
      const c = CircleShape(radiusMeters: -5);
      expect(c.validate(), isNotNull);
    });
  });

  group('TriangleShape', () {
    test('computes Heron formula area correctly (3-4-5 right triangle)', () {
      const t = TriangleShape(sideA: 3, sideB: 4, sideC: 5);
      expect(t.calculateAreaInSquareMeters(), closeTo(6.0, 0.001));
      expect(t.calculatePerimeterInMeters(), 12.0);
      expect(t.validate(), isNull);
    });

    test('degenerate triangle returns validation error', () {
      const t = TriangleShape(sideA: 1, sideB: 2, sideC: 3);
      expect(t.validate(), isNotNull);
      expect(t.calculateAreaInSquareMeters(), 0.0);
    });

    test('validation rejects negative sides', () {
      const t = TriangleShape(sideA: -1, sideB: 4, sideC: 5);
      expect(t.validate(), isNotNull);
    });

    test('equilateral triangle area', () {
      const t = TriangleShape(sideA: 10, sideB: 10, sideC: 10);
      expect(t.calculateAreaInSquareMeters(), closeTo(43.301, 0.01));
    });
  });

  group('IrregularPolygonShape', () {
    test('Shoelace formula for 4x3 rectangle as polygon', () {
      const p = IrregularPolygonShape(
        vertices: [
          Point3D(0, 0),
          Point3D(4, 0),
          Point3D(4, 3),
          Point3D(0, 3),
        ],
      );
      expect(p.calculateAreaInSquareMeters(), 12.0);
      expect(p.calculatePerimeterInMeters(), 14.0);
      expect(p.validate(), isNull);
    });

    test('returns 0 for fewer than 3 vertices', () {
      const p = IrregularPolygonShape(
        vertices: [Point3D(0, 0), Point3D(1, 1)],
      );
      expect(p.calculateAreaInSquareMeters(), 0.0);
      expect(p.validate(), isNotNull);
    });

    test('returns 0 area for empty vertices', () {
      const p = IrregularPolygonShape(vertices: []);
      expect(p.calculateAreaInSquareMeters(), 0.0);
    });
  });

  group('WallShape & WallOpening', () {
    test('net area deducts openings', () {
      const wall = WallShape(
        lengthMeters: 6,
        heightMeters: 3,
        openings: [
          WallOpening(label: 'Door', widthMeters: 1.0, heightMeters: 2.0),
          WallOpening(label: 'Window', widthMeters: 1.5, heightMeters: 1.0),
        ],
      );
      expect(wall.grossAreaInSquareMeters, 18.0);
      expect(wall.openingsTotalAreaInSquareMeters, 3.5);
      expect(wall.calculateAreaInSquareMeters(), 14.5);
      expect(wall.validate(), isNull);
    });

    test('validation rejects openings exceeding wall area', () {
      const wall = WallShape(
        lengthMeters: 2,
        heightMeters: 2,
        openings: [
          WallOpening(label: 'Huge Door', widthMeters: 3, heightMeters: 3),
        ],
      );
      expect(wall.validate(), isNotNull);
    });

    test('wall with no openings returns gross area', () {
      const wall = WallShape(lengthMeters: 5, heightMeters: 3);
      expect(wall.calculateAreaInSquareMeters(), 15.0);
    });
  });

  group('RoomShape', () {
    test('area and volume calculation', () {
      const room = RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(5, 0),
          Point3D(5, 4),
          Point3D(0, 4),
        ],
        heightMeters: 3.0,
      );
      expect(room.calculateAreaInSquareMeters(), 20.0);
      expect(room.calculateVolumeInCubicMeters(), 60.0);
      expect(room.validate(), isNull);
    });

    test('validation rejects zero height', () {
      const room = RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(5, 0),
          Point3D(5, 4),
          Point3D(0, 4),
        ],
        heightMeters: 0,
      );
      expect(room.validate(), isNotNull);
    });
  });

  group('PlotShape (GPS geodetic)', () {
    test('computes area and perimeter for outdoor parcel', () {
      const plot = PlotShape(
        coordinates: [
          GpsCoordinate(latitude: 37.7749, longitude: -122.4194),
          GpsCoordinate(latitude: 37.7755, longitude: -122.4194),
          GpsCoordinate(latitude: 37.7755, longitude: -122.4185),
          GpsCoordinate(latitude: 37.7749, longitude: -122.4185),
        ],
      );
      expect(plot.calculateAreaInSquareMeters(), greaterThan(4000));
      expect(plot.calculatePerimeterInMeters(), greaterThan(200));
      expect(plot.validate(), isNull);
    });

    test('validation rejects fewer than 3 coordinates', () {
      const plot = PlotShape(
        coordinates: [GpsCoordinate(latitude: 0, longitude: 0)],
      );
      expect(plot.validate(), isNotNull);
    });
  });

  group('BuildingShape', () {
    test('multi-floor built-up area and volume', () {
      const building = BuildingShape(
        baseFootprint: RectangleShape(lengthMeters: 20, widthMeters: 15),
        numberOfFloors: 3,
        floorHeightMeters: 3.0,
      );
      expect(building.calculateAreaInSquareMeters(), 900.0);
      expect(building.calculateVolumeInCubicMeters(), 2700.0);
      expect(building.calculatePerimeterInMeters(), 70.0);
      expect(building.validate(), isNull);
    });

    test('total wall surface area', () {
      const building = BuildingShape(
        baseFootprint: RectangleShape(lengthMeters: 10, widthMeters: 8),
        numberOfFloors: 2,
        floorHeightMeters: 3.0,
      );
      expect(building.calculateTotalWallSurfaceArea(), 216.0);
    });

    test('validation rejects zero floors', () {
      const building = BuildingShape(
        baseFootprint: RectangleShape(lengthMeters: 10, widthMeters: 8),
        numberOfFloors: 0,
        floorHeightMeters: 3.0,
      );
      expect(building.validate(), isNotNull);
    });
  });

  group('CapabilityProfile.fallbackManual', () {
    test('all sensors disabled and defaults valid', () {
      final profile = CapabilityProfile.fallbackManual();
      expect(profile.hasLidar, false);
      expect(profile.hasDepthSensor, false);
      expect(profile.hasArCore, false);
      expect(profile.hasArKit, false);
      expect(profile.hasCamera, false);
      expect(profile.hasGps, false);
      expect(profile.ramMb, 2048);
      expect(profile.cpuCores, 4);
      expect(profile.storageAvailableMb, 1024);
      expect(profile.batteryLevel, 1.0);
      expect(profile.permissionsGranted, true);
    });
  });
}
