import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/di/service_locator.dart';
import '../../measurement_engine/domain/entities/spatial_shape.dart';
import '../../measurement_engine/domain/entities/measurement_unit.dart';
import '../../measurement_engine/domain/services/unit_converter.dart';

/// Quick Measure — single-screen shape calculator with live preview.
///
/// Skip the wizard — select shape, enter dimensions, see instant results.
class QuickMeasurePage extends StatefulWidget {
  const QuickMeasurePage({super.key});

  @override
  State<QuickMeasurePage> createState() => _QuickMeasurePageState();
}

class _QuickMeasurePageState extends State<QuickMeasurePage> {
  ShapeType _selectedShape = ShapeType.rectangle;
  final _dim1 = TextEditingController();
  final _dim2 = TextEditingController();
  final _dim3 = TextEditingController();
  final _heightCtrl = TextEditingController();

  SpatialShape? _currentShape;
  String? _validationError;

  @override
  void dispose() {
    _dim1.dispose();
    _dim2.dispose();
    _dim3.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  static const _supportedShapes = [
    ShapeType.rectangle,
    ShapeType.square,
    ShapeType.circle,
    ShapeType.triangle,
    ShapeType.ellipse,
    ShapeType.trapezoid,
    ShapeType.room,
    ShapeType.wall,
  ];

  void _calculate() {
    final d1 = double.tryParse(_dim1.text);
    final d2 = double.tryParse(_dim2.text);
    final d3 = double.tryParse(_dim3.text);
    final h = double.tryParse(_heightCtrl.text);

    SpatialShape? shape;

    switch (_selectedShape) {
      case ShapeType.rectangle:
        if (d1 == null || d1 <= 0 || d2 == null || d2 <= 0) {
          setState(() => _validationError = 'Enter length and width');
          return;
        }
        shape = RectangleShape(lengthMeters: d1, widthMeters: d2);
      case ShapeType.square:
        if (d1 == null || d1 <= 0) {
          setState(() => _validationError = 'Enter side length');
          return;
        }
        shape = RectangleShape(lengthMeters: d1, widthMeters: d1);
      case ShapeType.circle:
        if (d1 == null || d1 <= 0) {
          setState(() => _validationError = 'Enter radius');
          return;
        }
        shape = CircleShape(radiusMeters: d1);
      case ShapeType.triangle:
        if (d1 == null ||
            d1 <= 0 ||
            d2 == null ||
            d2 <= 0 ||
            d3 == null ||
            d3 <= 0) {
          setState(() => _validationError = 'Enter all three sides');
          return;
        }
        shape = TriangleShape(sideA: d1, sideB: d2, sideC: d3);
      case ShapeType.ellipse:
        if (d1 == null || d1 <= 0 || d2 == null || d2 <= 0) {
          setState(
              () => _validationError = 'Enter semi-major and semi-minor axes');
          return;
        }
        shape = EllipseShape(semiMajorMeters: d1, semiMinorMeters: d2);
      case ShapeType.trapezoid:
        if (d1 == null ||
            d1 <= 0 ||
            d2 == null ||
            d2 <= 0 ||
            d3 == null ||
            d3 <= 0) {
          setState(() => _validationError = 'Enter parallel sides and height');
          return;
        }
        shape = TrapezoidShape(
            parallelSideA: d1, parallelSideB: d2, heightMeters: d3);
      case ShapeType.room:
        if (d1 == null ||
            d1 <= 0 ||
            d2 == null ||
            d2 <= 0 ||
            h == null ||
            h <= 0) {
          setState(() => _validationError = 'Enter length, width, and height');
          return;
        }
        shape = RoomShape(
          vertices: [
            const Point3D(0, 0),
            Point3D(d1, 0),
            Point3D(d1, d2),
            Point3D(0, d2),
          ],
          heightMeters: h,
        );
      case ShapeType.wall:
        if (d1 == null || d1 <= 0 || d2 == null || d2 <= 0) {
          setState(() => _validationError = 'Enter wall length and height');
          return;
        }
        shape = WallShape(lengthMeters: d1, heightMeters: d2);
      default:
        setState(() => _validationError = 'Shape not supported');
        return;
    }

    final err = shape.validate();
    if (err != null) {
      setState(() => _validationError = err);
      return;
    }

    setState(() {
      _currentShape = shape;
      _validationError = null;
    });

    // Save to measurement provider
    sl.measurementProvider.calculateMeasurement(
      shape: shape,
      profile: sl.capabilityProvider.profile,
      shapeName: '${_selectedShape.name} (Quick)',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Measure'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Shape selector
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _supportedShapes.map((s) {
                  final selected = s == _selectedShape;
                  return ChoiceChip(
                    label: Text(_shapeLabel(s)),
                    avatar: Icon(_shapeIcon(s), size: 18),
                    selected: selected,
                    onSelected: (_) {
                      setState(() {
                        _selectedShape = s;
                        _currentShape = null;
                        _validationError = null;
                        _dim1.clear();
                        _dim2.clear();
                        _dim3.clear();
                        _heightCtrl.clear();
                      });
                    },
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Shape preview
          SizedBox(
            height: 120,
            child: CustomPaint(
              painter: _ShapePreviewPainter(
                shapeType: _selectedShape,
                d1: double.tryParse(_dim1.text),
                d2: double.tryParse(_dim2.text),
                d3: double.tryParse(_dim3.text),
                color: theme.colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Input fields (dynamic per shape)
          ..._buildInputFields(),

          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_validationError!,
                  style:
                      TextStyle(color: theme.colorScheme.error, fontSize: 13)),
            ),

          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _calculate,
            icon: const Icon(Icons.calculate_rounded),
            label: const Text('Calculate'),
          ),

          // Results
          if (_currentShape != null) ...[
            const SizedBox(height: 24),
            _buildResults(theme),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildInputFields() {
    switch (_selectedShape) {
      case ShapeType.rectangle:
        return [
          _field(_dim1, 'Length', 'm', 'e.g. 5.0'),
          _field(_dim2, 'Width', 'm', 'e.g. 4.0'),
        ];
      case ShapeType.square:
        return [_field(_dim1, 'Side Length', 'm', 'e.g. 5.0')];
      case ShapeType.circle:
        return [_field(_dim1, 'Radius', 'm', 'e.g. 3.0')];
      case ShapeType.triangle:
        return [
          _field(_dim1, 'Side A', 'm', 'e.g. 3.0'),
          _field(_dim2, 'Side B', 'm', 'e.g. 4.0'),
          _field(_dim3, 'Side C', 'm', 'e.g. 5.0'),
        ];
      case ShapeType.ellipse:
        return [
          _field(_dim1, 'Semi-Major Axis', 'm', 'e.g. 5.0'),
          _field(_dim2, 'Semi-Minor Axis', 'm', 'e.g. 3.0'),
        ];
      case ShapeType.trapezoid:
        return [
          _field(_dim1, 'Parallel Side 1', 'm', 'e.g. 6.0'),
          _field(_dim2, 'Parallel Side 2', 'm', 'e.g. 4.0'),
          _field(_dim3, 'Height', 'm', 'e.g. 3.0'),
        ];
      case ShapeType.room:
        return [
          _field(_dim1, 'Length', 'm', 'e.g. 5.0'),
          _field(_dim2, 'Width', 'm', 'e.g. 4.0'),
          _field(_heightCtrl, 'Ceiling Height', 'm', 'e.g. 3.0'),
        ];
      case ShapeType.wall:
        return [
          _field(_dim1, 'Wall Length', 'm', 'e.g. 6.0'),
          _field(_dim2, 'Wall Height', 'm', 'e.g. 3.0'),
        ];
      default:
        return [];
    }
  }

  Widget _field(
      TextEditingController ctrl, String label, String suffix, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildResults(ThemeData theme) {
    final shape = _currentShape!;
    final area = shape.calculateAreaInSquareMeters();
    final perimeter = shape.calculatePerimeterInMeters();
    final volume = shape.calculateVolumeInCubicMeters();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RESULTS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                )),
            const SizedBox(height: 12),
            _resultTile(
                theme,
                Icons.square_foot_rounded,
                'Area',
                '${area.toStringAsFixed(3)} m²',
                '${UnitConverter.convertArea(valueSqMeters: area, targetUnit: AreaUnit.squareFeet).toStringAsFixed(2)} ft²'),
            const SizedBox(height: 8),
            _resultTile(
                theme,
                Icons.straighten_rounded,
                'Perimeter',
                '${perimeter.toStringAsFixed(3)} m',
                '${UnitConverter.convertDistance(valueMeters: perimeter, targetUnit: DistanceUnit.feet).toStringAsFixed(2)} ft'),
            if (volume > 0) ...[
              const SizedBox(height: 8),
              _resultTile(theme, Icons.view_in_ar_rounded, 'Volume',
                  '${volume.toStringAsFixed(3)} m³', null),
            ],
            if (shape is RoomShape) ...[
              const SizedBox(height: 8),
              _resultTile(theme, Icons.wallpaper_rounded, 'Wall Area',
                  '${shape.wallArea.toStringAsFixed(2)} m²', null),
            ],
          ],
        ),
      ),
    );
  }

  Widget _resultTile(ThemeData theme, IconData icon, String label, String value,
      String? secondary) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 13)),
        const Spacer(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                )),
            if (secondary != null)
              Text(secondary,
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )),
          ],
        ),
      ],
    );
  }

  String _shapeLabel(ShapeType s) {
    switch (s) {
      case ShapeType.rectangle:
        return 'Rectangle';
      case ShapeType.square:
        return 'Square';
      case ShapeType.circle:
        return 'Circle';
      case ShapeType.triangle:
        return 'Triangle';
      case ShapeType.ellipse:
        return 'Ellipse';
      case ShapeType.trapezoid:
        return 'Trapezoid';
      case ShapeType.room:
        return 'Room';
      case ShapeType.wall:
        return 'Wall';
      default:
        return s.name;
    }
  }

  IconData _shapeIcon(ShapeType s) {
    switch (s) {
      case ShapeType.rectangle:
        return Icons.crop_landscape_rounded;
      case ShapeType.square:
        return Icons.crop_square_rounded;
      case ShapeType.circle:
        return Icons.circle_outlined;
      case ShapeType.triangle:
        return Icons.change_history_rounded;
      case ShapeType.ellipse:
        return Icons.lens_rounded;
      case ShapeType.trapezoid:
        return Icons.hexagon_outlined;
      case ShapeType.room:
        return Icons.meeting_room_rounded;
      case ShapeType.wall:
        return Icons.border_all_rounded;
      default:
        return Icons.interests_rounded;
    }
  }
}

