import 'package:flutter_test/flutter_test.dart';
import 'package:meassure_app/core/di/service_locator.dart';
import 'package:meassure_app/main.dart';

void main() {
  setUp(() {
    sl.init();
  });

  testWidgets('GeoMeasureApp smoke test - renders DashboardPage title', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoMeasureApp());
    await tester.pumpAndSettle();

    expect(find.text('GeoMeasure Spatial Engine'), findsOneWidget);
  });
}
