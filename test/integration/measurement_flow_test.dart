import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/unit_converter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/svg_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/kml_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/csv_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/dxf_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geojson_exporter.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';
import 'package:geomeasure/features/export/excel_exporter.dart';
import 'package:geomeasure/features/estimation/domain/entities/material_estimate.dart';

/// Integration tests for end-to-end measurement and export flows.
void main() {
  group('Room Measurement Flow', () {
    test('rectangle → area + perimeter', () {
      const shape = RectangleShape(lengthMeters: 5.0, widthMeters: 4.0);
      expect(shape.validate(), isNull);
      expect(shape.calculateAreaInSquareMeters(), closeTo(20.0, 0.001));
      expect(shape.calculatePerimeterInMeters(), closeTo(18.0, 0.001));
    });

    test('room with height → volume + wall area', () {
      const room = RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(5, 0),
          Point3D(5, 4),
          Point3D(0, 4),
        ],
        heightMeters: 3.0,
      );
      expect(room.validate(), isNull);
      expect(room.calculateAreaInSquareMeters(), closeTo(20.0, 0.001));
      expect(room.calculateVolumeInCubicMeters(), closeTo(60.0, 0.001));
      expect(room.wallArea, closeTo(54.0, 0.001));
    });

    test('circle shape → area + circumference', () {
      const circle = CircleShape(radiusMeters: 3.0);
      expect(circle.validate(), isNull);
      expect(circle.calculateAreaInSquareMeters(), closeTo(28.274, 0.01));
      expect(circle.calculatePerimeterInMeters(), closeTo(18.849, 0.01));
    });

    test('triangle shape → area via Heron', () {
      const tri = TriangleShape(sideA: 3, sideB: 4, sideC: 5);
      expect(tri.validate(), isNull);
      expect(tri.calculateAreaInSquareMeters(), closeTo(6.0, 0.001));
      expect(tri.calculatePerimeterInMeters(), closeTo(12.0, 0.001));
    });

    test('invalid triangle rejected', () {
      const bad = TriangleShape(sideA: 1, sideB: 2, sideC: 10);
      expect(bad.validate(), isNotNull);
    });

    test('wall shape with openings → net area', () {
      const wall = WallShape(
        lengthMeters: 6.0,
        heightMeters: 3.0,
        openings: [
          WallOpening(label: 'Door', widthMeters: 0.9, heightMeters: 2.1),
        ],
      );
      expect(wall.validate(), isNull);
      // Gross: 18m², Opening: 1.89m², Net: 16.11m²
      final netArea = wall.calculateAreaInSquareMeters();
      expect(netArea, closeTo(16.11, 0.01));
    });
  });

  group('Unit Conversion Flow', () {
    test('meters → feet', () {
      expect(
        UnitConverter.convertDistance(
            valueMeters: 1.0, targetUnit: DistanceUnit.feet),
        closeTo(3.28084, 0.001),
      );
    });

    test('sq meters → sq feet', () {
      expect(
        UnitConverter.convertArea(
            valueSqMeters: 1.0, targetUnit: AreaUnit.squareFeet),
        closeTo(10.7639, 0.001),
      );
    });

    test('sq meters → acres', () {
      expect(
        UnitConverter.convertArea(
            valueSqMeters: 4046.86, targetUnit: AreaUnit.acres),
        closeTo(1.0, 0.001),
      );
    });

    test('sq meters → cents (Indian)', () {
      expect(
        UnitConverter.convertArea(
            valueSqMeters: 40.4686, targetUnit: AreaUnit.cents),
        closeTo(1.0, 0.001),
      );
    });

    test('sq meters → guntha (Indian)', () {
      expect(
        UnitConverter.convertArea(
            valueSqMeters: 101.17, targetUnit: AreaUnit.guntha),
        closeTo(1.0, 0.01),
      );
    });

    test('all distance units produce non-zero', () {
      for (final unit in DistanceUnit.values) {
        expect(
          UnitConverter.convertDistance(valueMeters: 1.0, targetUnit: unit),
          greaterThan(0),
        );
      }
    });

    test('all area units produce non-zero', () {
      for (final unit in AreaUnit.values) {
        expect(
          UnitConverter.convertArea(valueSqMeters: 1.0, targetUnit: unit),
          greaterThan(0),
        );
      }
    });
  });

  group('Export Pipeline Flow', () {
    const rect = RectangleShape(lengthMeters: 5.0, widthMeters: 4.0);

    test('SVG export produces valid SVG', () {
      final svg = SvgExporter.generateSvg(rect);
      expect(svg, contains('<svg'));
      expect(svg, contains('</svg>'));
    });

    test('DXF export produces valid DXF', () {
      final dxf = DxfExporter.generateDxf(rect);
      expect(dxf, contains('SECTION'));
      expect(dxf, contains('ENTITIES'));
      expect(dxf, contains('EOF'));
    });

    test('CSV export with empty results has header', () {
      final csv = CsvExporter.generateCsv([]);
      expect(csv, contains('ShapeType'));
    });

    test('Excel export produces bytes', () {
      final bytes = ExcelExporter.exportMeasurements([]);
      expect(bytes.length, greaterThan(0));
    });
  });

  group('GPS Land Survey Flow', () {
    test('PlotShape from GPS waypoints → geodetic area', () {
      const plot = PlotShape(
        coordinates: [
          GpsCoordinate(latitude: 0.0, longitude: 0.0),
          GpsCoordinate(latitude: 0.0009, longitude: 0.0),
          GpsCoordinate(latitude: 0.0009, longitude: 0.0009),
          GpsCoordinate(latitude: 0.0, longitude: 0.0009),
        ],
      );
      expect(plot.validate(), isNull);
      final area = plot.calculateAreaInSquareMeters();
      expect(area, greaterThan(9000));
      expect(area, lessThan(11000));
    });

    test('KML export from GPS plot', () {
      const plot = PlotShape(
        coordinates: [
          GpsCoordinate(latitude: 12.9716, longitude: 77.5946),
          GpsCoordinate(latitude: 12.9726, longitude: 77.5946),
          GpsCoordinate(latitude: 12.9726, longitude: 77.5956),
        ],
      );
      final kml = KmlExporter.generateKml(plot);
      expect(kml, contains('<?xml'));
      expect(kml, contains('kml'));
      expect(kml, contains('Polygon'));
    });

    test('GeoJSON export from GPS plot', () {
      const plot = PlotShape(
        coordinates: [
          GpsCoordinate(latitude: 12.9716, longitude: 77.5946),
          GpsCoordinate(latitude: 12.9726, longitude: 77.5946),
          GpsCoordinate(latitude: 12.9726, longitude: 77.5956),
        ],
      );
      final json = GeoJsonExporter.generateGeoJson(plot);
      expect(json, contains('Feature'));
      expect(json, contains('Polygon'));
    });
  });

  group('Material Estimation Flow', () {
    test('room estimate produces materials', () {
      const room = RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(5, 0),
          Point3D(5, 4),
          Point3D(0, 4),
        ],
        heightMeters: 3.0,
      );
      final takeoff = MaterialEstimator.estimateForRoom(room);
      expect(takeoff, isNotNull);
      expect(takeoff.items, isNotEmpty);
      // unitCost defaults to 0.0 — verify quantities are computed
      expect(takeoff.items.first.adjustedQuantity, greaterThan(0));
    });
  });
}
