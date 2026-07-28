/// Map tile, terrain, and satellite imagery service abstraction.
///
/// Default implementation uses OpenStreetMap (free, no API key required).
/// Supports pluggable providers for Google Maps, Mapbox, etc.

/// Tile provider abstraction for map rendering.
abstract class MapTileProvider {
  /// Provider name for display.
  String get name;

  /// Get tile URL for given coordinates.
  /// z = zoom level, x/y = tile indices.
  String getTileUrl(int z, int x, int y);

  /// Attribution text required by the provider.
  String get attribution;

  /// Maximum zoom level supported.
  int get maxZoom;

  /// Minimum zoom level supported.
  int get minZoom;
}

/// OpenStreetMap tile provider — free, no API key required.
class OsmTileProvider implements MapTileProvider {
  @override
  String get name => 'OpenStreetMap';

  @override
  String getTileUrl(int z, int x, int y) =>
      'https://tile.openstreetmap.org/$z/$x/$y.png';

  @override
  String get attribution =>
      '© OpenStreetMap contributors';

  @override
  int get maxZoom => 19;

  @override
  int get minZoom => 0;
}

/// OpenTopoMap — topographic map tiles, free, no API key.
class OpenTopoMapProvider implements MapTileProvider {
  @override
  String get name => 'OpenTopoMap';

  @override
  String getTileUrl(int z, int x, int y) =>
      'https://tile.opentopomap.org/$z/$x/$y.png';

  @override
  String get attribution =>
      '© OpenTopoMap (CC-BY-SA)';

  @override
  int get maxZoom => 17;

  @override
  int get minZoom => 0;
}

/// Satellite imagery provider abstraction.
class EsriSatelliteProvider implements MapTileProvider {
  @override
  String get name => 'Esri Satellite';

  @override
  String getTileUrl(int z, int x, int y) =>
      'https://server.arcgisonline.com/ArcGIS/rest/services/'
      'World_Imagery/MapServer/tile/$z/$y/$x';

  @override
  String get attribution =>
      '© Esri, Maxar, Earthstar Geographics';

  @override
  int get maxZoom => 18;

  @override
  int get minZoom => 0;
}

/// Terrain elevation tile provider (Stamen, free).
class StamenTerrainProvider implements MapTileProvider {
  @override
  String get name => 'Stamen Terrain';

  @override
  String getTileUrl(int z, int x, int y) =>
      'https://tiles.stadiamaps.com/tiles/stamen_terrain/$z/$x/$y.png';

  @override
  String get attribution =>
      '© Stadia Maps, © Stamen Design, © OpenMapTiles, © OpenStreetMap';

  @override
  int get maxZoom => 18;

  @override
  int get minZoom => 0;
}

/// Map service that manages tile providers and coordinates.
class MapService {
  MapTileProvider _provider;

  static final List<MapTileProvider> availableProviders = [
    OsmTileProvider(),
    OpenTopoMapProvider(),
    EsriSatelliteProvider(),
    StamenTerrainProvider(),
  ];

  MapService({MapTileProvider? provider})
      : _provider = provider ?? OsmTileProvider();

  MapTileProvider get provider => _provider;

  void switchProvider(MapTileProvider newProvider) {
    _provider = newProvider;
  }

  /// Get tile URL for a GPS coordinate at given zoom.
  String getTileForCoordinate(double lat, double lon, int zoom) {
    final x = _lonToTileX(lon, zoom);
    final y = _latToTileY(lat, zoom);
    return _provider.getTileUrl(zoom, x, y);
  }

  /// Convert longitude to tile X index.
  static int _lonToTileX(double lon, int zoom) {
    return ((lon + 180.0) / 360.0 * (1 << zoom)).floor();
  }

