import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';
import '../../measurement_engine/domain/entities/measurement_algorithm.dart';

/// Displays the active measurement algorithm with confidence/accuracy badge.
class AlgorithmBanner extends StatelessWidget {
  final CapabilityProfile profile;

  const AlgorithmBanner({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = sl.capabilityProvider.isLoading;
    final algo = sl.measurementProvider.lastResult?.algorithmUsed ??
        (isLoading ? null : profile.bestAlgorithm);
    final algoName = isLoading
        ? 'Detecting Hardware...'
        : (algo?.displayName ?? 'Manual Fallback Engine');
    final algoColor = algo != null
        ? AppTheme.algorithmColor(algo.name)
        : theme.colorScheme.outline;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: algoColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: algoColor,
                      ),
                    )
                  : Icon(Icons.memory_rounded, color: algoColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ACTIVE ENGINE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
      ),
    );
  }
}

/// Status dot indicator for sensor detection.
class PulsingDot extends StatelessWidget {
  final Color color;
  final bool isAnimating;

  const PulsingDot({super.key, required this.color, required this.isAnimating});

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
