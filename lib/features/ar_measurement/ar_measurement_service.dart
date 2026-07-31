import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../core/logging/app_logger.dart';
import '../measurement_engine/domain/entities/spatial_shape.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// AR Measurement Service — Production Interface
// Plug in ARCore (Android) or ARKit (iOS) via the ArEngine interface
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

enum ArSessionState {
  uninitialized,
  initializing,
  ready,
  tracking,
  paused,
  error
}

enum ArPlaneType { horizontal, vertical, unknown }

/// A detected surface in AR space.
class ArPlane {
  final String id;
  final ArPlaneType type;
  final double widthMeters;
  final double heightMeters;
  final double confidence;

  const ArPlane({
    required this.id,
    required this.type,
    required this.widthMeters,
    required this.heightMeters,
    this.confidence = 0.0,
  });
}

/// An anchor placed in AR space with 3D coordinates.
class ArAnchor {
  final String id;
  final Point3D position;
  final DateTime placedAt;

  const ArAnchor({
    required this.id,
    required this.position,
    required this.placedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'x': position.x,
        'y': position.y,
        'z': position.z,
        'placedAt': placedAt.toIso8601String(),
      };

  factory ArAnchor.fromJson(Map<String, dynamic> map) => ArAnchor(
        id: map['id'] as String,
        position: Point3D(
          (map['x'] as num).toDouble(),
          (map['y'] as num).toDouble(),
          (map['z'] as num?)?.toDouble() ?? 0,
        ),
        placedAt: DateTime.parse(map['placedAt'] as String),
      );
}

/// A distance measurement between two AR anchors.
class ArMeasurement {
  final ArAnchor start;
  final ArAnchor end;
  final double distanceMeters;
  final DateTime measuredAt;

  const ArMeasurement({
    required this.start,
    required this.end,
    required this.distanceMeters,
    required this.measuredAt,
  });

  Map<String, dynamic> toJson() => {
        'start': start.toJson(),
        'end': end.toJson(),
        'distanceMeters': distanceMeters,
        'measuredAt': measuredAt.toIso8601String(),
      };
}

/// AR engine interface — swap in ARCore/ARKit implementations.
abstract class ArEngine {
  Future<bool> checkAvailability();
  Future<void> startSession();
  Future<void> stopSession();
  Future<ArAnchor?> hitTest(double screenX, double screenY);
  Stream<ArSessionState> get stateStream;
  Stream<List<ArPlane>> get planeStream;
  void dispose();
}

/// Production AR measurement provider.
///
/// Manages AR session, anchor placement, automatic distance calculation,
/// and conversion to measurement engine shapes.
class ArMeasurementProvider extends ChangeNotifier {
  final ArEngine _engine;

  ArSessionState _state = ArSessionState.uninitialized;
  final List<ArAnchor> _anchors = [];
  final List<ArMeasurement> _measurements = [];
  final List<ArPlane> _planes = [];
  String? _errorMessage;
  bool _isSupported = false;
  StreamSubscription<ArSessionState>? _stateSub;
  StreamSubscription<List<ArPlane>>? _planeSub;

  ArSessionState get state => _state;
  List<ArAnchor> get anchors => List.unmodifiable(_anchors);
  List<ArMeasurement> get measurements => List.unmodifiable(_measurements);
  List<ArPlane> get planes => List.unmodifiable(_planes);
  String? get errorMessage => _errorMessage;
  bool get isSupported => _isSupported;
  bool get isReady =>
      _state == ArSessionState.ready || _state == ArSessionState.tracking;

  ArMeasurementProvider({required ArEngine engine}) : _engine = engine;

  Future<void> initialize() async {
    try {
      _isSupported = await _engine.checkAvailability();
      if (!_isSupported) {
        _errorMessage = 'AR not supported on this device';
        notifyListeners();
        return;
      }

      _stateSub = _engine.stateStream.listen((s) {
        _state = s;
        notifyListeners();
      });

      _planeSub = _engine.planeStream.listen((p) {
        _planes
          ..clear()
          ..addAll(p);
        notifyListeners();
      });

      await _engine.startSession();
      logger.info('AR session initialized', tag: 'AR');
    } catch (e) {
      _state = ArSessionState.error;
      _errorMessage = 'AR init failed: $e';
      logger.error('AR init failed', error: e, tag: 'AR');
    }
    notifyListeners();
  }

