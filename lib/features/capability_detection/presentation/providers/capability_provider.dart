import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geomeasure/core/usecases/usecase.dart';
import '../../domain/entities/capability_profile.dart';
import '../../domain/entities/sensor_type.dart';
import '../../domain/usecases/detect_capabilities_usecase.dart';

/// Capability provider with in-memory caching and background refresh.
class CapabilityProvider extends ChangeNotifier {
  final DetectCapabilitiesUseCase detectCapabilitiesUseCase;

  CapabilityProfile _profile = CapabilityProfile.fallbackManual();
  bool _isLoading = false;
  DateTime? _lastDetectedAt;
  static String? _cachedJson;

  CapabilityProfile get profile => _profile;
  bool get isLoading => _isLoading;
  DateTime? get lastDetectedAt => _lastDetectedAt;

  CapabilityProvider({required this.detectCapabilitiesUseCase});

  /// Load capabilities with cache-first strategy.
  Future<void> loadCapabilities() async {
    _isLoading = true;
    notifyListeners();

    // Try cache first for instant UI
    if (_cachedJson != null) {
      try {
        final map = jsonDecode(_cachedJson!) as Map<String, dynamic>;
        _profile = _profileFromMap(map);
        _isLoading = false;
        notifyListeners();
        // Refresh in background
        _refreshFromHardware();
        return;
      } catch (_) {
        // Cache corrupt, fall through to hardware
      }
    }

    // No cache — detect from hardware
    _profile = await detectCapabilitiesUseCase(const NoParams());
    _isLoading = false;
    _lastDetectedAt = DateTime.now();
    _cachedJson = jsonEncode(_profile.toJson());
    notifyListeners();
  }

  /// Force refresh from hardware, bypassing cache.
  Future<void> forceRefresh() async {
    _isLoading = true;
    notifyListeners();

    _profile = await detectCapabilitiesUseCase(const NoParams());
    _isLoading = false;
    _lastDetectedAt = DateTime.now();
    _cachedJson = jsonEncode(_profile.toJson());
    notifyListeners();
  }

  Future<void> _refreshFromHardware() async {
    try {
      final fresh = await detectCapabilitiesUseCase(const NoParams());
      final freshJson = jsonEncode(fresh.toJson());
      if (freshJson != _cachedJson) {
        _profile = fresh;
        _lastDetectedAt = DateTime.now();
        _cachedJson = freshJson;
        notifyListeners();
      }
    } catch (_) {
      // Cache is valid, ignore hardware errors silently
    }
  }

  CapabilityProfile _profileFromMap(Map<String, dynamic> map) {
    return CapabilityProfile(
      hasLidar: map['hasLidar'] as bool? ?? false,
      hasDepthSensor: map['hasDepthSensor'] as bool? ?? false,
      hasArCore: map['hasArCore'] as bool? ?? false,
      hasArKit: map['hasArKit'] as bool? ?? false,
      hasCamera: map['hasCamera'] as bool? ?? false,
      hasGps: map['hasGps'] as bool? ?? false,
      hasCompass: map['hasCompass'] as bool? ?? false,
      hasGyroscope: map['hasGyroscope'] as bool? ?? false,
      hasAccelerometer: map['hasAccelerometer'] as bool? ?? false,
      hasBarometer: map['hasBarometer'] as bool? ?? false,
      hasBluetooth: map['hasBluetooth'] as bool? ?? false,
      hasNfc: map['hasNfc'] as bool? ?? false,
      hasUwb: map['hasUwb'] as bool? ?? false,
      hasFlash: map['hasFlash'] as bool? ?? false,
      hasMicrophone: map['hasMicrophone'] as bool? ?? false,
      hasGpu: map['hasGpu'] as bool? ?? false,
      hasAiAccelerator: map['hasAiAccelerator'] as bool? ?? false,
      cameraCalibrated: map['cameraCalibrated'] as bool? ?? false,
      ramMb: (map['ramMb'] as num?)?.toInt() ?? 2048,
      cpuCores: (map['cpuCores'] as num?)?.toInt() ?? 4,
      storageAvailableMb: (map['storageAvailableMb'] as num?)?.toInt() ?? 1024,
      displayResolution: map['displayResolution'] as String? ?? '720x1280',
      osVersion: map['osVersion'] as String? ?? 'unknown',
      batteryLevel: (map['batteryLevel'] as num?)?.toDouble() ?? 1.0,
      thermalState: ThermalState.values.firstWhere(
        (t) => t.name == (map['thermalState'] as String? ?? 'nominal'),
        orElse: () => ThermalState.nominal,
      ),
      sensorAccuracy: HardwareAccuracy.values.firstWhere(
        (a) => a.name == (map['sensorAccuracy'] as String? ?? 'low'),
        orElse: () => HardwareAccuracy.low,
      ),
      networkType: NetworkType.values.firstWhere(
        (n) => n.name == (map['networkType'] as String? ?? 'none'),
        orElse: () => NetworkType.none,
      ),
      permissionsGranted: map['permissionsGranted'] as bool? ?? true,
    );
  }
}
