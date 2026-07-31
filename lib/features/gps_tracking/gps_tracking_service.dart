import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/logging/app_logger.dart';
import '../measurement_engine/domain/entities/spatial_shape.dart';
import '../measurement_engine/domain/services/geodetic_calculator.dart';

/// Real GPS position with full metadata.
class GpsPosition {
  final double latitude;
  final double longitude;
  final double altitude;
  final double accuracy;
  final double speed;
  final double heading;
  final DateTime timestamp;

  const GpsPosition({
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.accuracy = 0.0,
    this.speed = 0.0,
    this.heading = 0.0,
    required this.timestamp,
  });

  factory GpsPosition.fromGeolocator(Position pos) => GpsPosition(
        latitude: pos.latitude,
        longitude: pos.longitude,
        altitude: pos.altitude,
        accuracy: pos.accuracy,
        speed: pos.speed,
        heading: pos.heading,
        timestamp: pos.timestamp,
      );

  GpsCoordinate toGpsCoordinate() => GpsCoordinate(
        latitude: latitude,
        longitude: longitude,
        altitudeMeters: altitude,
      );

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'speed': speed,
        'heading': heading,
        'timestamp': timestamp.toIso8601String(),
      };

  factory GpsPosition.fromJson(Map<String, dynamic> map) => GpsPosition(
        latitude: (map['latitude'] as num).toDouble(),
        longitude: (map['longitude'] as num).toDouble(),
        altitude: (map['altitude'] as num?)?.toDouble() ?? 0.0,
        accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
        speed: (map['speed'] as num?)?.toDouble() ?? 0.0,
        heading: (map['heading'] as num?)?.toDouble() ?? 0.0,
        timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Production GPS tracking service using the geolocator package.
///
/// Handles real permission requests, location service checks,
/// and continuous position streaming with configurable distance filter.
class GpsTrackingService {
  StreamSubscription<Position>? _positionSub;
  final StreamController<GpsPosition> _controller =
      StreamController<GpsPosition>.broadcast();

  Stream<GpsPosition> get positionStream => _controller.stream;

  /// Check if location permission is granted.
  Future<bool> checkPermission() async {
    final perm = await Geolocator.checkPermission();
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Request location permission from the user.
  Future<bool> requestPermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      logger.warning('Location permission permanently denied', tag: 'GPS');
      return false;
    }
    return perm == LocationPermission.always ||
        perm == LocationPermission.whileInUse;
  }

  /// Check if location services are enabled on the device.
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Get the current position (single shot).
  Future<GpsPosition> getCurrentPosition({
    LocationAccuracy accuracy = LocationAccuracy.high,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        timeLimit: timeout,
      ),
    );
    return GpsPosition.fromGeolocator(pos);
  }

  /// Start continuous position tracking.
  void startTracking({
    double distanceFilter = 2.0,
    LocationAccuracy accuracy = LocationAccuracy.bestForNavigation,
  }) {
    _positionSub?.cancel();

    final settings = LocationSettings(
      accuracy: accuracy,
      distanceFilter: distanceFilter.toInt(),
    );

    _positionSub = Geolocator.getPositionStream(
      locationSettings: settings,
    ).listen(
      (pos) => _controller.add(GpsPosition.fromGeolocator(pos)),
      onError: (error) {
        logger.error('GPS stream error', error: error, tag: 'GPS');
        _controller.addError(error);
      },
    );

    logger.info(
      'GPS tracking started (filter: ${distanceFilter}m, accuracy: ${accuracy.name})',
      tag: 'GPS',
    );
  }

  /// Stop position tracking.
  void stopTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    logger.info('GPS tracking stopped', tag: 'GPS');
  }

  /// Open device location settings (useful when services are disabled).
  Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (useful when permission is permanently denied).
  Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  void dispose() {
    _positionSub?.cancel();
    _controller.close();
  }
}

/// GPS tracking state provider — manages waypoints, distance, and PlotShape conversion.
class GpsTrackingProvider extends ChangeNotifier {
  final GpsTrackingService _service;

  final List<GpsPosition> _waypoints = [];
  GpsPosition? _currentPosition;
  bool _isTracking = false;
  bool _hasPermission = false;
  bool _serviceEnabled = false;
  String? _errorMessage;
  StreamSubscription<GpsPosition>? _subscription;

  List<GpsPosition> get waypoints => List.unmodifiable(_waypoints);
  GpsPosition? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;
  bool get serviceEnabled => _serviceEnabled;
  String? get errorMessage => _errorMessage;

  double get totalDistanceMeters {
    if (_waypoints.length < 2) return 0.0;
    double total = 0.0;
    for (int i = 1; i < _waypoints.length; i++) {
      total += GeodeticCalculator.calculateDistanceHaversine(
        _waypoints[i - 1].toGpsCoordinate(),
        _waypoints[i].toGpsCoordinate(),
      );
    }
    return total;
  }

  GpsTrackingProvider({GpsTrackingService? service})
      : _service = service ?? GpsTrackingService();

  /// Initialize GPS — check permissions and get initial position.
  Future<void> initialize() async {
    try {
      _serviceEnabled = await _service.isLocationServiceEnabled();
      if (!_serviceEnabled) {
        _errorMessage =
            'Location services are disabled. Enable GPS in device settings.';
        notifyListeners();
        return;
      }

      _hasPermission = await _service.checkPermission();
      if (!_hasPermission) {
        _hasPermission = await _service.requestPermission();
      }

      if (!_hasPermission) {
        _errorMessage =
            'Location permission denied. Grant access in app settings.';
        notifyListeners();
        return;
      }

      _currentPosition = await _service.getCurrentPosition();
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'GPS initialization failed: $e';
      logger.error('GPS init failed', error: e, tag: 'GPS');
    }
    notifyListeners();
  }

  /// Start continuous GPS tracking and waypoint collection.
  void startTracking({double distanceFilter = 2.0}) {
    if (_isTracking) return;
    _waypoints.clear();
    _isTracking = true;
    _errorMessage = null;

    _service.startTracking(distanceFilter: distanceFilter);
    _subscription = _service.positionStream.listen(
      (position) {
        _currentPosition = position;
        _waypoints.add(position);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'GPS error: $error';
        logger.error('GPS stream error', error: error, tag: 'GPS');
        notifyListeners();
      },
    );

    notifyListeners();
  }

  /// Stop tracking and preserve waypoints.
  void stopTracking() {
    _subscription?.cancel();
    _subscription = null;
    _isTracking = false;
    _service.stopTracking();
    logger.info(
      'Stopped tracking. ${_waypoints.length} waypoints, ${totalDistanceMeters.toStringAsFixed(1)}m',
      tag: 'GPS',
    );
    notifyListeners();
  }

  /// Convert collected waypoints to a PlotShape for area measurement.
  PlotShape? toPlotShape() {
    if (_waypoints.length < 3) return null;
    return PlotShape(
      coordinates: _waypoints.map((w) => w.toGpsCoordinate()).toList(),
    );
  }

  void clearWaypoints() {
    _waypoints.clear();
    notifyListeners();
  }

  /// Open device location settings.
  Future<void> openSettings() async {
    if (!_serviceEnabled) {
      await _service.openLocationSettings();
    } else if (!_hasPermission) {
      await _service.openAppSettings();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _service.dispose();
    super.dispose();
  }
}
