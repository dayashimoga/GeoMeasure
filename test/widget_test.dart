import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/core/di/service_locator.dart';
import 'package:geomeasure/main.dart';

void main() {
  setUp(() {
    sl.init();
  });

  testWidgets('GeoMeasureApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoMeasureApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(find.text('GeoMeasure Spatial Engine'), findsOneWidget);
  });
}
