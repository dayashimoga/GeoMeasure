import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../../measurement_engine/domain/entities/measurement_result.dart';
import '../../measurement_engine/domain/services/unit_converter.dart';

class MeasurementDisplay extends StatelessWidget {
  final MeasurementResult result;

  const MeasurementDisplay({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final geoColors = theme.extension<GeoMeasureColors>();
    final algoColor = AppTheme.algorithmColor(result.algorithmUsed.name);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: algoColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    result.algorithmUsed.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: algoColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                _accuracyBadge(theme, geoColors),
              ],
            ),
            const SizedBox(height: 16),

            // Measurement grid
            Semantics(
              label: 'Measurement results',
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _metricTile(
                    theme,
                    icon: Icons.square_foot_rounded,
                    label: 'Area',
                    value: result.area.toStringAsFixed(3),
                    unit: UnitConverter.areaUnitLabel(result.areaUnit),
                  ),
                  _metricTile(
                    theme,
                    icon: Icons.straighten_rounded,
                    label: 'Perimeter',
                    value: result.perimeter.toStringAsFixed(3),
                    unit: UnitConverter.distanceUnitLabel(result.distanceUnit),
                  ),
                  if (result.volume > 0)
                    _metricTile(
                      theme,
                      icon: Icons.view_in_ar_rounded,
                      label: 'Volume',
                      value: result.volume.toStringAsFixed(3),
                      unit: 'm³',
                    ),
                ],
              ),
            ),

            if (result.shapeName.isNotEmpty &&
                !result.shapeName.startsWith('INVALID')) ...[
              const SizedBox(height: 8),
              Text(
                result.shapeName,
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accuracyBadge(ThemeData theme, GeoMeasureColors? colors) {
    final pct = result.estimatedAccuracyPercentage;
    final color = pct >= 95
        ? (colors?.success ?? Colors.green)
        : pct >= 85
            ? (colors?.warning ?? Colors.amber)
            : (colors?.info ?? Colors.blue);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '${pct.toStringAsFixed(0)}% accuracy',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _metricTile(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required String unit,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: theme.colorScheme.primary),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
