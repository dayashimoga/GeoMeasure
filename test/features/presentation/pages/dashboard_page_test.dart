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
    await tester.pumpWidget(const MaterialApp(home: DashboardPage()));
    await tester.pumpAndSettle();

    expect(find.text('Hardware Capability Matrix'), findsOneWidget);
    expect(find.text('Room'), findsOneWidget);
    expect(find.text('Wall'), findsOneWidget);
    expect(find.text('Plot / Land'), findsOneWidget);

    final executeBtn = find.widgetWithText(
      ElevatedButton,
      'Measure Room Enclosure',
    );
    expect(executeBtn, findsOneWidget);

    await tester.ensureVisible(executeBtn);
    await tester.pumpAndSettle();
    await tester.tap(executeBtn, warnIfMissed: false);
    await tester.pumpAndSettle();

    final exportDxf = find.text('Export DXF');
    expect(exportDxf, findsOneWidget);
    final exportCsv = find.text('Export CSV');
    expect(exportCsv, findsOneWidget);
  });
}
