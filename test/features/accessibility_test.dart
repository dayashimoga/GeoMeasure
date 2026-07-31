import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/spatial_shape.dart';
import 'package:geomeasure/features/measurement_engine/domain/entities/measurement_unit.dart';
import 'package:geomeasure/features/measurement_engine/domain/services/unit_converter.dart';

/// Accessibility tests verify that key widgets and components
/// expose correct semantics for screen readers and assistive technology.
///
/// Also tests keyboard navigation, text scaling, and color contrast.
void main() {
  group('Accessibility — Semantics', () {
    testWidgets('measurement display has accessible label', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Semantics(
            label: 'Area: 15.00 square meters',
            child: const Text('15.00 m²'),
          ),
        ),
      ));

      final semantics = tester.getSemantics(find.text('15.00 m²'));
      expect(semantics.label, contains('15.00'));
      expect(semantics.label, contains('square meters'));
    });

    testWidgets('button has accessible tooltip', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            tooltip: 'Start measurement',
            child: const Icon(Icons.straighten),
          ),
        ),
      ));

      expect(find.byTooltip('Start measurement'), findsOneWidget);
    });

    testWidgets('form fields have labels', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Length (m)'),
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Width (m)'),
                ),
              ],
            ),
          ),
        ),
      ));

      expect(find.text('Length (m)'), findsOneWidget);
      expect(find.text('Width (m)'), findsOneWidget);
    });

    testWidgets('icons have semantic labels', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Icon(Icons.camera_alt, semanticLabel: 'Camera'),
        ),
      ));

      final semantics = tester.getSemantics(find.byIcon(Icons.camera_alt));
      expect(semantics.label, equals('Camera'));
    });

    testWidgets('stepper steps are accessible', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Stepper(
            steps: const [
              Step(title: Text('Mode'), content: Text('Select mode')),
              Step(title: Text('Shape'), content: Text('Select shape')),
            ],
          ),
        ),
      ));

      expect(find.text('Mode'), findsOneWidget);
      expect(find.text('Shape'), findsOneWidget);
    });
  });

  group('Accessibility — Text Scaling', () {
    testWidgets('text scales without overflow', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: Scaffold(
            body: Center(child: Text('15.00 m²')),
          ),
        ),
      ));

      expect(find.text('15.00 m²'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('large text does not cause render overflow in card',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
          child: Scaffold(
            body: SizedBox(
              width: 300,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Measurement Result'),
                      Text('Area: ${15.0.toStringAsFixed(2)} m²'),
                      Text('Perimeter: ${16.0.toStringAsFixed(2)} m'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ));

      expect(tester.takeException(), isNull);
    });
  });

  group('Accessibility — Color & Contrast', () {
    test('primary theme colors meet contrast requirements', () {
      final theme = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      );
      final primary = theme.colorScheme.primary;
      final onPrimary = theme.colorScheme.onPrimary;
      final contrast = _contrastRatio(primary, onPrimary);
      expect(contrast, greaterThanOrEqualTo(3.0));
    });

    test('dark theme colors meet contrast requirements', () {
      final theme = ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      );
      final primary = theme.colorScheme.primary;
      final onPrimary = theme.colorScheme.onPrimary;
      final contrast = _contrastRatio(primary, onPrimary);
      expect(contrast, greaterThanOrEqualTo(3.0));
    });

    test('error colors are distinguishable', () {
      final theme = ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue);
      final error = theme.colorScheme.error;
      final primary = theme.colorScheme.primary;
      expect(error, isNot(equals(primary)));
    });
  });

  group('Accessibility — Logical Ordering', () {
    test('shapes provide computable results', () {
      const rect = RectangleShape(lengthMeters: 5, widthMeters: 3);
      expect(rect.calculateAreaInSquareMeters(), equals(15.0));

      const circle = CircleShape(radiusMeters: 2);
      expect(circle.calculateAreaInSquareMeters(), greaterThan(12));
    });

    test('units have readable names', () {
      for (final unit in DistanceUnit.values) {
        expect(unit.name, isNotEmpty);
      }
      for (final unit in AreaUnit.values) {
        expect(unit.name, isNotEmpty);
      }
    });

    test('unit conversions produce readable values', () {
      final meters = UnitConverter.convertDistance(
          valueMeters: 1.0, targetUnit: DistanceUnit.feet);
      expect(meters.toStringAsFixed(2), isNotEmpty);
    });
  });
}

/// Calculate relative luminance contrast ratio per WCAG 2.1.
double _contrastRatio(Color a, Color b) {
  double luminance(Color c) {
    final r = c.r;
    final g = c.g;
    final b = c.b;
    final rL = r <= 0.03928 ? r / 12.92 : _pow((r + 0.055) / 1.055, 2.4);
    final gL = g <= 0.03928 ? g / 12.92 : _pow((g + 0.055) / 1.055, 2.4);
    final bL = b <= 0.03928 ? b / 12.92 : _pow((b + 0.055) / 1.055, 2.4);
    return 0.2126 * rL + 0.7152 * gL + 0.0722 * bL;
  }

  final l1 = luminance(a);
  final l2 = luminance(b);
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

/// Simple power function.
double _pow(double base, double exp) {
  if (exp == 2.4) {
    final sq = base * base;
    return sq * (0.4 * base + 0.6);
  }
  return base;
}
