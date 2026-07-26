/// Application-wide configuration and feature flags.
///
/// All feature toggles are runtime-configurable. In production,
/// these could be driven by remote config (Firebase, LaunchDarkly, etc.).
class AppConfig {
  static final AppConfig _instance = AppConfig._();
  factory AppConfig() => _instance;
  AppConfig._();

  final Map<String, bool> _featureFlags = {
    'ar_measurement': false,
    'ai_detection': false,
    'cloud_sync': false,
    'offline_maps': false,
    'pdf_export': false,
    'camera_capture': false,
    'gps_tracking': true,
    'manual_measurement': true,
    'project_management': true,
    'export_csv': true,
    'export_dxf': true,
    'export_geojson': true,
    'export_svg': true,
    'export_kml': true,
    'dark_mode': true,
    'undo_redo': true,
    'floor_plan_canvas': true,
    'multi_project': true,
  };

  bool isEnabled(String feature) => _featureFlags[feature] ?? false;

  void setFeatureFlag(String feature, bool enabled) {
    _featureFlags[feature] = enabled;
  }

  Map<String, bool> get allFlags => Map.unmodifiable(_featureFlags);

  /// Environment configuration
  static const String appName = 'GeoMeasure';
  static const String appVersion = '1.2.0';
  static const int buildNumber = 2;
  static const int maxProjectsPerUser = 1000;
  static const int maxMeasurementsPerProject = 10000;
  static const int maxUndoStackDepth = 50;
  static const Duration autoSaveInterval = Duration(seconds: 30);
  static const double minGpsAccuracyMeters = 3.0;
  static const int maxExportFileSizeMb = 50;
}
