import '../entities/spatial_shape.dart';

class DxfExporter {
  /// Generates ASCII AutoCAD DXF (R12 standard) representation of a spatial shape
  static String generateDxf(SpatialShape shape, {String layerName = 'GEOMEASURE_LAYER'}) {
    final buffer = StringBuffer();

    // DXF Header Section
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('HEADER');
    buffer.writeln('0');
    buffer.writeln('ENDSEC');

    // DXF Tables Section
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('TABLES');
    buffer.writeln('0');
    buffer.writeln('ENDSEC');

    // DXF Entities Section
    buffer.writeln('0');
    buffer.writeln('SECTION');
    buffer.writeln('2');
    buffer.writeln('ENTITIES');

    if (shape is RectangleShape) {
      _writePolyline(buffer, layerName, [
        const Point3D(0, 0),
        Point3D(shape.lengthMeters, 0),
        Point3D(shape.lengthMeters, shape.widthMeters),
        Point3D(0, shape.widthMeters),
      ]);
    } else if (shape is IrregularPolygonShape) {
      _writePolyline(buffer, layerName, shape.vertices);
    } else if (shape is CircleShape) {
      buffer.writeln('0');
      buffer.writeln('CIRCLE');
      buffer.writeln('8');
      buffer.writeln(layerName);
      buffer.writeln('10'); // Center X
      buffer.writeln('0.0');
      buffer.writeln('20'); // Center Y
      buffer.writeln('0.0');
      buffer.writeln('40'); // Radius
      buffer.writeln(shape.radiusMeters.toString());
    }

    buffer.writeln('0');
    buffer.writeln('ENDSEC');

    // EOF
    buffer.writeln('0');
    buffer.writeln('EOF');

    return buffer.toString();
  }

  static void _writePolyline(StringBuffer buffer, String layer, List<Point3D> points) {
    if (points.isEmpty) return;

    for (int i = 0; i < points.length; i++) {
      final next = (i + 1) % points.length;
      buffer.writeln('0');
      buffer.writeln('LINE');
      buffer.writeln('8');
      buffer.writeln(layer);
      buffer.writeln('10');
      buffer.writeln(points[i].x.toString());
      buffer.writeln('20');
      buffer.writeln(points[i].y.toString());
      buffer.writeln('11');
      buffer.writeln(points[next].x.toString());
      buffer.writeln('21');
      buffer.writeln(points[next].y.toString());
    }
  }
}
