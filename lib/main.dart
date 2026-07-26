import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'features/presentation/pages/dashboard_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline-first persistent storage
  await Hive.initFlutter();

  // Initialize dependency injection
  sl.init();

  // Load projects from persistent storage
  await sl.projectProvider.loadProjects();

  logger.info('GeoMeasure app starting', tag: 'Main');

  runApp(const GeoMeasureApp());
}

class GeoMeasureApp extends StatefulWidget {
  const GeoMeasureApp({super.key});

  @override
  State<GeoMeasureApp> createState() => _GeoMeasureAppState();
}

class _GeoMeasureAppState extends State<GeoMeasureApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoMeasure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: DashboardPage(onToggleTheme: toggleTheme),
    );
  }
}
