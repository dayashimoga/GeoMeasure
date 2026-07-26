import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/export/export_manager.dart';
import '../../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../../measurement_engine/domain/entities/measurement_result.dart';
import '../../measurement_engine/domain/services/unit_converter.dart';

/// Measurement history page with filtering, search, and export.
class MeasurementHistoryPage extends StatefulWidget {
  const MeasurementHistoryPage({super.key});

  @override
  State<MeasurementHistoryPage> createState() => _MeasurementHistoryPageState();
}

class _MeasurementHistoryPageState extends State<MeasurementHistoryPage> {
  String _searchQuery = '';
  String _filterAlgorithm = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement History'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list_rounded),
            onSelected: (val) => setState(() => _filterAlgorithm = val),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('All Algorithms')),
              const PopupMenuItem(value: 'lidar', child: Text('LiDAR')),
              const PopupMenuItem(
                  value: 'arCoreArKit', child: Text('ARCore/ARKit')),
              const PopupMenuItem(value: 'gpsImu', child: Text('GPS+IMU')),
              const PopupMenuItem(value: 'manual', child: Text('Manual')),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _exportAll(context),
            tooltip: 'Export All as CSV',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: sl.measurementProvider,
        builder: (context, _) {
          final history = sl.measurementProvider.history;
          final filtered = _applyFilters(history);

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64, color: theme.colorScheme.outline),
                  const SizedBox(height: 12),
                  Text(
                    history.isEmpty
                        ? 'No measurements yet'
                        : 'No matching measurements',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search by shape name...',
                    prefixIcon: Icon(Icons.search_rounded),
                    isDense: true,
                  ),
                  onChanged: (q) => setState(() => _searchQuery = q),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} measurement${filtered.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (_filterAlgorithm != 'all')
                      Chip(
                        label: Text(_filterAlgorithm,
                            style: const TextStyle(fontSize: 12)),
                        deleteIcon: const Icon(Icons.close, size: 14),
                        onDeleted: () =>
                            setState(() => _filterAlgorithm = 'all'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) =>
                      _buildHistoryItem(theme, filtered[i], i),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<MeasurementResult> _applyFilters(List<MeasurementResult> history) {
    var results = history.toList();

    if (_filterAlgorithm != 'all') {
      results = results
          .where((r) => r.algorithmUsed.name == _filterAlgorithm)
          .toList();
    }

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      results = results
          .where((r) =>
              r.shapeName.toLowerCase().contains(q) ||
              r.shapeType.name.toLowerCase().contains(q))
          .toList();
    }

    return results.reversed.toList();
  }

  Widget _buildHistoryItem(
      ThemeData theme, MeasurementResult result, int index) {
    return Semantics(
      label:
          'Measurement ${index + 1}: ${result.shapeName.isNotEmpty ? result.shapeName : result.shapeType.name}, '
          '${result.area.toStringAsFixed(2)} ${UnitConverter.areaUnitLabel(result.areaUnit)}',
      child: Card(
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              _shapeIcon(result.shapeType),
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(
            result.shapeName.isNotEmpty
                ? result.shapeName
                : result.shapeType.name,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${result.area.toStringAsFixed(2)} ${UnitConverter.areaUnitLabel(result.areaUnit)} • '
            '${result.algorithmUsed.displayName} • '
            '${result.estimatedAccuracyPercentage.toStringAsFixed(0)}%',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          trailing: Text(
            _formatTimestamp(result.timestamp),
            style: TextStyle(
              fontSize: 11,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      ),
    );
  }

  IconData _shapeIcon(dynamic shapeType) {
    switch (shapeType.toString()) {
      case 'ShapeType.rectangle':
      case 'ShapeType.square':
        return Icons.crop_square_rounded;
      case 'ShapeType.circle':
      case 'ShapeType.ellipse':
        return Icons.circle_outlined;
      case 'ShapeType.triangle':
        return Icons.change_history_rounded;
      case 'ShapeType.room':
        return Icons.meeting_room_rounded;
      case 'ShapeType.wall':
        return Icons.sensor_window_rounded;
      case 'ShapeType.plot':
        return Icons.terrain_rounded;
      case 'ShapeType.building':
        return Icons.apartment_rounded;
      default:
        return Icons.square_foot_rounded;
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${dt.month}/${dt.day}';
  }

  void _exportAll(BuildContext context) {
    final csv = ExportManager.exportToString(
      format: ExportFormat.csv,
      history: sl.measurementProvider.history,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('CSV Export'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(csv,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11)),
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
