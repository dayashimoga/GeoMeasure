import 'dart:convert';
import '../entities/spatial_shape.dart';
import 'geodetic_calculator.dart';

/// Generates KML (Keyhole Markup Language) for Google Earth / Maps.
///
/// Compliant with KML 2.2 specification (OGC standard).
class KmlExporter {
  /// Generate KML document from a PlotShape with GPS coordinates.
  static String generateKml(
    PlotShape plot, {
    String documentName = 'GeoMeasure Survey',
    String placemarkName = 'Surveyed Plot',
    String description = '',
    String lineColor = 'ff0000ff',
    String fillColor = '400000ff',
    double lineWidth = 2.0,
  }) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln(
        '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">');
    buf.writeln('  <Document>');
    buf.writeln('    <name>${_xmlEscape(documentName)}</name>');
    buf.writeln('    <Style id="plotStyle">');
    buf.writeln('      <LineStyle>');
    buf.writeln('        <color>$lineColor</color>');
    buf.writeln('        <width>$lineWidth</width>');
    buf.writeln('      </LineStyle>');
    buf.writeln('      <PolyStyle>');
    buf.writeln('        <color>$fillColor</color>');
    buf.writeln('      </PolyStyle>');
    buf.writeln('    </Style>');
    buf.writeln('    <Placemark>');
    buf.writeln('      <name>${_xmlEscape(placemarkName)}</name>');

    final area = plot.calculateAreaInSquareMeters();
    final perimeter = plot.calculatePerimeterInMeters();
    final desc = description.isNotEmpty
        ? description
        : 'Area: ${area.toStringAsFixed(2)} m² | Perimeter: ${perimeter.toStringAsFixed(2)} m';
    buf.writeln('      <description>${_xmlEscape(desc)}</description>');
    buf.writeln('      <styleUrl>#plotStyle</styleUrl>');
    buf.writeln('      <Polygon>');
    buf.writeln('        <extrude>0</extrude>');
    buf.writeln('        <altitudeMode>clampToGround</altitudeMode>');
    buf.writeln('        <outerBoundaryIs>');
    buf.writeln('          <LinearRing>');
    buf.writeln('            <coordinates>');

    for (final coord in plot.coordinates) {
      buf.writeln(
          '              ${coord.longitude},${coord.latitude},${coord.altitudeMeters}');
    }
    // Close the ring
    if (plot.coordinates.isNotEmpty) {
      final first = plot.coordinates.first;
      buf.writeln(
          '              ${first.longitude},${first.latitude},${first.altitudeMeters}');
    }

    buf.writeln('            </coordinates>');
    buf.writeln('          </LinearRing>');
    buf.writeln('        </outerBoundaryIs>');
    buf.writeln('      </Polygon>');
    buf.writeln('    </Placemark>');
    buf.writeln('  </Document>');
    buf.writeln('</kml>');

    return buf.toString();
  }

  /// Generate KML for a set of waypoints (GPS path).
  static String generateWaypointKml(
    List<GpsCoordinate> waypoints, {
    String name = 'GPS Survey Path',
  }) {
    final buf = StringBuffer();
    buf.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buf.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buf.writeln('  <Document>');
    buf.writeln('    <name>${_xmlEscape(name)}</name>');
    buf.writeln('    <Placemark>');
    buf.writeln('      <name>Survey Path</name>');
    buf.writeln('      <LineString>');
    buf.writeln('        <altitudeMode>clampToGround</altitudeMode>');
    buf.writeln('        <coordinates>');

    for (final wp in waypoints) {
      buf.writeln(
          '          ${wp.longitude},${wp.latitude},${wp.altitudeMeters}');
    }

    buf.writeln('        </coordinates>');
    buf.writeln('      </LineString>');
    buf.writeln('    </Placemark>');

    // Individual waypoint markers
    for (int i = 0; i < waypoints.length; i++) {
      buf.writeln('    <Placemark>');
      buf.writeln('      <name>Point ${i + 1}</name>');
      buf.writeln('      <Point>');
      buf.writeln(
          '        <coordinates>${waypoints[i].longitude},${waypoints[i].latitude},${waypoints[i].altitudeMeters}</coordinates>');
      buf.writeln('      </Point>');
      buf.writeln('    </Placemark>');
    }

    buf.writeln('  </Document>');
    buf.writeln('</kml>');
    return buf.toString();
  }

  static String _xmlEscape(String input) {
    return const HtmlEscape(HtmlEscapeMode.element).convert(input);
  }
}
