import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../measurement_engine/domain/entities/measurement_unit.dart';

/// Displays aggregate statistics from measurement history.
///
/// Shows total measurements, total area, most-used shape, averages.
class MeasurementStats extends StatelessWidget {
  const MeasurementStats({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final history = sl.measurementProvider.history;

    if (history.isEmpty) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(Icons.analytics_outlined,
                  size: 32, color: theme.colorScheme.outline),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('No Measurements Yet',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        )),
                    Text('Start measuring to see statistics here',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.5),
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Compute stats
    final totalCount = history.length;
    double totalArea = 0;
    double maxArea = 0;
    double minArea = double.infinity;
    final shapeCounts = <String, int>{};

    for (final r in history) {
      totalArea += r.area;
      if (r.area > maxArea) maxArea = r.area;
      if (r.area > 0 && r.area < minArea) minArea = r.area;
      final name = r.shapeType.name;
      shapeCounts[name] = (shapeCounts[name] ?? 0) + 1;
    }

    if (minArea == double.infinity) minArea = 0;
    final avgArea = totalArea / totalCount;

    // Most used shape
    String mostUsed = 'N/A';
    int mostUsedCount = 0;
    for (final e in shapeCounts.entries) {
      if (e.value > mostUsedCount) {
        mostUsed = e.key;
        mostUsedCount = e.value;
      }
    }

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
            Row(
              children: [
                Icon(Icons.analytics_rounded,
                    size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('MEASUREMENT SUMMARY',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _statTile(
                    theme, Icons.tag_rounded, totalCount.toString(), 'Total'),
                _statTile(theme, Icons.square_foot_rounded,
                    '${totalArea.toStringAsFixed(1)} m²', 'Area'),
                _statTile(theme, Icons.trending_up_rounded,
                    '${avgArea.toStringAsFixed(1)} m²', 'Average'),
                _statTile(theme, Icons.star_rounded, _capitalize(mostUsed),
                    'Top Shape'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat(theme, 'Largest', '${maxArea.toStringAsFixed(1)} m²'),
                const SizedBox(width: 16),
                _miniStat(
                    theme, 'Smallest', '${minArea.toStringAsFixed(1)} m²'),
                const SizedBox(width: 16),
                _miniStat(theme, 'Types Used', '${shapeCounts.length}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile(ThemeData theme, IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.primary),
          const SizedBox(height: 4),
          Text(value,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              )),
        ],
      ),
    );
  }

  Widget _miniStat(ThemeData theme, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                )),
            Text(value,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
          ],
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
