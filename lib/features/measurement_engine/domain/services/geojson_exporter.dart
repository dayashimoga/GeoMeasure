import 'dart:convert';
import '../entities/spatial_shape.dart';

class GeoJsonExporter {
  /// Generates RFC 7946 GeoJSON FeatureCollection string for PlotShape or spatial boundaries
  static String generateGeoJson(
    PlotShape plot, {
    String projectName = 'GeoMeasure Parcel',
  }) {
    final List<List<double>> coords = plot.coordinates
        .map((c) => [c.longitude, c.latitude, c.altitudeMeters])
        .toList();

    if (coords.isNotEmpty) {
      coords.add(coords.first); // Close GeoJSON linear ring
    }

    final Map<String, dynamic> geoJsonMap = {
      'type': 'FeatureCollection',
      'features': [
        {
          'type': 'Feature',
          'properties': {
            'name': projectName,
            'area_sq_meters': plot.calculateAreaInSquareMeters(),
            'perimeter_meters': plot.calculatePerimeterInMeters(),
          },
          'geometry': {
            'type': 'Polygon',
            'coordinates': [coords],
          },
        },
      ],
    };

    return const JsonEncoder.withIndent('  ').convert(geoJsonMap);
  }
}
