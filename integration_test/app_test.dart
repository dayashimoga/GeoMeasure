import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:geomeasure/core/di/service_locator.dart';
import 'package:geomeasure/main.dart';

/// Integration test for the core measurement flow.
///
/// Run with: flutter test integration_test/app_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    sl.init();
  });

  testWidgets('Complete measurement flow: select mode → measure → view result',
      (WidgetTester tester) async {
    await tester.pumpWidget(const GeoMeasureApp());
    await tester.pumpAndSettle();

    // Verify app launches with dashboard
    expect(find.text('GeoMeasure'), findsOneWidget);
    expect(find.text('Measure'), findsOneWidget);

    // Tap Room mode
    expect(find.text('Room'), findsOneWidget);

    // Execute measurement
    final measureBtn = find.byKey(const Key('execute_measurement_button'));
    expect(measureBtn, findsOneWidget);
    await tester.tap(measureBtn);
    await tester.pumpAndSettle();

    // Verify results appear
    expect(find.text('Area'), findsOneWidget);
    expect(find.text('Perimeter'), findsOneWidget);

    // Verify export options appear
    expect(find.text('DXF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
  });

  testWidgets('Navigation to GPS tracking page', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoMeasureApp());
    await tester.pumpAndSettle();

    // Tap GPS button in AppBar
    final gpsButton = find.byTooltip('GPS Land Survey');
    expect(gpsButton, findsOneWidget);
    await tester.tap(gpsButton);
    await tester.pumpAndSettle();

    // Verify GPS tracking page loaded
    expect(find.text('GPS Land Survey'), findsOneWidget);
    expect(find.text('Tracking Inactive'), findsOneWidget);
  });

  testWidgets('Navigation to measurement history', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoMeasureApp());
    await tester.pumpAndSettle();

    // First create a measurement
    final measureBtn = find.byKey(const Key('execute_measurement_button'));
    await tester.tap(measureBtn);
    await tester.pumpAndSettle();

    // Navigate to history
    final historyBtn = find.byTooltip('Measurement History');
    expect(historyBtn, findsOneWidget);
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    // Verify history page loaded
    expect(find.text('Measurement History'), findsOneWidget);
  });

  testWidgets('Project creation flow', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoMeasureApp());
    await tester.pumpAndSettle();

    // Navigate to Projects tab
    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();

    // Verify empty state
    expect(find.text('No projects yet'), findsOneWidget);

    // Tap Create First Project
    await tester.tap(find.text('Create First Project'));
    await tester.pumpAndSettle();

    // Enter project name
    await tester.enterText(find.byType(TextField).last, 'Test Project');
    await tester.pumpAndSettle();

    // Submit
    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    // Verify project was created
    expect(find.text('Test Project'), findsOneWidget);
  });

  testWidgets('Theme toggle works', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoMeasureApp());
    await tester.pumpAndSettle();

    // Find theme toggle button
    final toggleBtn = find.byTooltip('Toggle Theme');
    expect(toggleBtn, findsOneWidget);

    // Toggle theme
    await tester.tap(toggleBtn);
    await tester.pumpAndSettle();

    // Toggle back
    await tester.tap(toggleBtn);
    await tester.pumpAndSettle();

    // App should still be functional
    expect(find.text('GeoMeasure'), findsOneWidget);
  });
}
