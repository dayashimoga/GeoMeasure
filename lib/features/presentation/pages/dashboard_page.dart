import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';
import '../../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../../measurement_engine/domain/entities/measurement_unit.dart';
import '../../measurement_engine/domain/entities/spatial_shape.dart';
import '../../measurement_engine/domain/services/unit_converter.dart';
import '../widgets/export_panel.dart';
import '../widgets/algorithm_banner.dart';
import '../widgets/settings_tab.dart';
import '../../estimation/domain/entities/material_estimate.dart';
import '../../visualization/presentation/widgets/floor_plan_canvas.dart';
import '../widgets/measurement_display.dart';
import 'gps_tracking_page.dart';
import 'camera_measurement_page.dart';
import 'measurement_history_page.dart';
import 'measurement_wizard_page.dart';
import 'quick_measure_page.dart';
import 'multi_room_page.dart';
import '../widgets/paint_tile_calculator.dart';
import '../widgets/measurement_stats.dart';

/// Consumer-grade Universal AI Measurement Platform Dashboard.
///
/// Features auto hardware selection, camera-first workflows,
/// Material 3 styling, and clean spacing without diagnostic clutter.
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
        centerTitle: false,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.architecture_rounded,
                  color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text(
              'GeoMeasure',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_fix_high_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const MeasurementWizardPage(),
              ),
            ),
            tooltip: 'Measurement Wizard',
          ),
          IconButton(
            icon: const Icon(Icons.gps_fixed_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GpsTrackingPage()),
            ),
            tooltip: 'GPS Survey',
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeasurementHistoryPage()),
            ),
            tooltip: 'History',
          ),
          ListenableBuilder(
            listenable: sl.measurementProvider,
            builder: (context, _) => Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.undo_rounded, size: 20),
                  onPressed: sl.commandManager.canUndo
                      ? () {
                          sl.commandManager.undo();
                          setState(() {});
                        }
                      : null,
                  tooltip: sl.commandManager.lastUndoDescription ?? 'Undo',
                ),
                IconButton(
                  icon: const Icon(Icons.redo_rounded, size: 20),
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
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.straighten_rounded), text: 'Measure'),
            Tab(icon: Icon(Icons.folder_special_rounded), text: 'Projects'),
            Tab(icon: Icon(Icons.tune_rounded), text: 'Settings'),
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
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'camera_scan_fab',
        onPressed: () {
          final profile = sl.capabilityProvider.profile;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CameraMeasurementPage(profile: profile),
            ),
          );
        },
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Live Camera Scan'),
        elevation: 4,
      ),
    );
  }

  // ━━━ Measure Tab ━━━
  Widget _buildMeasureTab(bool isWide) {
    return ListenableBuilder(
      listenable: sl.capabilityProvider,
      builder: (context, _) {
        final theme = Theme.of(context);
        final profile = sl.capabilityProvider.profile;

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    children: [
                      _buildAlgorithmBanner(profile),
                      const SizedBox(height: 12),
                      _buildQuickToolsGrid(theme),
                      const SizedBox(height: 12),
                      _buildModeSelector(profile),
                      const SizedBox(height: 12),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  child: Column(
                    children: [
                      _buildUnitSelector(),
                      const SizedBox(height: 12),
                      const MeasurementStats(),
                      const SizedBox(height: 12),
                      _buildResultsPanel(),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
          child: Column(
            children: [
              _buildAlgorithmBanner(profile),
              const SizedBox(height: 12),
              _buildQuickToolsGrid(theme),
              const SizedBox(height: 12),
              _buildUnitSelector(),
              const SizedBox(height: 12),
              _buildModeSelector(profile),
              const SizedBox(height: 12),
              _buildFloorPlanToggle(),
              if (_showFloorPlan) _buildFloorPlanView(),
              const SizedBox(height: 12),
              const MeasurementStats(),
              const SizedBox(height: 12),
              _buildResultsPanel(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickToolsGrid(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SPECIALIZED MEASUREMENT TOOLS',
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
                  child: _toolButton(
                    theme: theme,
                    icon: Icons.calculate_rounded,
                    label: 'Quick Measure',
                    subtitle: 'Direct shape input',
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const QuickMeasurePage()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _toolButton(
                    theme: theme,
                    icon: Icons.home_work_rounded,
                    label: 'Multi-Room',
                    subtitle: 'Full house survey',
                    color: theme.colorScheme.secondary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MultiRoomPage()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _toolButton(
                    theme: theme,
                    icon: Icons.format_paint_rounded,
                    label: 'Paint & Tiles',
                    subtitle: 'Material quantities',
                    color: theme.colorScheme.tertiary,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const PaintTileCalculator()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _toolButton(
                    theme: theme,
                    icon: Icons.history_rounded,
                    label: 'History & Logs',
                    subtitle: 'Saved records',
                    color: theme.colorScheme.outline,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const MeasurementHistoryPage()),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toolButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 10,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlgorithmBanner(CapabilityProfile profile) {
    final isLoading = sl.capabilityProvider.isLoading;
    final algo = sl.measurementProvider.lastResult?.algorithmUsed ??
        (isLoading ? null : profile.bestAlgorithm);
    final algoName = isLoading
        ? 'Detecting Hardware...'
        : (algo?.displayName ?? 'Manual Fallback Engine');
    final algoColor = algo != null
        ? AppTheme.algorithmColor(algo.name)
        : Theme.of(context).colorScheme.outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: algoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: algoColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          PulsingDot(color: algoColor, isAnimating: isLoading),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLoading ? 'Scanning Sensors' : 'AUTO ENGINE SELECTED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  algoName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: algoColor,
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
                        ? '${sl.measurementProvider.lastResult!.estimatedAccuracyPercentage.toStringAsFixed(0)}% acc'
                        : '${profile.bestConfidence.toStringAsFixed(0)}% conf',
                    style: TextStyle(
                      fontSize: 11,
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
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
                    icon: Icons.square_foot_rounded,
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
                    icon: Icons.straighten_rounded,
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
                        style: const TextStyle(fontSize: 13)),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildModeSelector(CapabilityProfile profile) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SELECT TARGET OBJECT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 12),
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
                icon: Icon(_selectedModeIndex == 2
                    ? Icons.gps_fixed_rounded
                    : Icons.play_arrow_rounded),
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
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.grid_on_rounded, size: 18),
              const SizedBox(width: 8),
              const Text('Floor Plan Blueprint Canvas',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: FloorPlanCanvas(
        shape: sl.measurementProvider.lastShape,
        distanceUnit: sl.measurementProvider.targetDistanceUnit,
      ),
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
            const SizedBox(height: 12),
            _buildMaterialEstimation(),
            const SizedBox(height: 12),
            const ExportPanel(),
            const SizedBox(height: 12),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.construction_rounded,
              color: theme.colorScheme.tertiary, size: 22),
        ),
        title: const Text(
          'Material Quantity Take-off',
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
                        item.material.name
                            .replaceAll(RegExp(r'([A-Z])'), r' $1')
                            .trim(),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${item.adjustedQuantity.toStringAsFixed(1)} ${item.unit.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    if (item.totalCost > 0) ...[
                      const SizedBox(width: 8),
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
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MeasurementHistoryPage()),
            ),
            icon: const Icon(Icons.history_rounded, size: 18),
            label: const Text('History'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const GpsTrackingPage()),
            ),
            icon: const Icon(Icons.gps_fixed_rounded, size: 18),
            label: const Text('GPS Track'),
          ),
        ),
      ],
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
        // Navigate to real GPS tracking for land measurement
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const GpsTrackingPage()),
        );
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
    final lengthCtrl = TextEditingController();
    final widthCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
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
            Text(
              'Enter your room\'s actual dimensions. '
              'Use a tape measure for best accuracy.',
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            _dimensionField(lengthCtrl, 'Length (m)', Icons.straighten_rounded,
                hint: 'e.g. 5.2'),
            const SizedBox(height: 12),
            _dimensionField(widthCtrl, 'Width (m)', Icons.straighten_rounded,
                hint: 'e.g. 3.8'),
            const SizedBox(height: 12),
            _dimensionField(heightCtrl, 'Height (m)', Icons.height_rounded,
                hint: 'e.g. 2.8'),
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
              final l = double.tryParse(lengthCtrl.text);
              final w = double.tryParse(widthCtrl.text);
              final h = double.tryParse(heightCtrl.text);
              if (l == null ||
                  w == null ||
                  h == null ||
                  l <= 0 ||
                  w <= 0 ||
                  h <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid positive dimensions'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _runMeasurement(
                  profile,
                  RoomShape(
                    vertices: [
                      const Point3D(0, 0),
                      Point3D(l, 0),
                      Point3D(l, w),
                      Point3D(0, w),
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
    final lengthCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
    final doorWCtrl = TextEditingController();
    final doorHCtrl = TextEditingController();
    final winWCtrl = TextEditingController();
    final winHCtrl = TextEditingController();
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
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Measure the wall with a tape measure or laser.',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(ctx)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              _dimensionField(
                  lengthCtrl, 'Wall Length (m)', Icons.straighten_rounded,
                  hint: 'e.g. 4.5'),
              const SizedBox(height: 12),
              _dimensionField(
                  heightCtrl, 'Wall Height (m)', Icons.height_rounded,
                  hint: 'e.g. 2.8'),
              const SizedBox(height: 20),
              Text(
                'OPENINGS (optional)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Theme.of(ctx).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dimensionField(
                        doorWCtrl, 'Door W', Icons.door_front_door_rounded,
                        hint: '0.9'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dimensionField(
                        doorHCtrl, 'Door H', Icons.door_front_door_rounded,
                        hint: '2.1'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _dimensionField(
                        winWCtrl, 'Window W', Icons.window_rounded,
                        hint: '1.2'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dimensionField(
                        winHCtrl, 'Window H', Icons.window_rounded,
                        hint: '1.2'),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.calculate_rounded, size: 18),
            onPressed: () {
              final l = double.tryParse(lengthCtrl.text);
              final h = double.tryParse(heightCtrl.text);
              if (l == null || h == null || l <= 0 || h <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid wall dimensions'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final openings = <WallOpening>[];
              final dw = double.tryParse(doorWCtrl.text);
              final dh = double.tryParse(doorHCtrl.text);
              if (dw != null && dh != null && dw > 0 && dh > 0) {
                openings.add(WallOpening(
                    label: 'Door', widthMeters: dw, heightMeters: dh));
              }
              final ww = double.tryParse(winWCtrl.text);
              final wh = double.tryParse(winHCtrl.text);
              if (ww != null && wh != null && ww > 0 && wh > 0) {
                openings.add(WallOpening(
                    label: 'Window', widthMeters: ww, heightMeters: wh));
              }
              Navigator.of(ctx).pop();
              _runMeasurement(
                  profile,
                  WallShape(
                    lengthMeters: l,
                    heightMeters: h,
                    openings: openings,
                  ));
            },
            label: const Text('Measure'),
          ),
        ],
      ),
    );
  }

  void _showObjectInput(CapabilityProfile profile) {
    final lengthCtrl = TextEditingController();
    final widthCtrl = TextEditingController();
    final heightCtrl = TextEditingController();
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
            Text(
              'Measure the object\'s length, width, and height.',
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            _dimensionField(lengthCtrl, 'Length (m)', Icons.straighten_rounded,
                hint: 'e.g. 1.8'),
            const SizedBox(height: 12),
            _dimensionField(widthCtrl, 'Width (m)', Icons.straighten_rounded,
                hint: 'e.g. 0.6'),
            const SizedBox(height: 12),
            _dimensionField(heightCtrl, 'Height (m)', Icons.height_rounded,
                hint: 'e.g. 0.9'),
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
              final l = double.tryParse(lengthCtrl.text);
              final w = double.tryParse(widthCtrl.text);
              final h = double.tryParse(heightCtrl.text);
              if (l == null ||
                  w == null ||
                  h == null ||
                  l <= 0 ||
                  w <= 0 ||
                  h <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid positive dimensions'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _runMeasurement(
                  profile,
                  CuboidShape(
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
    final lengthCtrl = TextEditingController();
    final widthCtrl = TextEditingController();
    final floorsCtrl = TextEditingController();
    final floorHCtrl = TextEditingController();
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
            Text(
              'Enter the building footprint and floor details.',
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),
            _dimensionField(lengthCtrl, 'Length (m)', Icons.straighten_rounded,
                hint: 'e.g. 20.0'),
            const SizedBox(height: 12),
            _dimensionField(widthCtrl, 'Width (m)', Icons.straighten_rounded,
                hint: 'e.g. 15.0'),
            const SizedBox(height: 12),
            _dimensionField(
                floorsCtrl, 'Number of Floors', Icons.layers_rounded,
                hint: 'e.g. 3'),
            const SizedBox(height: 12),
            _dimensionField(
                floorHCtrl, 'Floor Height (m)', Icons.height_rounded,
                hint: 'e.g. 3.0'),
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
              final l = double.tryParse(lengthCtrl.text);
              final w = double.tryParse(widthCtrl.text);
              final floors = int.tryParse(floorsCtrl.text);
              final fh = double.tryParse(floorHCtrl.text);
              if (l == null ||
                  w == null ||
                  floors == null ||
                  fh == null ||
                  l <= 0 ||
                  w <= 0 ||
                  floors <= 0 ||
                  fh <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter valid positive dimensions'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.of(ctx).pop();
              _runMeasurement(
                  profile,
                  BuildingShape(
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

  Widget _dimensionField(
      TextEditingController ctrl, String label, IconData icon,
      {String? hint}) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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

  // _executeMeasurement removed: Land mode now navigates to GPS tracking.
  // Room/Wall/Object/Building modes use validated input dialogs.

  String _getExecuteButtonText() {
    switch (_selectedModeIndex) {
      case 0:
        return 'Measure Room';
      case 1:
        return 'Measure Wall';
      case 2:
        return 'Start GPS Land Survey';
      case 3:
        return 'Measure Object';
      case 4:
        return 'Measure Building';
      default:
        return 'Measure';
    }
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
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: theme.colorScheme.outlineVariant),
                            ),
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
    return SettingsTab(onToggleTheme: widget.onToggleTheme);
  }
}
