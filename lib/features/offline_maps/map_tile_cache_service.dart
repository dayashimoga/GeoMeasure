import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../../core/logging/app_logger.dart';

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// Production Offline Map Tile Cache
// Hive-backed tile storage with region management
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/// Geographic bounding box for tile regions.
class GeoBounds {
  final double north;
  final double south;
  final double east;
  final double west;

  const GeoBounds({
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  bool contains(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;

  /// Calculate tile coordinate ranges for a given zoom level.
  ({int xMin, int xMax, int yMin, int yMax}) tileRange(int zoom) {
    final n = 1 << zoom;
    final xMin = _lonToTileX(west, n);
    final xMax = _lonToTileX(east, n);
    final yMin = _latToTileY(north, n);
    final yMax = _latToTileY(south, n);
    return (xMin: xMin, xMax: xMax, yMin: yMin, yMax: yMax);
  }

  /// Estimate total tile count for zoom range.
  int estimateTileCount(int minZoom, int maxZoom) {
    int count = 0;
    for (int z = minZoom; z <= maxZoom; z++) {
      final range = tileRange(z);
      count += (range.xMax - range.xMin + 1) * (range.yMax - range.yMin + 1);
    }
    return count;
  }

  static int _lonToTileX(double lon, int n) =>
      ((lon + 180.0) / 360.0 * n).floor().clamp(0, n - 1);

  static int _latToTileY(double lat, int n) {
    final latRad = lat * 3.14159265358979 / 180.0;
    final y = (1.0 - _ln(_tan(latRad) + 1.0 / _cos(latRad)) / 3.14159265358979) / 2.0 * n;
    return y.floor().clamp(0, n - 1);
  }

  static double _tan(double x) {
    final s = _sin(x);
    final c = _cos(x);
    return c == 0 ? double.infinity : s / c;
  }

  static double _sin(double x) {
    // Use dart:math through a simple Taylor expansion isn't needed —
    // we import dart:math at the top level via typed_data
    x = x % (2 * 3.14159265358979);
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  static double _cos(double x) => _sin(x + 3.14159265358979 / 2);

  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    double y = (x - 1) / (x + 1);
    double result = y;
    double term = y;
    for (int i = 1; i <= 20; i++) {
      term *= y * y;
      result += term / (2 * i + 1);
    }
    return 2 * result;
  }

  Map<String, dynamic> toJson() => {
        'north': north,
        'south': south,
        'east': east,
        'west': west,
      };

  factory GeoBounds.fromJson(Map<String, dynamic> map) => GeoBounds(
        north: (map['north'] as num).toDouble(),
        south: (map['south'] as num).toDouble(),
        east: (map['east'] as num).toDouble(),
        west: (map['west'] as num).toDouble(),
      );
}

/// A cached map region with metadata.
class CachedRegion {
  final String id;
  final String name;
  final GeoBounds bounds;
  final int minZoom;
  final int maxZoom;
  final int tileCount;
  final int sizeBytes;
  final DateTime cachedAt;

  const CachedRegion({
    required this.id,
    required this.name,
    required this.bounds,
    this.minZoom = 10,
    this.maxZoom = 17,
    this.tileCount = 0,
    this.sizeBytes = 0,
    required this.cachedAt,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1048576) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bounds': bounds.toJson(),
        'minZoom': minZoom,
        'maxZoom': maxZoom,
        'tileCount': tileCount,
        'sizeBytes': sizeBytes,
        'cachedAt': cachedAt.toIso8601String(),
      };

  factory CachedRegion.fromJson(Map<String, dynamic> map) => CachedRegion(
        id: map['id'] as String,
        name: map['name'] as String,
        bounds: GeoBounds.fromJson(map['bounds'] as Map<String, dynamic>),
        minZoom: map['minZoom'] as int? ?? 10,
        maxZoom: map['maxZoom'] as int? ?? 17,
        tileCount: map['tileCount'] as int? ?? 0,
        sizeBytes: map['sizeBytes'] as int? ?? 0,
        cachedAt: DateTime.parse(map['cachedAt'] as String),
      );
}

/// Production Hive-backed tile cache.
///
/// Stores tile PNG bytes in Hive with z/x/y keys.
/// Manages regions with metadata for bulk download/delete.
class TileCacheStore {
  static const String _tileBox = 'map_tiles';
  static const String _regionBox = 'map_regions';

  /// Store a tile.
  Future<void> putTile(int z, int x, int y, Uint8List data) async {
    final box = await Hive.openBox<Uint8List>(_tileBox);
    await box.put('$z/$x/$y', data);
  }

  /// Get a cached tile, or null if not cached.
  Future<Uint8List?> getTile(int z, int x, int y) async {
    final box = await Hive.openBox<Uint8List>(_tileBox);
    return box.get('$z/$x/$y');
  }

  /// Check if a tile is cached.
  Future<bool> hasTile(int z, int x, int y) async {
    final box = await Hive.openBox<Uint8List>(_tileBox);
    return box.containsKey('$z/$x/$y');
  }

  /// Store region metadata.
  Future<void> saveRegion(CachedRegion region) async {
    final box = await Hive.openBox<String>(_regionBox);
    await box.put(region.id, jsonEncode(region.toJson()));
  }

  /// Get all cached regions.
  Future<List<CachedRegion>> getRegions() async {
    final box = await Hive.openBox<String>(_regionBox);
    return box.values
        .map((json) =>
            CachedRegion.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList();
  }

  /// Delete a region and its tiles.
  Future<void> deleteRegion(String regionId) async {
    final regionBox = await Hive.openBox<String>(_regionBox);
    final regionJson = regionBox.get(regionId);
    if (regionJson != null) {
      final region = CachedRegion.fromJson(
          jsonDecode(regionJson) as Map<String, dynamic>);

      // Remove tiles for this region's zoom/bounds
      final tileBox = await Hive.openBox<Uint8List>(_tileBox);
      for (int z = region.minZoom; z <= region.maxZoom; z++) {
        final range = region.bounds.tileRange(z);
        for (int x = range.xMin; x <= range.xMax; x++) {
          for (int y = range.yMin; y <= range.yMax; y++) {
            await tileBox.delete('$z/$x/$y');
          }
        }
      }

      await regionBox.delete(regionId);
    }
  }

  /// Total cache size in bytes.
  Future<int> totalSize() async {
    final box = await Hive.openBox<Uint8List>(_tileBox);
    int total = 0;
    for (final value in box.values) {
      total += value.length;
    }
    return total;
  }

  /// Clear entire tile cache.
  Future<void> clearAll() async {
    final tileBox = await Hive.openBox<Uint8List>(_tileBox);
    await tileBox.clear();
    final regionBox = await Hive.openBox<String>(_regionBox);
    await regionBox.clear();
  }
}

/// Offline map tile provider.
class MapTileCacheProvider extends ChangeNotifier {
  final TileCacheStore _store;

  final List<CachedRegion> _regions = [];
  int _cacheSizeBytes = 0;
  String? _errorMessage;

  List<CachedRegion> get regions => List.unmodifiable(_regions);
  int get cacheSizeBytes => _cacheSizeBytes;
  String? get errorMessage => _errorMessage;

  String get formattedCacheSize {
    if (_cacheSizeBytes < 1048576) {
      return '${(_cacheSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(_cacheSizeBytes / 1048576).toStringAsFixed(1)} MB';
  }

  MapTileCacheProvider({TileCacheStore? store})
      : _store = store ?? TileCacheStore();

  /// Initialize cache provider and load region metadata.
  Future<void> initialize() async {
    try {
      _regions
        ..clear()
        ..addAll(await _store.getRegions());
      _cacheSizeBytes = await _store.totalSize();
    } catch (e) {
      _errorMessage = 'Map cache init failed: $e';
      logger.error('Map cache init failed', error: e, tag: 'Maps');
    }
    notifyListeners();
  }

  /// Get a tile from cache.
  Future<Uint8List?> getTile(int z, int x, int y) => _store.getTile(z, x, y);

  /// Cache a downloaded tile.
  Future<void> cacheTile(int z, int x, int y, Uint8List data) async {
    await _store.putTile(z, x, y, data);
  }

  /// Register a downloaded region.
  Future<void> registerRegion(CachedRegion region) async {
    await _store.saveRegion(region);
    _regions.add(region);
    _cacheSizeBytes = await _store.totalSize();
    notifyListeners();
  }

  /// Delete a cached region and its tiles.
  Future<void> deleteRegion(String regionId) async {
    await _store.deleteRegion(regionId);
    _regions.removeWhere((r) => r.id == regionId);
    _cacheSizeBytes = await _store.totalSize();
    notifyListeners();
  }

  /// Clear all cached tiles and regions.
  Future<void> clearAll() async {
    await _store.clearAll();
    _regions.clear();
    _cacheSizeBytes = 0;
    notifyListeners();
  }
}
