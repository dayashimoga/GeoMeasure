import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/capability_detection/domain/entities/capability_profile.dart';
import 'package:geomeasure/features/presentation/widgets/capability_card.dart';

void main() {
  testWidgets('CapabilityCard renders sensor availability', (
    WidgetTester tester,
  ) async {
    final profile = CapabilityProfile.fallbackManual();
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: CapabilityCard(profile: profile))),
    );
    expect(find.text('Hardware Capability Matrix'), findsOneWidget);
    expect(find.text('LiDAR Sensor'), findsOneWidget);
    expect(find.text('Memory: 2048 MB'), findsOneWidget);
    expect(find.text('CPU Cores: 4'), findsOneWidget);
  });
}
