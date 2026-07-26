import 'package:flutter/material.dart';
import '../../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../../measurement_engine/domain/entities/measurement_result.dart';

class MeasurementDisplay extends StatelessWidget {
  final MeasurementResult result;

  const MeasurementDisplay({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Technique: ${result.algorithmUsed.displayName}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blueAccent,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Calculated Area: ${result.area.toStringAsFixed(2)} ${result.areaUnit.name}',
            ),
            Text(
              'Perimeter / Boundary: ${result.perimeter.toStringAsFixed(2)} ${result.distanceUnit.name}',
            ),
            if (result.volume > 0)
              Text('Volume: ${result.volume.toStringAsFixed(2)} m³'),
            const SizedBox(height: 8),
            Text(
              'Estimated Accuracy: ${result.estimatedAccuracyPercentage.toStringAsFixed(1)}%',
            ),
          ],
        ),
      ),
    );
  }
}
