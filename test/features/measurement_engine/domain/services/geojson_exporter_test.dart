import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geodetic_calculator.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/geojson_exporter.dart';

void main() {
  group('GeoJsonExporter', () {
    test('generates RFC 7946 valid GeoJSON', () {
      const plot = PlotShape(
        coordinates: [
          GpsCoordinate(latitude: 37.7749, longitude: -122.4194),
          GpsCoordinate(latitude: 37.7755, longitude: -122.4194),
          GpsCoordinate(latitude: 37.7755, longitude: -122.4185),
          GpsCoordinate(latitude: 37.7749, longitude: -122.4185),
        ],
      );

      final geoJsonStr = GeoJsonExporter.generateGeoJson(plot);
      final jsonMap = jsonDecode(geoJsonStr) as Map<String, dynamic>;

      expect(jsonMap['type'], 'FeatureCollection');
      expect(jsonMap['features'], isNotEmpty);
      expect(jsonMap['features'][0]['geometry']['type'], 'Polygon');
      expect(
        jsonMap['features'][0]['properties']['area_sq_meters'],
        greaterThan(0),
      );
    });
  });
}
