import '../entities/spatial_shape.dart';

/// Generates SVG (Scalable Vector Graphics) output for spatial shapes.
///
/// SVG is resolution-independent and embeddable in HTML and PDF reports.
class SvgExporter {
  static const double _padding = 20.0;
  static const double _scale = 50.0; // pixels per meter

  /// Generate a standalone SVG document from a shape.
  static String generateSvg(
    SpatialShape shape, {
    String strokeColor = '#0D6EFD',
    String fillColor = '#E8F4FD',
    double strokeWidth = 2.0,
    bool showDimensions = true,
    bool showGrid = true,
  }) {
    if (shape is RectangleShape) {
      return _rectangleSvg(
          shape, strokeColor, fillColor, strokeWidth, showDimensions, showGrid);
    } else if (shape is CircleShape) {
      return _circleSvg(
          shape, strokeColor, fillColor, strokeWidth, showDimensions, showGrid);
    } else if (shape is IrregularPolygonShape) {
      return _polygonSvg(
          shape, strokeColor, fillColor, strokeWidth, showDimensions, showGrid);
    } else if (shape is TriangleShape) {
      return _triangleSvg(
          shape, strokeColor, fillColor, strokeWidth, showDimensions, showGrid);
    }

    return _emptySvg();
  }

  static String _rectangleSvg(
    RectangleShape shape,
    String stroke,
    String fill,
    double sw,
    bool dims,
    bool grid,
  ) {
    final w = shape.lengthMeters * _scale;
    final h = shape.widthMeters * _scale;
    final svgW = w + _padding * 2;
    final svgH = h + _padding * 2 + (dims ? 30 : 0);

    final buf = StringBuffer();
    buf.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $svgW $svgH" width="$svgW" height="$svgH">');
    if (grid) buf.writeln(_gridPattern(svgW, svgH));
    buf.writeln(
        '  <rect x="$_padding" y="$_padding" width="$w" height="$h" fill="$fill" stroke="$stroke" stroke-width="$sw" rx="2"/>');

    if (dims) {
      final midX = _padding + w / 2;
      final bottomY = _padding + h + 20;
      buf.writeln(
          '  <text x="$midX" y="$bottomY" text-anchor="middle" font-size="12" fill="#333">${shape.lengthMeters.toStringAsFixed(2)}m × ${shape.widthMeters.toStringAsFixed(2)}m</text>');
      buf.writeln(
          '  <text x="$midX" y="${bottomY + 14}" text-anchor="middle" font-size="11" fill="#666">Area: ${shape.calculateAreaInSquareMeters().toStringAsFixed(2)} m²</text>');
    }

    buf.writeln('</svg>');
    return buf.toString();
  }

  static String _circleSvg(
    CircleShape shape,
    String stroke,
    String fill,
    double sw,
    bool dims,
    bool grid,
  ) {
    final r = shape.radiusMeters * _scale;
    final size = r * 2 + _padding * 2;
    final svgH = size + (dims ? 30 : 0);
    final cx = _padding + r;
    final cy = _padding + r;

    final buf = StringBuffer();
    buf.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $size $svgH" width="$size" height="$svgH">');
    if (grid) buf.writeln(_gridPattern(size, svgH));
    buf.writeln(
        '  <circle cx="$cx" cy="$cy" r="$r" fill="$fill" stroke="$stroke" stroke-width="$sw"/>');
    buf.writeln(
        '  <line x1="$cx" y1="$cy" x2="${cx + r}" y2="$cy" stroke="#EF4444" stroke-width="1.5" stroke-dasharray="5,3"/>');

    if (dims) {
      buf.writeln(
          '  <text x="$cx" y="${cy + r + 24}" text-anchor="middle" font-size="12" fill="#333">r = ${shape.radiusMeters.toStringAsFixed(2)}m | Area: ${shape.calculateAreaInSquareMeters().toStringAsFixed(2)} m²</text>');
    }

    buf.writeln('</svg>');
    return buf.toString();
  }

