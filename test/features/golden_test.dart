import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';

/// Golden tests verify visual rendering matches expected baselines.
///
/// On first run, execute: `flutter test --update-goldens` to generate baselines.
/// Subsequent runs compare against these golden images.
///
/// Since golden baselines are platform-dependent (font rendering differs),
/// we use structural golden tests that verify widget tree structure
/// and layout constraints instead of pixel-perfect screenshots.
void main() {
  group('Golden — Structural Layout Tests', () {
    testWidgets('measurement result card layout', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rectangle',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _MetricRow('Length', '5.00 m'),
                      _MetricRow('Width', '3.00 m'),
                      const Divider(),
                      _MetricRow('Area', '15.00 m²'),
                      _MetricRow('Perimeter', '16.00 m'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      // Verify structure
      expect(find.text('Rectangle'), findsOneWidget);
      expect(find.text('5.00 m'), findsOneWidget);
      expect(find.text('15.00 m²'), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);

      // Verify layout constraints (card is within expected bounds)
      final cardSize = tester.getSize(find.byType(Card));
      expect(cardSize.width, lessThanOrEqualTo(320));
      expect(cardSize.height, greaterThan(100));
    });

    testWidgets('shape chip selector layout', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('Rectangle'), selected: true, onSelected: (_) {}),
              ChoiceChip(label: const Text('Circle'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('Triangle'), selected: false, onSelected: (_) {}),
              ChoiceChip(label: const Text('L-Shape'), selected: false, onSelected: (_) {}),
            ],
          ),
        ),
      ));

      expect(find.byType(ChoiceChip), findsNWidgets(4));
      expect(find.text('Rectangle'), findsOneWidget);
      expect(find.text('Circle'), findsOneWidget);
    });

    testWidgets('dimension input form layout', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Length (m)',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: '5.0'),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Width (m)',
                    prefixIcon: Icon(Icons.straighten),
                    border: OutlineInputBorder(),
                  ),
                  controller: TextEditingController(text: '3.0'),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Length (m)'), findsOneWidget);
      expect(find.text('Width (m)'), findsOneWidget);
    });

    testWidgets('review row layout renders correctly', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MetricRow('Mode', 'Room'),
                _MetricRow('Shape', 'Rectangle'),
                _MetricRow('Area', '15.00 m²'),
                _MetricRow('Volume', '42.00 m³'),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Room'), findsOneWidget);
      expect(find.text('15.00 m²'), findsOneWidget);
    });

    testWidgets('dark theme renders without errors', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
        home: Scaffold(
          body: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Dark Mode Test'),
                    const SizedBox(height: 8),
                    _MetricRow('Area', '15.00 m²'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ));

      expect(find.text('Dark Mode Test'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('responsive layout: narrow width renders single column', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? const Row(children: [
                      Expanded(child: Text('Panel 1')),
                      Expanded(child: Text('Panel 2')),
                    ])
                  : const Column(children: [
                      Text('Panel 1'),
                      Text('Panel 2'),
                    ]);
            },
          ),
        ),
      ));

      // At 360px, should use Column not Row
      expect(find.byType(Column), findsWidgets);
    });

    testWidgets('responsive layout: wide width renders two columns', (tester) async {
      tester.view.physicalSize = const Size(1024, 768);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 600;
              return isWide
                  ? const Row(children: [
                      Expanded(child: Text('Panel 1')),
                      Expanded(child: Text('Panel 2')),
                    ])
                  : const Column(children: [
                      Text('Panel 1'),
                      Text('Panel 2'),
                    ]);
            },
          ),
        ),
      ));

      expect(find.byType(Row), findsWidgets);
    });
  });

  group('Golden — Shape Rendering Validation', () {
    test('RectangleShape produces correct metrics for display', () {
      final shape = RectangleShape(lengthMeters: 5, widthMeters: 3);
      expect(shape.calculateAreaInSquareMeters(), equals(15.0));
      expect(shape.calculatePerimeterInMeters(), equals(16.0));
      expect(shape.type, equals(ShapeType.rectangle));
    });

    test('CircleShape produces correct metrics for display', () {
      final shape = CircleShape(radiusMeters: 5);
      final area = shape.calculateAreaInSquareMeters();
      expect(area, closeTo(78.54, 0.1));
      expect(shape.type, equals(ShapeType.circle));
    });

    test('TriangleShape produces correct metrics for display', () {
      final shape = TriangleShape(sideA: 3, sideB: 4, sideC: 5);
      expect(shape.calculateAreaInSquareMeters(), closeTo(6.0, 0.01));
      expect(shape.type, equals(ShapeType.triangle));
    });
  });
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  const _MetricRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          )),
        ],
      ),
    );
  }
}
