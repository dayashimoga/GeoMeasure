import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../measurement_engine/domain/entities/measurement_unit.dart';
import '../../measurement_engine/domain/entities/spatial_shape.dart';
import 'gps_tracking_page.dart';

/// Step-by-step measurement wizard for guided measurements.
///
/// Steps: Select Mode → Choose Shape → Enter Dimensions → Review → Save
class MeasurementWizardPage extends StatefulWidget {
  const MeasurementWizardPage({super.key});

  @override
  State<MeasurementWizardPage> createState() => _MeasurementWizardPageState();
}

class _MeasurementWizardPageState extends State<MeasurementWizardPage> {
  int _currentStep = 0;

  // Step 1: Mode
  String _selectedMode = 'Room';

  // Step 2: Shape
  String _selectedShape = 'Rectangle';

  // Step 3: Dimensions — empty fields, user must enter real values
  final _lengthController = TextEditingController();
  final _widthController = TextEditingController();
  final _heightController = TextEditingController();
  final _radiusController = TextEditingController();

  // Step 4: Unit
  DistanceUnit _selectedUnit = DistanceUnit.meters;

  static const _modes = ['Room', 'Land', 'Building', 'Object'];
  static const _shapes = [
    'Rectangle',
    'Circle',
    'Triangle',
    'L-Shape',
    'Irregular',
  ];
  static const _shapeIcons = [
    Icons.crop_square_rounded,
    Icons.circle_outlined,
    Icons.change_history_rounded,
    Icons.view_quilt_rounded,
    Icons.pentagon_rounded,
  ];

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  double get _area {
    final l = double.tryParse(_lengthController.text) ?? 0;
    final w = double.tryParse(_widthController.text) ?? 0;
    final r = double.tryParse(_radiusController.text) ?? 0;

    switch (_selectedShape) {
      case 'Circle':
        return 3.14159 * r * r;
      case 'Triangle':
        return 0.5 * l * w;
      default:
        return l * w;
    }
  }