/// Simple shape preview painter.
class _ShapePreviewPainter extends CustomPainter {
  final ShapeType shapeType;
  final double? d1, d2, d3;
  final Color color;

  _ShapePreviewPainter({
    required this.shapeType,
    this.d1,
    this.d2,
    this.d3,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final maxDim = math.min(size.width, size.height) * 0.4;

    switch (shapeType) {
      case ShapeType.rectangle || ShapeType.room || ShapeType.wall:
        final w = maxDim;
        final h = maxDim * 0.7;
        final rect =
            Rect.fromCenter(center: Offset(cx, cy), width: w, height: h);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            strokePaint);
      case ShapeType.square:
        final s = maxDim * 0.8;
        final rect =
            Rect.fromCenter(center: Offset(cx, cy), width: s, height: s);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)), paint);
        canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(4)),
            strokePaint);
      case ShapeType.circle:
        canvas.drawCircle(Offset(cx, cy), maxDim * 0.45, paint);
        canvas.drawCircle(Offset(cx, cy), maxDim * 0.45, strokePaint);
      case ShapeType.triangle:
        final path = Path()
          ..moveTo(cx, cy - maxDim * 0.4)
          ..lineTo(cx - maxDim * 0.4, cy + maxDim * 0.3)
          ..lineTo(cx + maxDim * 0.4, cy + maxDim * 0.3)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
      case ShapeType.ellipse:
        final rect = Rect.fromCenter(
            center: Offset(cx, cy), width: maxDim, height: maxDim * 0.6);
        canvas.drawOval(rect, paint);
        canvas.drawOval(rect, strokePaint);
      case ShapeType.trapezoid:
        final path = Path()
          ..moveTo(cx - maxDim * 0.25, cy - maxDim * 0.3)
          ..lineTo(cx + maxDim * 0.25, cy - maxDim * 0.3)
          ..lineTo(cx + maxDim * 0.4, cy + maxDim * 0.3)
          ..lineTo(cx - maxDim * 0.4, cy + maxDim * 0.3)
          ..close();
        canvas.drawPath(path, paint);
        canvas.drawPath(path, strokePaint);
      default:
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ShapePreviewPainter old) =>
      old.shapeType != shapeType || old.d1 != d1 || old.d2 != d2;
}
