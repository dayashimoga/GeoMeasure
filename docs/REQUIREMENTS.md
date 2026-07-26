# Requirements

## Functional Requirements

| ID | Requirement | Status |
|----|------------|--------|
| FR-01 | Probe all device sensors (LiDAR, ToF, AR, GPS, gyro, accelerometer, magnetometer, barometer) | ✅ Implemented |
| FR-02 | Dynamically select measurement algorithm based on device capabilities | ✅ Implemented |
| FR-03 | Support 25 spatial shape types (rooms, 3D primitives, structures, land) | ✅ Implemented |
| FR-04 | Convert between metric, imperial, and land units | ✅ Implemented |
| FR-05 | Geodetic calculations (Vincenty, Haversine, Shoelace) for GPS polygons | ✅ Implemented |
| FR-06 | Export in 9 formats (DXF, CSV, GeoJSON, SVG, KML, PDF, JSON, Excel) | ✅ Implemented |
| FR-07 | Material estimation and cost calculation | ✅ Implemented |
| FR-08 | Object detection and counting | ✅ Implemented (pure Dart) |
| FR-09 | Building analysis (FAR, coverage, floors) | ✅ Implemented |
| FR-10 | Multi-sensor fusion for improved accuracy | ✅ Implemented |
| FR-11 | Photogrammetry from overlapping images | ✅ Implemented (pure Dart) |
| FR-12 | AR-based measurement | ⚠️ Interface only |
| FR-13 | Cloud sync of measurements | ⚠️ Interface only |
| FR-14 | ML Kit object detection | ⚠️ Scaffold only |

## Non-Functional Requirements

| ID | Requirement | Status |
|----|------------|--------|
| NFR-01 | Cold startup under 2.0 seconds | ✅ ~0.8s baseline |
| NFR-02 | Zero failure — always falls back to manual | ✅ Implemented |
| NFR-03 | Offline-first — no network required for measurement | ✅ Implemented |
| NFR-04 | Cross-platform (Android, iOS, Web) | ✅ Android + Web verified |
| NFR-05 | Encrypted local storage | ✅ AES-256 Hive |
| NFR-06 | Undo/redo support | ✅ CommandManager |

## Performance Requirements

| Requirement | Target | Status |
|------------|--------|--------|
| Cold startup | <2.0s | ✅ |
| Heap memory | <120 MB | ✅ |
| Build APK | <60s | ✅ |
| Test suite | <10s | ✅ ~5s |

## Platform Requirements

| Platform | Minimum |
|----------|---------|
| Android | API 24 (Android 7.0) |
| iOS | iOS 12+ |
| Web | ES6-capable browser |
| Dart SDK | ≥3.0.0 <4.0.0 |
