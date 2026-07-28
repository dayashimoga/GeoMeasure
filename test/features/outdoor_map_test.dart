import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/outdoor/domain/services/map_service.dart';

/// Tests for outdoor mode services: map tiles, terrain, satellite,
/// coordinate conversion, and survey points.
void main() {
  group('MapTileProvider — OSM', () {
    final osm = OsmTileProvider();

    test('name is OpenStreetMap', () {
      expect(osm.name, equals('OpenStreetMap'));
    });

    test('generates valid tile URL', () {
      final url = osm.getTileUrl(10, 512, 340);
      expect(url, contains('tile.openstreetmap.org'));
      expect(url, contains('/10/512/340.png'));
    });

    test('max zoom is 19', () {
      expect(osm.maxZoom, equals(19));
    });

    test('attribution is present', () {
      expect(osm.attribution, isNotEmpty);
      expect(osm.attribution, contains('OpenStreetMap'));
    });
  });

  group('MapTileProvider — Terrain', () {
    final terrain = StamenTerrainProvider();

    test('name is Stamen Terrain', () {
      expect(terrain.name, contains('Terrain'));
    });

    test('generates terrain tile URL', () {
      final url = terrain.getTileUrl(12, 2048, 1360);
      expect(url, contains('stamen_terrain'));
    });
  });

  group('MapTileProvider — Satellite', () {
    final sat = EsriSatelliteProvider();

    test('name is Esri Satellite', () {
      expect(sat.name, contains('Satellite'));
    });

    test('generates satellite tile URL', () {
      final url = sat.getTileUrl(15, 8192, 5440);
      expect(url, contains('World_Imagery'));
    });

    test('max zoom is 18', () {
      expect(sat.maxZoom, equals(18));
    });
  });

  group('MapTileProvider — TopoMap', () {
    final topo = OpenTopoMapProvider();

    test('generates topo tile URL', () {
      final url = topo.getTileUrl(10, 512, 340);
      expect(url, contains('opentopomap.org'));
    });
  });

  group('MapService', () {
    late MapService service;

    setUp(() {
      service = MapService();
    });

    test('default provider is OSM', () {
      expect(service.provider.name, equals('OpenStreetMap'));
    });

    test('switchProvider changes active provider', () {
      service.switchProvider(EsriSatelliteProvider());
      expect(service.provider.name, contains('Satellite'));
    });

    test('availableProviders has 4 providers', () {
      expect(MapService.availableProviders.length, equals(4));
    });

    test('getTileForCoordinate returns valid URL for Bangalore', () {
      final url = service.getTileForCoordinate(12.9716, 77.5946, 15);
      expect(url, contains('tile.openstreetmap.org'));
      expect(url, contains('/15/'));
    });

    test('getTileForCoordinate returns valid URL for London', () {
      final url = service.getTileForCoordinate(51.5074, -0.1278, 12);
      expect(url, contains('/12/'));
    });

    test('metersPerPixel decreases with higher zoom', () {
      final zoom10 = MapService.metersPerPixel(12.0, 10);
      final zoom15 = MapService.metersPerPixel(12.0, 15);
      expect(zoom15, lessThan(zoom10));
    });

    test('metersPerPixel at equator zoom 0 is ~156543', () {
      final mpp = MapService.metersPerPixel(0, 0);
      expect(mpp, closeTo(156543, 100));
    });

    test('tileXToLon returns valid longitude', () {
      final lon = MapService.tileXToLon(512, 10);
      expect(lon, greaterThanOrEqualTo(-180));
      expect(lon, lessThanOrEqualTo(180));
    });

    test('tileYToLat returns valid latitude', () {
      final lat = MapService.tileYToLat(340, 10);
      expect(lat, greaterThanOrEqualTo(-90));
      expect(lat, lessThanOrEqualTo(90));
    });
  });

  group('MapLayer', () {
    test('default layer is visible with full opacity', () {
      final layer = MapLayer(
        name: 'Base',
        provider: OsmTileProvider(),
      );
      expect(layer.visible, isTrue);
      expect(layer.opacity, equals(1.0));
    });

    test('copyWith modifies visibility', () {
      final layer = MapLayer(name: 'Base', provider: OsmTileProvider());
      final hidden = layer.copyWith(visible: false);
      expect(hidden.visible, isFalse);
      expect(hidden.name, equals('Base')); // unchanged
    });

    test('copyWith modifies opacity', () {
      final layer = MapLayer(name: 'Overlay', provider: EsriSatelliteProvider());
      final semi = layer.copyWith(opacity: 0.5);
      expect(semi.opacity, equals(0.5));
    });
  });

  group('SurveyPoint', () {
    test('serialization round-trip', () {
      final point = SurveyPoint(
        latitude: 12.9716,
        longitude: 77.5946,
        altitude: 920,
        accuracy: 3.0,
        label: 'Corner A',
        timestamp: DateTime(2026, 7, 28),
      );
      final json = point.toJson();
      final restored = SurveyPoint.fromJson(json);
      expect(restored.latitude, equals(12.9716));
      expect(restored.longitude, equals(77.5946));
      expect(restored.altitude, equals(920));
      expect(restored.label, equals('Corner A'));
    });

    test('optional fields can be null', () {
      final point = SurveyPoint(
        latitude: 0,
        longitude: 0,
        timestamp: DateTime.now(),
      );
      expect(point.altitude, isNull);
      expect(point.accuracy, isNull);
      expect(point.label, isNull);
    });
  });
}
