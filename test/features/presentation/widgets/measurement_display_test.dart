import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:meassure_app/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:meassure_app/features/presentation/widgets/measurement_display.dart';

void main() {
  testWidgets('MeasurementDisplay renders measurement results correctly', (WidgetTester tester) async {
    const result = MeasurementResult(
      area: 25.5,
      areaUnit: AreaUnit.squareMeters,
      perimeter: 20.0,
      distanceUnit: DistanceUnit.meters,
      volume: 76.5,
      algorithmUsed: MeasurementAlgorithm.arCoreArKit,
      estimatedAccuracyPercentage: 95.0,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MeasurementDisplay(result: result),
        ),
      ),
    );

    expect(find.text('Selected Technique: ARCore / ARKit Visual-Inertial'), findsOneWidget);
    expect(find.text('Calculated Area: 25.50 squareMeters'), findsOneWidget);
    expect(find.text('Perimeter / Boundary: 20.00 meters'), findsOneWidget);
    expect(find.text('Volume: 76.50 m³'), findsOneWidget);
    expect(find.text('Estimated Accuracy: 95.0%'), findsOneWidget);
  });
}
