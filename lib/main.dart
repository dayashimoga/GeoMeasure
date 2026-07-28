import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/di/service_locator.dart';
import 'core/theme/app_theme.dart';
import 'core/logging/app_logger.dart';
import 'features/presentation/pages/dashboard_page.dart';
import 'features/presentation/pages/onboarding_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline-first persistent storage
  await Hive.initFlutter();

  // Initialize dependency injection
  sl.init();

  // Load projects from persistent storage
  await sl.projectProvider.loadProjects();

  // Check if onboarding has been completed
  final settingsBox = await Hive.openBox('app_settings');
  final onboardingComplete =
      settingsBox.get('onboarding_complete', defaultValue: false) as bool;

  logger.info('GeoMeasure app starting', tag: 'Main');

  runApp(GeoMeasureApp(showOnboarding: !onboardingComplete));
}

class GeoMeasureApp extends StatefulWidget {
  final bool showOnboarding;

  const GeoMeasureApp({super.key, this.showOnboarding = false});

  @override
  State<GeoMeasureApp> createState() => _GeoMeasureAppState();
}

class _GeoMeasureAppState extends State<GeoMeasureApp> {
  ThemeMode _themeMode = ThemeMode.system;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
          _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    });
  }

  void _completeOnboarding() async {
    final settingsBox = Hive.box('app_settings');
    await settingsBox.put('onboarding_complete', true);
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GeoMeasure',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _showOnboarding
          ? OnboardingPage(onComplete: _completeOnboarding)
          : DashboardPage(onToggleTheme: toggleTheme),
    );
  }
}
