import 'package:flutter/material.dart';
import 'core/di/service_locator.dart';
import 'features/presentation/pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  sl.init();
  runApp(const GeoMeasureApp());
}

class GeoMeasureApp extends StatelessWidget {
  const GeoMeasureApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoMeasure App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const DashboardPage(),
    );
  }
}
