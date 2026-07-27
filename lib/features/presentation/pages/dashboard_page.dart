import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';
import '../../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../../measurement_engine/domain/entities/measurement_unit.dart';
import '../../measurement_engine/domain/entities/spatial_shape.dart';
import '../../measurement_engine/domain/services/geodetic_calculator.dart';
import '../../measurement_engine/domain/services/unit_converter.dart';
import '../../estimation/domain/entities/material_estimate.dart';
import '../../visualization/presentation/widgets/floor_plan_canvas.dart';
import '../widgets/capability_card.dart';
import '../widgets/measurement_display.dart';
import 'gps_tracking_page.dart';
import 'measurement_history_page.dart';

class DashboardPage extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const DashboardPage({super.key, this.onToggleTheme});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  int _selectedModeIndex = 0;
  late TabController _tabController;
  bool _showFloorPlan = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    sl.capabilityProvider.loadCapabilities();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width > 720;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child:
                  const Icon(Icons.architecture, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('GeoMeasure'),
          ],
        ),
        actions: [
          // GPS tracking
          IconButton(
            icon: const Icon(Icons.gps_fixed_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GpsTrackingPage()),
            ),
            tooltip: 'GPS Land Survey',
          ),
          // Measurement history
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeasurementHistoryPage()),
            ),
            tooltip: 'Measurement History',
          ),
          // Undo/Redo
          ListenableBuilder(
            listenable: sl.measurementProvider,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo_rounded),
                  onPressed: sl.commandManager.canUndo
                      ? () {
                          sl.commandManager.undo();
                          setState(() {});
                        }
                      : null,
                  tooltip: sl.commandManager.lastUndoDescription ?? 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded),
                  onPressed: sl.commandManager.canRedo
                      ? () {
                          sl.commandManager.redo();
                          setState(() {});
                        }
                      : null,
                  tooltip: sl.commandManager.lastRedoDescription ?? 'Redo',
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
            ),
            onPressed: widget.onToggleTheme,
            tooltip: 'Toggle Theme',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => sl.capabilityProvider.loadCapabilities(),
            tooltip: 'Refresh Capabilities',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Measure'),
            Tab(icon: Icon(Icons.folder_rounded), text: 'Projects'),
            Tab(icon: Icon(Icons.settings_rounded), text: 'Settings'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMeasureTab(isWide),
          _buildProjectsTab(),
          _buildSettingsTab(theme),
        ],
      ),
    );
  }

  // ━━━ Measure Tab ━━━
  Widget _buildMeasureTab(bool isWide) {
    return ListenableBuilder(
      listenable: sl.capabilityProvider,
      builder: (context, _) {
        final profile = sl.capabilityProvider.profile;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _buildAlgorithmBanner(profile),
                      _buildModeSelector(profile),
                      _buildFloorPlanToggle(),
                      if (_showFloorPlan) _buildFloorPlanView(),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Column(
                    children: [
                      _buildUnitSelector(),
                      _buildResultsPanel(),
                      CapabilityCard(profile: profile),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            children: [
              _buildAlgorithmBanner(profile),
              _buildUnitSelector(),
              _buildModeSelector(profile),
              _buildFloorPlanToggle(),
              if (_showFloorPlan) _buildFloorPlanView(),
              _buildResultsPanel(),
              CapabilityCard(profile: profile),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlgorithmBanner(CapabilityProfile profile) {
    final isLoading = sl.capabilityProvider.isLoading;
    final algo = sl.measurementProvider.lastResult?.algorithmUsed
        ?? (isLoading ? null : profile.bestAlgorithm);
    final algoName = isLoading
        ? 'Detecting hardware...'
        : (algo?.displayName ?? 'Manual Input Fallback');
    final algoColor = algo != null
        ? AppTheme.algorithmColor(algo.name)
        : Theme.of(context).colorScheme.outline;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            algoColor.withValues(alpha: 0.18),
            algoColor.withValues(alpha: 0.05),
            Colors.transparent,
          ],
          stops: const [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: algoColor.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          _PulsingDot(color: algoColor, isAnimating: isLoading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? 'Scanning Sensors' : 'Active Engine',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    algoName,
                    key: ValueKey(algoName),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: algoColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (algo != null && !isLoading)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: algoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_rounded, size: 14, color: algoColor),
                  const SizedBox(width: 4),
                  Text(
                    sl.measurementProvider.lastResult != null
                        ? '${sl.measurementProvider.lastResult!.estimatedAccuracyPercentage.toStringAsFixed(0)}%'
                        : '${profile.sensorCount} sensors',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: algoColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUnitSelector() {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MEASUREMENT UNITS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildUnitDropdown<AreaUnit>(
                    label: 'Area',
                    icon: Icons.square_foot,
                    value: sl.measurementProvider.targetAreaUnit,
                    items: AreaUnit.values,
                    displayName: (u) => UnitConverter.areaUnitLabel(u),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() =>
                            sl.measurementProvider.updateUnits(areaUnit: val));
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildUnitDropdown<DistanceUnit>(
                    label: 'Distance',
                    icon: Icons.straighten,
                    value: sl.measurementProvider.targetDistanceUnit,
                    items: DistanceUnit.values,
                    displayName: (u) => UnitConverter.distanceUnitLabel(u),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => sl.measurementProvider
                            .updateUnits(distanceUnit: val));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitDropdown<T>({
    required String label,
    required IconData icon,
    required T value,
    required List<T> items,
    required String Function(T) displayName,
    required void Function(T?) onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 18),
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: true,
          items: items
              .map((u) => DropdownMenuItem(
                    value: u,
                    child: Text(displayName(u),
                        style: const TextStyle(fontSize: 14)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildModeSelector(CapabilityProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(
                    value: 0,
                    label: Text('Room'),
                    icon: Icon(Icons.meeting_room_rounded),
                  ),
                  ButtonSegment(
                    value: 1,
                    label: Text('Wall'),
                    icon: Icon(Icons.sensor_window_rounded),
                  ),
                  ButtonSegment(
                    value: 2,
                    label: Text('Land'),
                    icon: Icon(Icons.map_rounded),
                  ),
                  ButtonSegment(
                    value: 3,
                    label: Text('Object'),
                    icon: Icon(Icons.category_rounded),
                  ),
                  ButtonSegment(
                    value: 4,
                    label: Text('Building'),
                    icon: Icon(Icons.apartment_rounded),
                  ),
                ],
                selected: {_selectedModeIndex},
                onSelectionChanged: (set) {
                  setState(() => _selectedModeIndex = set.first);
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                key: const Key('execute_measurement_button'),
                onPressed: () => _showMeasurementInput(profile),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(_getExecuteButtonText()),
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloorPlanToggle() {
    return ListenableBuilder(
      listenable: sl.measurementProvider,
      builder: (context, _) {
        if (sl.measurementProvider.lastResult == null) {
          return const SizedBox.shrink();
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              const Icon(Icons.grid_on_rounded, size: 18),
              const SizedBox(width: 8),
              const Text('Floor Plan View', style: TextStyle(fontSize: 14)),
              const Spacer(),
              Switch.adaptive(
                value: _showFloorPlan,
                onChanged: (v) => setState(() => _showFloorPlan = v),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFloorPlanView() {
    return FloorPlanCanvas(
      shape: sl.measurementProvider.lastShape,
      distanceUnit: sl.measurementProvider.targetDistanceUnit,
    );
  }

  Widget _buildResultsPanel() {
    return ListenableBuilder(
      listenable: sl.measurementProvider,
      builder: (context, _) {
        final result = sl.measurementProvider.lastResult;
        if (result == null) return const SizedBox.shrink();

        return Column(
          children: [
            MeasurementDisplay(result: result),
            _buildMaterialEstimation(),
            _buildExportButtons(),
            _buildNavigationButtons(),
          ],
        );
      },
    );
  }

  Widget _buildMaterialEstimation() {
    final shape = sl.measurementProvider.lastShape;
    if (shape == null) return const SizedBox.shrink();

    QuantityTakeoff? takeoff;
    if (shape is RoomShape) {
      takeoff = MaterialEstimator.estimateForRoom(shape);
    } else if (shape is BuildingShape) {
      takeoff = MaterialEstimator.estimateForBuilding(shape);
    }
    if (takeoff == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Card(
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.tertiary.withValues(alpha: 0.15),
                theme.colorScheme.tertiary.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.construction_rounded,
              color: theme.colorScheme.tertiary, size: 22),
        ),
        title: const Text(
          'Material Estimation',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${takeoff.items.length} materials • \$${takeoff.totalCost.toStringAsFixed(0)} est.',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        initiallyExpanded: false,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          ...takeoff.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.material.name.replaceAll(
                            RegExp(r'([A-Z])'), r' $1').trim(),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${item.adjustedQuantity.toStringAsFixed(1)} ${item.unit.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (item.totalCost > 0) ...[                      const SizedBox(width: 8),
                      Text(
                        '\$${item.totalCost.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              )),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total Estimated Cost',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
              Text(
                '\$${takeoff.totalCost.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const MeasurementHistoryPage()),
              ),
              icon: const Icon(Icons.history_rounded, size: 18),
              label: const Text('History'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const GpsTrackingPage()),
              ),
              icon: const Icon(Icons.gps_fixed_rounded, size: 18),
              label: const Text('GPS Track'),
            ),
          ),
        ],
      ),
    );
  }

  void _showMeasurementInput(CapabilityProfile profile) {
    switch (_selectedModeIndex) {
      case 0:
        _showRoomInput(profile);
        break;
      case 1:
        _showWallInput(profile);
        break;
      case 2:
        _executeMeasurement(profile); // GPS uses preset coordinates
        break;
      case 3:
        _showObjectInput(profile);
        break;
      case 4:
        _showBuildingInput(profile);
        break;
    }
  }

  void _showRoomInput(CapabilityProfile profile) {
    final lengthCtrl = TextEditingController(text: '6.0');
    final widthCtrl = TextEditingController(text: '4.5');
    final heightCtrl = TextEditingController(text: '3.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.meeting_room_rounded, size: 24),
            SizedBox(width: 8),
            Text('Room Dimensions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dimensionField(lengthCtrl, 'Length (m)', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _dimensionField(widthCtrl, 'Width (m)', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _dimensionField(heightCtrl, 'Height (m)', Icons.height_rounded),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.calculate_rounded, size: 18),
            onPressed: () {
              final l = double.tryParse(lengthCtrl.text) ?? 6.0;
              final w = double.tryParse(widthCtrl.text) ?? 4.5;
              final h = double.tryParse(heightCtrl.text) ?? 3.0;
              Navigator.of(ctx).pop();
              _runMeasurement(profile, RoomShape(
                vertices: [
                  Point3D(0, 0), Point3D(l, 0),
                  Point3D(l, w), Point3D(0, w),
                ],
                heightMeters: h,
              ));
            },
            label: const Text('Measure'),
          ),
        ],
      ),
    );
  }

  void _showWallInput(CapabilityProfile profile) {
    final lengthCtrl = TextEditingController(text: '6.0');
    final heightCtrl = TextEditingController(text: '3.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.sensor_window_rounded, size: 24),
            SizedBox(width: 8),
            Text('Wall Dimensions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dimensionField(lengthCtrl, 'Length (m)', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _dimensionField(heightCtrl, 'Height (m)', Icons.height_rounded),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.calculate_rounded, size: 18),
            onPressed: () {
              final l = double.tryParse(lengthCtrl.text) ?? 6.0;
              final h = double.tryParse(heightCtrl.text) ?? 3.0;
              Navigator.of(ctx).pop();
              _runMeasurement(profile, WallShape(
                lengthMeters: l,
                heightMeters: h,
                openings: const [
                  WallOpening(label: 'Door', widthMeters: 0.9, heightMeters: 2.1),
                  WallOpening(label: 'Window', widthMeters: 1.2, heightMeters: 1.2),
                ],
              ));
            },
            label: const Text('Measure'),
          ),
        ],
      ),
    );
  }

  void _showObjectInput(CapabilityProfile profile) {
    final lengthCtrl = TextEditingController(text: '2.0');
    final widthCtrl = TextEditingController(text: '1.5');
    final heightCtrl = TextEditingController(text: '1.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.category_rounded, size: 24),
            SizedBox(width: 8),
            Text('Object Dimensions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dimensionField(lengthCtrl, 'Length (m)', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _dimensionField(widthCtrl, 'Width (m)', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _dimensionField(heightCtrl, 'Height (m)', Icons.height_rounded),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.calculate_rounded, size: 18),
            onPressed: () {
              final l = double.tryParse(lengthCtrl.text) ?? 2.0;
              final w = double.tryParse(widthCtrl.text) ?? 1.5;
              final h = double.tryParse(heightCtrl.text) ?? 1.0;
              Navigator.of(ctx).pop();
              _runMeasurement(profile, CuboidShape(
                lengthMeters: l,
                widthMeters: w,
                heightMeters: h,
              ));
            },
            label: const Text('Measure'),
          ),
        ],
      ),
    );
  }

  void _showBuildingInput(CapabilityProfile profile) {
    final lengthCtrl = TextEditingController(text: '20.0');
    final widthCtrl = TextEditingController(text: '15.0');
    final floorsCtrl = TextEditingController(text: '3');
    final floorHCtrl = TextEditingController(text: '3.0');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.apartment_rounded, size: 24),
            SizedBox(width: 8),
            Text('Building Dimensions'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dimensionField(lengthCtrl, 'Length (m)', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _dimensionField(widthCtrl, 'Width (m)', Icons.straighten_rounded),
            const SizedBox(height: 12),
            _dimensionField(floorsCtrl, 'Floors', Icons.layers_rounded),
            const SizedBox(height: 12),
            _dimensionField(floorHCtrl, 'Floor Height (m)', Icons.height_rounded),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.calculate_rounded, size: 18),
            onPressed: () {
              final l = double.tryParse(lengthCtrl.text) ?? 20.0;
              final w = double.tryParse(widthCtrl.text) ?? 15.0;
              final floors = int.tryParse(floorsCtrl.text) ?? 3;
              final fh = double.tryParse(floorHCtrl.text) ?? 3.0;
              Navigator.of(ctx).pop();
              _runMeasurement(profile, BuildingShape(
                baseFootprint: RectangleShape(
                  lengthMeters: l,
                  widthMeters: w,
                ),
                numberOfFloors: floors,
                floorHeightMeters: fh,
              ));
            },
            label: const Text('Measure'),
          ),
        ],
      ),
    );
  }

  Widget _dimensionField(TextEditingController ctrl, String label, IconData icon) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        isDense: true,
        border: const OutlineInputBorder(),
      ),
    );
  }

  void _runMeasurement(CapabilityProfile profile, SpatialShape shape) {
    sl.measurementProvider.calculateMeasurement(
      shape: shape,
      profile: profile,
    );
    setState(() => _showFloorPlan = true);
  }

  void _executeMeasurement(CapabilityProfile profile) {
    SpatialShape shape;
    if (_selectedModeIndex == 0) {
      shape = const RoomShape(
        vertices: [
          Point3D(0, 0),
          Point3D(6, 0),
          Point3D(6, 4.5),
          Point3D(0, 4.5),
        ],
        heightMeters: 3.0,
      );
    } else if (_selectedModeIndex == 1) {
      shape = const WallShape(
        lengthMeters: 6.0,
        heightMeters: 3.0,
        openings: [
          WallOpening(label: 'Door', widthMeters: 0.9, heightMeters: 2.1),
          WallOpening(label: 'Window', widthMeters: 1.2, heightMeters: 1.2),
        ],
      );
    } else {
      shape = const PlotShape(
        coordinates: [
          GpsCoordinate(latitude: 37.7749, longitude: -122.4194),
          GpsCoordinate(latitude: 37.7755, longitude: -122.4194),
          GpsCoordinate(latitude: 37.7755, longitude: -122.4185),
          GpsCoordinate(latitude: 37.7749, longitude: -122.4185),
        ],
      );
    }

    _runMeasurement(profile, shape);
  }

  String _getExecuteButtonText() {
    switch (_selectedModeIndex) {
      case 0:
        return 'Measure Room';
      case 1:
        return 'Measure Wall';
      case 2:
        return 'Measure Land Plot';
      case 3:
        return 'Measure Object';
      case 4:
        return 'Measure Building';
      default:
        return 'Measure';
    }
  }

  Widget _buildExportButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _exportChip('PDF', Icons.picture_as_pdf_rounded, () {
            _showExportDialog('PDF Report',
                'PDF export ready.\nUse share button to save/send.');
          }),
          _exportChip('DXF', Icons.architecture_rounded, () {
            final str = sl.measurementProvider.exportCurrentToDxf();
            _showExportDialog('AutoCAD DXF', str);
          }),
          _exportChip('CSV', Icons.table_chart_rounded, () {
            final str = sl.measurementProvider.exportHistoryToCsv();
            _showExportDialog('CSV Schedule', str);
          }),
          _exportChip('SVG', Icons.image_rounded, () {
            _showExportDialog('SVG', 'SVG floor plan export ready.');
          }),
          _exportChip('GeoJSON', Icons.public_rounded, () {
            final str = sl.measurementProvider.exportPlotToGeoJson();
            _showExportDialog(
                'GeoJSON', str.isNotEmpty ? str : 'Select Land mode first');
          }),
          _exportChip('KML', Icons.map_rounded, () {
            _showExportDialog('KML', 'KML export ready for Google Earth.');
          }),
          _exportChip('JSON', Icons.data_object_rounded, () {
            final result = sl.measurementProvider.lastResult;
            if (result != null) {
              _showExportDialog('JSON', result.toJson().toString());
            }
          }),
        ],
      ),
    );
  }

  Widget _exportChip(String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      onPressed: onTap,
    );
  }

  // ━━━ Projects Tab ━━━
  Widget _buildProjectsTab() {
    return ListenableBuilder(
      listenable: sl.projectProvider,
      builder: (context, _) {
        final projects = sl.projectProvider.projects;
        final theme = Theme.of(context);

        if (sl.projectProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search projects...',
                        prefixIcon: Icon(Icons.search_rounded),
                        isDense: true,
                      ),
                      onChanged: (q) => sl.projectProvider.searchProjects(q),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _showCreateProjectDialog,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('New'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: projects.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.folder_open_rounded,
                              size: 64, color: theme.colorScheme.outline),
                          const SizedBox(height: 12),
                          Text('No projects yet',
                              style:
                                  TextStyle(color: theme.colorScheme.outline)),
                          const SizedBox(height: 8),
                          FilledButton.tonal(
                            onPressed: _showCreateProjectDialog,
                            child: const Text('Create First Project'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: projects.length,
                      itemBuilder: (ctx, i) {
                        final p = projects[i];
                        return Semantics(
                          label:
                              'Project ${p.name}, ${p.measurementCount} measurements',
                          child: Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    theme.colorScheme.primaryContainer,
                                child: Icon(
                                  _projectTypeIcon(p.type),
                                  color: theme.colorScheme.onPrimaryContainer,
                                ),
                              ),
                              title: Text(p.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                '${p.measurementCount} measurements • ${p.type.name}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'delete', child: Text('Delete')),
                                ],
                                onSelected: (action) {
                                  if (action == 'delete') {
                                    sl.projectProvider.deleteProject(p.id);
                                  }
                                },
                              ),
                              onTap: () =>
                                  sl.projectProvider.setActiveProject(p),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  IconData _projectTypeIcon(dynamic type) {
    switch (type.toString()) {
      case 'ProjectType.indoor':
      case 'ProjectType.room':
        return Icons.meeting_room_rounded;
      case 'ProjectType.outdoor':
      case 'ProjectType.land':
        return Icons.terrain_rounded;
      case 'ProjectType.building':
        return Icons.apartment_rounded;
      case 'ProjectType.construction':
        return Icons.construction_rounded;
      case 'ProjectType.survey':
        return Icons.map_rounded;
      default:
        return Icons.folder_rounded;
    }
  }

  void _showCreateProjectDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Project'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Project Name',
            hintText: 'e.g. Living Room Survey',
          ),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isNotEmpty) {
                sl.projectProvider.createProject(name: name);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  // ━━━ Settings Tab ━━━
  Widget _buildSettingsTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: const Text('Dark Mode'),
                trailing: Switch.adaptive(
                  value: theme.brightness == Brightness.dark,
                  onChanged: (_) => widget.onToggleTheme?.call(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_rounded),
                title: const Text('Show Grid in Floor Plan'),
                trailing: Switch.adaptive(
                  value: _showFloorPlan,
                  onChanged: (v) => setState(() => _showFloorPlan = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'FEATURE FLAGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              ...sl.config.allFlags.entries.map((e) => SwitchListTile.adaptive(
                    title: Text(e.key.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 14)),
                    value: e.value,
                    dense: true,
                    onChanged: (v) {
                      setState(() => sl.config.setFeatureFlag(e.key, v));
                    },
                  )),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GeoMeasure v${AppConfig.appVersion}',
                    key: const Key('app_version_text'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                Text(
                  'Capability-Aware Spatial & Land Measurement Engine',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showExportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.8),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

/// Status dot indicator for sensor detection.
class _PulsingDot extends StatelessWidget {
  final Color color;
  final bool isAnimating;

  const _PulsingDot({required this.color, required this.isAnimating});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isAnimating ? 0.6 : 1.0),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: isAnimating ? 10 : 6,
            spreadRadius: isAnimating ? 2 : 0,
          ),
        ],
      ),
    );
  }
}
