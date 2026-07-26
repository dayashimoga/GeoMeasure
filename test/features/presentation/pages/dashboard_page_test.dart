import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/core/di/service_locator.dart';
import 'package:meassure_app/features/presentation/pages/dashboard_page.dart';

void main() {
  setUp(() {
    sl.init();
  });

  testWidgets('DashboardPage renders segmented buttons and handles measurement execution', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Hardware Capability Matrix'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
    expect(find.text('Wall'), findsOneWidget);
    expect(find.text('Plot / Land'), findsOneWidget);

    // Tap execute measurement button
    final executeBtn = find.widgetWithText(ElevatedButton, 'Measure Room Enclosure');
    expect(executeBtn, findsOneWidget);
    await tester.tap(executeBtn);
    await tester.pumpAndSettle();

    // Verify measurement card appears with export buttons
    expect(find.text('Export DXF'), findsOneWidget);
    expect(find.text('Export GeoJSON'), findsOneWidget);
    expect(find.text('Export CSV'), findsOneWidget);
  });
}
