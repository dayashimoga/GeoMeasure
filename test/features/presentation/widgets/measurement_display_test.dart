import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_algorithm.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_result.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/presentation/widgets/measurement_display.dart';

void main() {
  testWidgets('MeasurementDisplay renders result', (
    WidgetTester tester,
  ) async {
    final result = MeasurementResult(
      area: 25.5,
      areaUnit: AreaUnit.squareMeters,
      perimeter: 20.0,
      distanceUnit: DistanceUnit.meters,
      volume: 76.5,
      algorithmUsed: MeasurementAlgorithm.arCoreArKit,
      estimatedAccuracyPercentage: 95.0,
      shapeType: ShapeType.room,
      shapeName: 'Living Room',
    );
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: MeasurementDisplay(result: result))),
    );
    // Verify algorithm name renders
    expect(find.text('ARCore / ARKit Visual-Inertial'), findsOneWidget);
    // Verify accuracy badge
    expect(find.text('95% accuracy'), findsOneWidget);
    // Verify metric values
    expect(find.text('Area'), findsOneWidget);
    expect(find.text('Perimeter'), findsOneWidget);
    expect(find.text('Volume'), findsOneWidget);
  });
}
