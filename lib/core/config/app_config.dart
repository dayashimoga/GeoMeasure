/// Application-wide configuration and feature flags.
///
/// All feature toggles are runtime-configurable. In production,
/// these could be driven by remote config (Firebase, LaunchDarkly, etc.).
class AppConfig {
  static final AppConfig _instance = AppConfig._();
  factory AppConfig() => _instance;
  AppConfig._();

  final Map<String, bool> _featureFlags = {
    // ── Measurement modes ──
    'manual_measurement': true,
    'gps_tracking': true,
    'ar_measurement': false, // Requires native ARCore/ARKit binding
    'ai_detection': true,

    // ── Platform services ──
    'camera_capture': true,
    'cloud_sync': false, // Requires backend API
    'offline_maps': false, // Requires tile server

    // ── Export formats ──
    'export_csv': true,
    'export_dxf': true,
    'export_geojson': true,
    'export_svg': true,
    'export_kml': true,
    'export_pdf': true,
    'export_json': true,
    'export_excel': true,

    // ── UI & features ──
    'dark_mode': true,
    'undo_redo': true,
    'floor_plan_canvas': true,
    'multi_project': true,
    'project_management': true,
    'material_estimation': true,
    'sensor_fusion': true,
    'photogrammetry': true,
    'pdf_report_templates': true,
  };

  bool isEnabled(String feature) => _featureFlags[feature] ?? false;

  void setFeatureFlag(String feature, bool enabled) {
    _featureFlags[feature] = enabled;
  }

  Map<String, bool> get allFlags => Map.unmodifiable(_featureFlags);

  /// Environment configuration
  static const String appName = 'GeoMeasure';
  static const String appVersion = '2.3.0';
  static const int buildNumber = 9;
  static const int maxProjectsPerUser = 1000;
  static const int maxMeasurementsPerProject = 10000;
  static const int maxUndoStackDepth = 50;
  static const Duration autoSaveInterval = Duration(seconds: 30);
  static const double minGpsAccuracyMeters = 3.0;
  static const int maxExportFileSizeMb = 50;
}