  /// Convert latitude to tile Y index.
  static int _latToTileY(double lat, int zoom) {
    final latRad = lat * 3.14159265358979 / 180.0;
    final n = 1 << zoom;
    return ((1.0 - _ln(_tan(latRad) + 1.0 / _cos(latRad)) /
                3.14159265358979) / 2.0 * n)
        .floor();
  }

  /// Convert tile indices back to lat/lon (for bounding box).
  static double tileXToLon(int x, int zoom) {
    return x / (1 << zoom) * 360.0 - 180.0;
  }

  static double tileYToLat(int y, int zoom) {
    final n = 3.14159265358979 - 2.0 * 3.14159265358979 * y / (1 << zoom);
    return 180.0 / 3.14159265358979 * _atan(_sinh(n));
  }

  /// Meters per pixel at given latitude and zoom.
  static double metersPerPixel(double lat, int zoom) {
    return 156543.03392 * _cos(lat * 3.14159265358979 / 180.0) / (1 << zoom);
  }

  // Inline math helpers
  static double _tan(double x) {
    final s = _sinApprox(x);
    final c = _cosApprox(x);
    return c != 0 ? s / c : double.infinity;
  }

  static double _cos(double x) => _cosApprox(x);

  static double _ln(double x) {
    if (x <= 0) return double.negativeInfinity;
    // Newton's method: ln(x) via convergent series
    double result = 0;
    double term = (x - 1) / (x + 1);
    double power = term;
    for (int i = 1; i < 30; i += 2) {
      result += power / i;
      power *= term * term;
    }
    return 2 * result;
  }

  static double _atan(double x) {
    // Approximate atan using polynomial
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * (3.14159265358979 / 2 - _atan(1 / x.abs()));
    }
    final x2 = x * x;
    return x * (1 - x2 / 3 + x2 * x2 / 5 - x2 * x2 * x2 / 7 +
        x2 * x2 * x2 * x2 / 9);
  }

  static double _sinh(double x) {
    final ex = _exp(x);
    return (ex - 1 / ex) / 2;
  }

  static double _exp(double x) {
    // Taylor series e^x
    double result = 1;
    double term = 1;
    for (int i = 1; i < 20; i++) {
      term *= x / i;
      result += term;
    }
    return result;
  }

  static double _sinApprox(double x) {
    // Normalize to [-π, π]
    while (x > 3.14159265358979) x -= 2 * 3.14159265358979;
    while (x < -3.14159265358979) x += 2 * 3.14159265358979;
    final x2 = x * x;
    return x * (1 - x2 / 6 + x2 * x2 / 120 - x2 * x2 * x2 / 5040);
  }

  static double _cosApprox(double x) {
    while (x > 3.14159265358979) x -= 2 * 3.14159265358979;
    while (x < -3.14159265358979) x += 2 * 3.14159265358979;
    final x2 = x * x;
    return 1 - x2 / 2 + x2 * x2 / 24 - x2 * x2 * x2 / 720;
  }
}

/// Represents a map layer that can be toggled on/off.
class MapLayer {
  final String name;
  final MapTileProvider provider;
  final double opacity;
  final bool visible;

  const MapLayer({
    required this.name,
    required this.provider,
    this.opacity = 1.0,
    this.visible = true,
  });

  MapLayer copyWith({
    double? opacity,
    bool? visible,
  }) =>
      MapLayer(
        name: name,
        provider: provider,
        opacity: opacity ?? this.opacity,
        visible: visible ?? this.visible,
      );
}

/// Survey point for outdoor GPS-based surveys.
class SurveyPoint {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final String? label;
  final DateTime timestamp;

  const SurveyPoint({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.label,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'altitude': altitude,
        'accuracy': accuracy,
        'label': label,
        'timestamp': timestamp.toIso8601String(),
      };

  factory SurveyPoint.fromJson(Map<String, dynamic> json) => SurveyPoint(
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        altitude: (json['altitude'] as num?)?.toDouble(),
        accuracy: (json['accuracy'] as num?)?.toDouble(),
        label: json['label'] as String?,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}
