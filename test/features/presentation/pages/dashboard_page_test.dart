import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/core/di/service_locator.dart';
import 'package:geomeasure/features/presentation/pages/dashboard_page.dart';

void main() {
  setUp(() {
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

    // Verify tab bar and mode selector
    expect(find.text('Measure'), findsOneWidget);
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
    expect(find.text('Wall'), findsOneWidget);
    expect(find.text('Land'), findsOneWidget);

    final executeButton = find.byKey(const Key('execute_measurement_button'));
    expect(executeButton, findsOneWidget);

    await tester.tap(executeButton);
    await tester.pumpAndSettle();

    // After measurement, export chips should appear
    expect(find.text('DXF'), findsOneWidget);
    expect(find.text('CSV'), findsOneWidget);
  });
}
