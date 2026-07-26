import 'package:flutter/material.dart';
import '../../../measurement_engine/domain/entities/spatial_shape.dart';
import '../../../measurement_engine/domain/services/unit_converter.dart';
import '../../../measurement_engine/domain/entities/measurement_unit.dart';

/// Interactive 2D floor plan canvas renderer.
///
/// Uses CustomPainter for high-performance hardware-accelerated
/// rendering of shapes, dimensions, and annotations.
class FloorPlanCanvas extends StatefulWidget {
  final SpatialShape? shape;
  final List<Point3D> vertices;
  final bool showGrid;
  final bool showDimensions;
  final bool showNorthArrow;
  final DistanceUnit distanceUnit;

  const FloorPlanCanvas({
    super.key,
    this.shape,
    this.vertices = const [],
    this.showGrid = true,
    this.showDimensions = true,
    this.showNorthArrow = true,
    this.distanceUnit = DistanceUnit.meters,
  });

  @override
  State<FloorPlanCanvas> createState() => _FloorPlanCanvasState();
}

class _FloorPlanCanvasState extends State<FloorPlanCanvas>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;
  Offset _offset = Offset.zero;
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GestureDetector(
          onScaleStart: (details) {},
          onScaleUpdate: (details) {
            setState(() {
              _scale = (_scale * details.scale).clamp(0.3, 5.0);
              _offset += details.focalPointDelta;
            });
          },
          child: SizedBox(
            height: 300,
            width: double.infinity,
            child: CustomPaint(
              painter: _FloorPlanPainter(
                shape: widget.shape,
                vertices: widget.vertices,
                scale: _scale,
                offset: _offset,
                showGrid: widget.showGrid,
                showDimensions: widget.showDimensions,
                showNorthArrow: widget.showNorthArrow,
                distanceUnit: widget.distanceUnit,
                primaryColor: theme.colorScheme.primary,
                surfaceColor: theme.colorScheme.surface,
                gridColor:
                    theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                textColor: theme.colorScheme.onSurface,
                accentColor: theme.colorScheme.secondary,
              ),
              size: Size.infinite,
            ),
          ),
        ),
      ),
    );
  }
}

class _FloorPlanPainter extends CustomPainter {
  final SpatialShape? shape;
  final List<Point3D> vertices;
  final double scale;
  final Offset offset;
  final bool showGrid;
  final bool showDimensions;
  final bool showNorthArrow;
  final DistanceUnit distanceUnit;
  final Color primaryColor;
  final Color surfaceColor;
  final Color gridColor;
  final Color textColor;
  final Color accentColor;

  _FloorPlanPainter({
    required this.shape,
    required this.vertices,
    required this.scale,
    required this.offset,
    required this.showGrid,
    required this.showDimensions,
    required this.showNorthArrow,
    required this.distanceUnit,
    required this.primaryColor,
    required this.surfaceColor,
    required this.gridColor,
    required this.textColor,
    required this.accentColor,
  });

  static const double _ppm = 50.0; // pixels per meter

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(
      size.width / 2 + offset.dx,
      size.height / 2 + offset.dy,
    );
    canvas.scale(scale);

    if (showGrid) _drawGrid(canvas, size);
    if (showNorthArrow) _drawNorthArrow(canvas, size);

    if (shape != null) {
      _drawShape(canvas, shape!);
    } else if (vertices.isNotEmpty) {
      _drawVertices(canvas, vertices);
    }

    canvas.restore();
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = gridColor
      ..strokeWidth = 0.5;

    final extent = (size.longestSide / scale).ceil() + 200;
    const gridSpacing = _ppm; // 1 meter grid

    for (double x = -extent.toDouble(); x <= extent; x += gridSpacing) {
      canvas.drawLine(
        Offset(x, -extent.toDouble()),
        Offset(x, extent.toDouble()),
        paint,
      );
    }
    for (double y = -extent.toDouble(); y <= extent; y += gridSpacing) {
      canvas.drawLine(
        Offset(-extent.toDouble(), y),
        Offset(extent.toDouble(), y),
        paint,
      );
    }