  /// Place an anchor at screen coordinates via AR hit test.
  Future<void> placeAnchor(double screenX, double screenY) async {
    try {
      final anchor = await _engine.hitTest(screenX, screenY);
      if (anchor == null) {
        _errorMessage = 'No surface detected. Point at a flat surface.';
        notifyListeners();
        return;
      }

      _anchors.add(anchor);
      _errorMessage = null;

      // Auto-measure between consecutive anchors
      if (_anchors.length >= 2) {
        final prev = _anchors[_anchors.length - 2];
        final distance = _euclideanDistance(prev.position, anchor.position);
        _measurements.add(ArMeasurement(
          start: prev,
          end: anchor,
          distanceMeters: distance,
          measuredAt: DateTime.now(),
        ));
      }

      _state = ArSessionState.tracking;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to place anchor: $e';
      notifyListeners();
    }
  }

  /// Remove the last placed anchor (undo).
  void undoLastAnchor() {
    if (_anchors.isEmpty) return;
    _anchors.removeLast();
    if (_measurements.isNotEmpty) {
      _measurements.removeLast();
    }
    notifyListeners();
  }

  /// Convert anchors to an IrregularPolygonShape for area calculation.
  IrregularPolygonShape? toPolygonShape() {
    if (_anchors.length < 3) return null;
    return IrregularPolygonShape(
      vertices: _anchors.map((a) => a.position).toList(),
    );
  }

  /// Total perimeter from all consecutive measurements.
  double get totalPerimeter =>
      _measurements.fold(0.0, (sum, m) => sum + m.distanceMeters);

  /// Estimated area using the Shoelace formula on 2D projection.
  double get estimatedArea {
    if (_anchors.length < 3) return 0.0;
    double area = 0.0;
    final n = _anchors.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += _anchors[i].position.x * _anchors[j].position.y;
      area -= _anchors[j].position.x * _anchors[i].position.y;
    }
    return (area / 2).abs();
  }

  /// Clear all anchors and measurements.
  void clearAll() {
    _anchors.clear();
    _measurements.clear();
    _state = ArSessionState.ready;
    notifyListeners();
  }

  static double _euclideanDistance(Point3D a, Point3D b) {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    final dz = b.z - a.z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    _planeSub?.cancel();
    _engine.dispose();
    super.dispose();
  }
}

/// Manual measurement engine — no AR required.
///
/// Users tap on a 2D canvas to place points. Distances are calculated
/// using a user-provided scale factor (pixels-to-meters).
class ManualArEngine implements ArEngine {
  final _stateCtrl = StreamController<ArSessionState>.broadcast();
  final _planeCtrl = StreamController<List<ArPlane>>.broadcast();
  int _anchorCount = 0;
  double pixelsPerMeter;

  ManualArEngine({this.pixelsPerMeter = 100.0});

  @override
  Stream<ArSessionState> get stateStream => _stateCtrl.stream;

  @override
  Stream<List<ArPlane>> get planeStream => _planeCtrl.stream;

  @override
  Future<bool> checkAvailability() async => true; // Always available

  @override
  Future<void> startSession() async {
    _stateCtrl.add(ArSessionState.ready);
  }

  @override
  Future<void> stopSession() async {
    _stateCtrl.add(ArSessionState.paused);
  }

  @override
  Future<ArAnchor?> hitTest(double screenX, double screenY) async {
    _anchorCount++;
    return ArAnchor(
      id: 'manual-$_anchorCount',
      position: Point3D(screenX / pixelsPerMeter, screenY / pixelsPerMeter),
      placedAt: DateTime.now(),
    );
  }

  /// Update scale factor (e.g., after user calibrates with a known distance).
  void setScale(double pxPerMeter) {
    pixelsPerMeter = pxPerMeter;
  }

  @override
  void dispose() {
    _stateCtrl.close();
    _planeCtrl.close();
  }
}