  double get _volume {
    final h = double.tryParse(_heightController.text) ?? 0;
    return _area * h;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement Wizard'),
        centerTitle: true,
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: _currentStep < 3
            ? () => setState(() => _currentStep++)
            : () => _saveMeasurement(),
        onStepCancel:
            _currentStep > 0 ? () => setState(() => _currentStep--) : null,
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton.icon(
                  onPressed: details.onStepContinue,
                  icon: Icon(_currentStep < 3
                      ? Icons.arrow_forward_rounded
                      : Icons.check_rounded),
                  label: Text(_currentStep < 3 ? 'Next' : 'Save'),
                ),
                if (_currentStep > 0) ...[
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: details.onStepCancel,
                    child: const Text('Back'),
                  ),
                ],
              ],
            ),
          );
        },
        steps: [
          // Step 1: Select Mode
          Step(
            title: const Text('Measurement Mode'),
            subtitle: Text(_selectedMode),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.indexed,
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _modes.map((mode) {
                final selected = mode == _selectedMode;
                return ChoiceChip(
                  label: Text(mode),
                  selected: selected,
                  onSelected: (_) => setState(() => _selectedMode = mode),
                  avatar: Icon(_modeIcon(mode), size: 18),
                );
              }).toList(),
            ),
          ),

          // Step 2: Choose Shape
          Step(
            title: const Text('Shape'),
            subtitle: Text(_selectedShape),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.indexed,
            content: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(_shapes.length, (i) {
                final selected = _shapes[i] == _selectedShape;
                return ChoiceChip(
                  label: Text(_shapes[i]),
                  selected: selected,
                  onSelected: (_) =>
                      setState(() => _selectedShape = _shapes[i]),
                  avatar: Icon(_shapeIcons[i], size: 18),
                );
              }),
            ),
          ),

          // Step 3: Dimensions
          Step(
            title: const Text('Dimensions'),
            subtitle: Text(_dimensionSummary),
            isActive: _currentStep >= 2,
            state: _currentStep > 2 ? StepState.complete : StepState.indexed,
            content: Column(
              children: [
                if (_selectedShape == 'Circle') ...[
                  _DimensionField(
                    controller: _radiusController,
                    label: 'Radius',
                    icon: Icons.radio_button_unchecked,
                    unit: _selectedUnit,
                    onChanged: () => setState(() {}),
                  ),
                ] else ...[
                  _DimensionField(
                    controller: _lengthController,
                    label: 'Length',
                    icon: Icons.straighten_rounded,
                    unit: _selectedUnit,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _DimensionField(
                    controller: _widthController,
                    label: 'Width',
                    icon: Icons.straighten_rounded,
                    unit: _selectedUnit,
                    onChanged: () => setState(() {}),
                  ),
                ],
                const SizedBox(height: 12),
                _DimensionField(
                  controller: _heightController,
                  label: 'Height',
                  icon: Icons.height_rounded,
                  unit: _selectedUnit,
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: 12),
                SegmentedButton<DistanceUnit>(
                  segments: const [
                    ButtonSegment(value: DistanceUnit.meters, label: Text('m')),
                    ButtonSegment(value: DistanceUnit.feet, label: Text('ft')),
                    ButtonSegment(
                        value: DistanceUnit.inches, label: Text('in')),
                  ],
                  selected: {_selectedUnit},
                  onSelectionChanged: (s) =>
                      setState(() => _selectedUnit = s.first),
                ),
              ],
            ),
          ),

          // Step 4: Review
          Step(
            title: const Text('Review & Save'),
            isActive: _currentStep >= 3,
            content: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ReviewRow('Mode', _selectedMode, Icons.straighten_rounded),
                    _ReviewRow(
                        'Shape', _selectedShape, Icons.crop_square_rounded),
                    _ReviewRow('Area', '${_area.toStringAsFixed(2)} m²',
                        Icons.square_foot_rounded),
                    _ReviewRow('Volume', '${_volume.toStringAsFixed(2)} m³',
                        Icons.view_in_ar_rounded),
                    _ReviewRow('Unit', _selectedUnit.name, Icons.tune_rounded),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: _saveMeasurement,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Save to Active Project'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _dimensionSummary {
    if (_selectedShape == 'Circle') {
      return 'r=${_radiusController.text} ${_selectedUnit.name}';
    }
    return '${_lengthController.text}×${_widthController.text}×${_heightController.text} ${_selectedUnit.name}';
  }

  IconData _modeIcon(String mode) {
    switch (mode) {
      case 'Room':
        return Icons.meeting_room_rounded;
      case 'Land':
        return Icons.terrain_rounded;
      case 'Building':
        return Icons.apartment_rounded;
      case 'Object':
        return Icons.category_rounded;
      default:
        return Icons.straighten_rounded;
    }
  }

  void _saveMeasurement() {
    // Land mode → redirect to GPS tracking
    if (_selectedMode == 'Land') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const GpsTrackingPage()),
      );
      return;
    }

    final l = double.tryParse(_lengthController.text);
    final w = double.tryParse(_widthController.text);
    final h = double.tryParse(_heightController.text);
    final r = double.tryParse(_radiusController.text);

    SpatialShape shape;
    if (_selectedShape == 'Circle') {
      if (r == null || r <= 0) {
        _showValidationError();
        return;
      }
      shape = CircleShape(radiusMeters: r);
    } else if (_selectedShape == 'Triangle') {
      if (l == null || w == null || l <= 0 || w <= 0) {
        _showValidationError();
        return;
      }
      shape = TriangleShape(
        sideA: l,
        sideB: w,
        sideC: l, // isosceles approximation
      );
    } else {
      if (l == null || w == null || l <= 0 || w <= 0) {
        _showValidationError();
        return;
      }
      if (_selectedMode == 'Room' && h != null && h > 0) {
        shape = RoomShape(
          vertices: [
            const Point3D(0, 0),
            Point3D(l, 0),
            Point3D(l, w),
            Point3D(0, w),
          ],
          heightMeters: h,
        );
      } else {
        shape = RectangleShape(lengthMeters: l, widthMeters: w);
      }
    }

    sl.measurementProvider.calculateMeasurement(
      shape: shape,
      profile: sl.capabilityProvider.profile,
      shapeName: '$_selectedMode $_selectedShape',
    );
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Measurement saved'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showValidationError() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please enter valid positive dimensions'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _DimensionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final DistanceUnit unit;
  final VoidCallback onChanged;

  const _DimensionField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.unit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: '$label (${unit.name})',
        hintText: 'Enter value',
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
        isDense: true,
      ),
      onChanged: (_) => onChanged(),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _ReviewRow(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