    // Origin axes
    final axisPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.4)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(-extent.toDouble(), 0),
      Offset(extent.toDouble(), 0),
      axisPaint,
    );
    canvas.drawLine(
      Offset(0, -extent.toDouble()),
      Offset(0, extent.toDouble()),
      axisPaint,
    );
  }

  void _drawNorthArrow(Canvas canvas, Size size) {
    final arrowPos = Offset(
      -(size.width / 2 - 30) / scale - offset.dx / scale,
      -(size.height / 2 - 30) / scale - offset.dy / scale,
    );

    final arrowPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(arrowPos.dx, arrowPos.dy - 12)
      ..lineTo(arrowPos.dx - 6, arrowPos.dy + 6)
      ..lineTo(arrowPos.dx + 6, arrowPos.dy + 6)
      ..close();
    canvas.drawPath(path, arrowPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(
          color: accentColor,
          fontSize: 10 / scale,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(arrowPos.dx - textPainter.width / 2, arrowPos.dy - 24),
    );
  }

  void _drawShape(Canvas canvas, SpatialShape shape) {
    if (shape is RectangleShape) {
      _drawRectangle(canvas, shape);
    } else if (shape is CircleShape) {
      _drawCircle(canvas, shape);
    } else if (shape is IrregularPolygonShape) {
      _drawPolygon(canvas, shape.vertices);
    } else if (shape is WallShape) {
      _drawWall(canvas, shape);
    }
  }

  void _drawRectangle(Canvas canvas, RectangleShape rect) {
    final w = rect.lengthMeters * _ppm;
    final h = rect.widthMeters * _ppm;

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      const Radius.circular(2),
    );
    canvas.drawRRect(rrect, fillPaint);
    canvas.drawRRect(rrect, strokePaint);

    // Vertices
    _drawVertexDot(canvas, Offset(-w / 2, -h / 2));
    _drawVertexDot(canvas, Offset(w / 2, -h / 2));
    _drawVertexDot(canvas, Offset(w / 2, h / 2));
    _drawVertexDot(canvas, Offset(-w / 2, h / 2));

    if (showDimensions) {
      _drawDimensionLabel(
          canvas, Offset(0, -h / 2 - 10), _formatDistance(rect.lengthMeters));
      _drawDimensionLabel(
          canvas, Offset(w / 2 + 10, 0), _formatDistance(rect.widthMeters));
    }
  }

  void _drawCircle(Canvas canvas, CircleShape circle) {
    final r = circle.radiusMeters * _ppm;

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(Offset.zero, r, fillPaint);
    canvas.drawCircle(Offset.zero, r, strokePaint);

    // Radius line
    final radiusPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset.zero, Offset(r, 0), radiusPaint);

    if (showDimensions) {
      _drawDimensionLabel(canvas, Offset(r / 2, -10),
          'r=${_formatDistance(circle.radiusMeters)}');
    }
  }

  void _drawPolygon(Canvas canvas, List<Point3D> verts) {
    if (verts.length < 2) return;

    final offsets = verts.map((v) => Offset(v.x * _ppm, v.y * _ppm)).toList();

    // Center the polygon
    double cx = 0, cy = 0;
    for (final o in offsets) {
      cx += o.dx;
      cy += o.dy;
    }
    cx /= offsets.length;
    cy /= offsets.length;

    final centered = offsets.map((o) => Offset(o.dx - cx, o.dy - cy)).toList();

    final path = Path()..moveTo(centered.first.dx, centered.first.dy);
    for (int i = 1; i < centered.length; i++) {
      path.lineTo(centered[i].dx, centered[i].dy);
    }
    path.close();

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);

    for (final o in centered) {
      _drawVertexDot(canvas, o);
    }

    // Edge dimensions
    if (showDimensions) {
      for (int i = 0; i < verts.length; i++) {
        final next = (i + 1) % verts.length;
        final dist = verts[i].distanceTo(verts[next]);
        final midPx = Offset(
          (centered[i].dx + centered[next].dx) / 2,
          (centered[i].dy + centered[next].dy) / 2 - 8,
        );
        _drawDimensionLabel(canvas, midPx, _formatDistance(dist));
      }
    }
  }

  void _drawWall(Canvas canvas, WallShape wall) {
    final w = wall.lengthMeters * _ppm;
    final h = wall.heightMeters * _ppm;

    final wallPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      wallPaint,
    );
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: w, height: h),
      strokePaint,
    );

    // Draw openings
    final openingPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    final openingStroke = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    double xOffset = -w / 2 + 20;
    for (final opening in wall.openings) {
      final ow = opening.widthMeters * _ppm;
      final oh = opening.heightMeters * _ppm;
      final rect = Rect.fromLTWH(xOffset, h / 2 - oh, ow, oh);
      canvas.drawRect(rect, openingPaint);
      canvas.drawRect(rect, openingStroke);

      if (showDimensions) {
        _drawDimensionLabel(
          canvas,
          Offset(rect.center.dx, rect.top - 6),
          opening.label,
        );
      }

      xOffset += ow + 30;
    }
  }

  void _drawVertices(Canvas canvas, List<Point3D> verts) {
    _drawPolygon(canvas, verts);
  }

  void _drawVertexDot(Canvas canvas, Offset position) {
    canvas.drawCircle(position, 5, Paint()..color = primaryColor);
    canvas.drawCircle(
      position,
      5,
      Paint()
        ..color = surfaceColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  void _drawDimensionLabel(Canvas canvas, Offset position, String text) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: 10 / scale.clamp(0.5, 2.0),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Background
    final bgRect = Rect.fromCenter(
      center: position,
      width: textPainter.width + 8,
      height: textPainter.height + 4,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(3)),
      Paint()..color = surfaceColor.withValues(alpha: 0.85),
    );

    textPainter.paint(
      canvas,
      Offset(
        position.dx - textPainter.width / 2,
        position.dy - textPainter.height / 2,
      ),
    );
  }

  String _formatDistance(double meters) {
    final converted = UnitConverter.convertDistance(
      valueMeters: meters,
      targetUnit: distanceUnit,
    );
    final label = UnitConverter.distanceUnitLabel(distanceUnit);
    return '${converted.toStringAsFixed(2)} $label';
  }

  @override
  bool shouldRepaint(covariant _FloorPlanPainter old) =>
      shape != old.shape ||
      vertices != old.vertices ||
      scale != old.scale ||
      offset != old.offset ||
      showGrid != old.showGrid ||
      showDimensions != old.showDimensions;
}