  static String _polygonSvg(
    IrregularPolygonShape shape,
    String stroke,
    String fill,
    double sw,
    bool dims,
    bool grid,
  ) {
    if (shape.vertices.isEmpty) return _emptySvg();

    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final v in shape.vertices) {
      if (v.x < minX) minX = v.x;
      if (v.y < minY) minY = v.y;
      if (v.x > maxX) maxX = v.x;
      if (v.y > maxY) maxY = v.y;
    }

    final w = (maxX - minX) * _scale + _padding * 2;
    final h = (maxY - minY) * _scale + _padding * 2 + (dims ? 30 : 0);

    final points = shape.vertices
        .map((v) =>
            '${(v.x - minX) * _scale + _padding},${(v.y - minY) * _scale + _padding}')
        .join(' ');

    final buf = StringBuffer();
    buf.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h" width="$w" height="$h">');
    if (grid) buf.writeln(_gridPattern(w, h));
    buf.writeln(
        '  <polygon points="$points" fill="$fill" stroke="$stroke" stroke-width="$sw" stroke-linejoin="round"/>');

    // Vertex markers
    for (int i = 0; i < shape.vertices.length; i++) {
      final v = shape.vertices[i];
      final sx = (v.x - minX) * _scale + _padding;
      final sy = (v.y - minY) * _scale + _padding;
      buf.writeln(
          '  <circle cx="$sx" cy="$sy" r="4" fill="$stroke" stroke="white" stroke-width="1.5"/>');
    }

    if (dims) {
      buf.writeln(
          '  <text x="${w / 2}" y="${h - 4}" text-anchor="middle" font-size="11" fill="#333">Area: ${shape.calculateAreaInSquareMeters().toStringAsFixed(2)} m² | Perimeter: ${shape.calculatePerimeterInMeters().toStringAsFixed(2)} m</text>');
    }

    buf.writeln('</svg>');
    return buf.toString();
  }

  static String _triangleSvg(
    TriangleShape shape,
    String stroke,
    String fill,
    double sw,
    bool dims,
    bool grid,
  ) {
    // Layout equilateral-ish triangle with base = sideA
    final baseLen = shape.sideA * _scale;
    final height =
        shape.calculateAreaInSquareMeters() * 2 / shape.sideA * _scale;
    final w = baseLen + _padding * 2;
    final h = height + _padding * 2 + (dims ? 30 : 0);

    final buf = StringBuffer();
    buf.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $w $h" width="$w" height="$h">');
    if (grid) buf.writeln(_gridPattern(w, h));

    const x1 = _padding;
    final y1 = _padding + height;
    final x2 = _padding + baseLen;
    final y2 = y1;
    final x3 = _padding + baseLen / 2;
    const y3 = _padding;

    buf.writeln(
        '  <polygon points="$x1,$y1 $x2,$y2 $x3,$y3" fill="$fill" stroke="$stroke" stroke-width="$sw" stroke-linejoin="round"/>');

    if (dims) {
      buf.writeln(
          '  <text x="${w / 2}" y="${h - 4}" text-anchor="middle" font-size="11" fill="#333">Area: ${shape.calculateAreaInSquareMeters().toStringAsFixed(2)} m²</text>');
    }

    buf.writeln('</svg>');
    return buf.toString();
  }

  static String _gridPattern(double w, double h) {
    return '''  <defs>
    <pattern id="grid" width="25" height="25" patternUnits="userSpaceOnUse">
      <path d="M 25 0 L 0 0 0 25" fill="none" stroke="#E5E7EB" stroke-width="0.5"/>
    </pattern>
  </defs>
  <rect width="$w" height="$h" fill="url(#grid)"/>''';
  }

  static String _emptySvg() =>
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 50" width="100" height="50"><text x="50" y="25" text-anchor="middle" font-size="10" fill="#999">No shape</text></svg>';
}
