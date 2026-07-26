import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';
import '../../measurement_engine/domain/entities/measurement_unit.dart';
import '../../measurement_engine/domain/entities/spatial_shape.dart';
import '../../measurement_engine/domain/services/geodetic_calculator.dart';
import '../widgets/capability_card.dart';
import '../widgets/measurement_display.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedModeIndex = 0;

  @override
  void initState() {
    super.initState();
    sl.capabilityProvider.loadCapabilities();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoMeasure Spatial Engine'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => sl.capabilityProvider.loadCapabilities(),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: sl.capabilityProvider,
        builder: (context, _) {
          final profile = sl.capabilityProvider.profile;
          if (sl.capabilityProvider.isLoading || profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                CapabilityCard(profile: profile),
                _buildUnitSelector(),
                _buildModeSelector(profile),
                const SizedBox(height: 12),
                ListenableBuilder(
                  listenable: sl.measurementProvider,
                  builder: (context, _) {
                    final result = sl.measurementProvider.lastResult;
                    if (result == null) {
                      return const SizedBox.shrink();
                    }
                    return Column(
                      children: [
                        MeasurementDisplay(result: result),
                        _buildExportButtons(),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnitSelector() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Area Unit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<AreaUnit>(
                  value: sl.measurementProvider.targetAreaUnit,
                  items: AreaUnit.values.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        sl.measurementProvider.updateUnits(areaUnit: val);
                      });
                    }
                  },
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Distance Unit',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                DropdownButton<DistanceUnit>(
                  value: sl.measurementProvider.targetDistanceUnit,
                  items: DistanceUnit.values.map((unit) {
                    return DropdownMenuItem(
                      value: unit,
                      child: Text(unit.name),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        sl.measurementProvider.updateUnits(distanceUnit: val);
                      });
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector(CapabilityProfile profile) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Room'),
                  icon: Icon(Icons.meeting_room),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Wall'),
                  icon: Icon(Icons.sensor_window),
                ),
                ButtonSegment(
                  value: 2,
                  label: Text('Plot / Land'),
                  icon: Icon(Icons.map),
                ),
              ],
              selected: {_selectedModeIndex},
              onSelectionChanged: (set) {
                setState(() {
                  _selectedModeIndex = set.first;
                });
              },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
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
                      WallOpening(
                        label: 'Door 1',
                        widthMeters: 0.9,
                        heightMeters: 2.1,
                      ),
                      WallOpening(
                        label: 'Window 1',
                        widthMeters: 1.2,
                        heightMeters: 1.2,
                      ),
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
                sl.measurementProvider.calculateMeasurement(
                  shape: shape,
                  profile: profile,
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: Text(_getExecuteButtonText()),
            ),
          ],
        ),
      ),
    );
  }

  String _getExecuteButtonText() {
    switch (_selectedModeIndex) {
      case 0:
        return 'Measure Room Enclosure';
      case 1:
        return 'Measure Wall (With Deductions)';
      case 2:
        return 'Measure Land Plot (WGS84 GPS)';
      default:
        return 'Measure Shape';
    }
  }

  Widget _buildExportButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          OutlinedButton.icon(
            onPressed: () {
              final dxfStr = sl.measurementProvider.exportCurrentToDxf();
              _showExportDialog('AutoCAD DXF File Generated', dxfStr);
            },
            icon: const Icon(Icons.architecture),
            label: const Text('Export DXF'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              final geoJsonStr = sl.measurementProvider.exportPlotToGeoJson();
              _showExportDialog(
                'GeoJSON FeatureCollection',
                geoJsonStr.isNotEmpty ? geoJsonStr : 'Select Plot Mode',
              );
            },
            icon: const Icon(Icons.public),
            label: const Text('Export GeoJSON'),
          ),
          OutlinedButton.icon(
            onPressed: () {
              final csvStr = sl.measurementProvider.exportHistoryToCsv();
              _showExportDialog('CSV Dimensional Schedule', csvStr);
            },
            icon: const Icon(Icons.table_chart),
            label: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
