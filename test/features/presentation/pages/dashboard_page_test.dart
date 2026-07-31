import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/core/di/service_locator.dart';
import 'package:geomeasure/features/presentation/pages/dashboard_page.dart';

void main() {
  setUpAll(() {
    sl.init();
  });

  testWidgets('DashboardPage renders mode tabs and execute button', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pumpAndSettle();

    // Verify tab bar
    expect(find.text('Measure'), findsWidgets);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);

    // Verify mode selector segments
    expect(find.text('Room'), findsOneWidget);
    expect(find.text('Wall'), findsOneWidget);
    expect(find.text('Land'), findsOneWidget);
    expect(find.text('Object'), findsOneWidget);
    expect(find.text('Building'), findsOneWidget);

    // Verify execute button exists
    final executeButton = find.byKey(const Key('execute_measurement_button'));
    expect(executeButton, findsOneWidget);

    // Tap execute button — opens room dimension input dialog
    await tester.tap(executeButton);
    await tester.pumpAndSettle();

    // Room dialog should show dimension fields
    expect(find.text('Room Dimensions'), findsOneWidget);
    expect(find.text('Length (m)'), findsOneWidget);
    expect(find.text('Width (m)'), findsOneWidget);
    expect(find.text('Height (m)'), findsOneWidget);

    // Enter valid dimensions (fields are empty — validation requires input)
    final lengthField = find.widgetWithText(TextField, 'Length (m)');
    final widthField = find.widgetWithText(TextField, 'Width (m)');
    final heightField = find.widgetWithText(TextField, 'Height (m)');
    await tester.enterText(lengthField, '5.0');
    await tester.enterText(widthField, '3.5');
    await tester.enterText(heightField, '2.8');

    // Tap Measure button in the dialog
    final dialogMeasureBtn = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Measure'),
    );
    await tester.tap(dialogMeasureBtn);
    await tester.pumpAndSettle();

    // After measurement, export chips should appear
    expect(find.text('DXF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
    expect(find.text('PDF'), findsOneWidget);
    expect(find.text('SVG'), findsOneWidget);
    expect(find.text('JSON'), findsOneWidget);
  });

  testWidgets('DashboardPage validation rejects empty inputs', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pumpAndSettle();

    // Tap execute button — opens room dimension dialog
    final executeButton = find.byKey(const Key('execute_measurement_button'));
    await tester.tap(executeButton);
    await tester.pumpAndSettle();

    // Tap Measure without entering any values
    final dialogMeasureBtn = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Measure'),
    );
    await tester.tap(dialogMeasureBtn);
    await tester.pumpAndSettle();

    // Validation snackbar should appear
    expect(
      find.text('Please enter valid positive dimensions'),
      findsOneWidget,
    );

    // Dialog should still be open
    expect(find.text('Room Dimensions'), findsOneWidget);
  });
}
