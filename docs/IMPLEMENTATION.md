# Implementation Guide

Module-by-module technical documentation. All references are to actual implemented code.

---

## Core Layer (`lib/core/`)

### AppConfig (`core/config/app_config.dart`)

Singleton configuration with 18 feature flags and environment constants.

| Constant | Value |
|----------|-------|
| `maxProjectsPerUser` | 1,000 |
| `maxMeasurementsPerProject` | 10,000 |
| `maxUndoStackDepth` | 50 |
| `autoSaveInterval` | 30 seconds |
| `minGpsAccuracyMeters` | 3.0 |
| `maxExportFileSizeMb` | 50 |

**Feature flags** (enabled by default): `gps_tracking`, `manual_measurement`, `project_management`, `export_csv`, `export_dxf`, `export_geojson`, `export_svg`, `export_kml`, `dark_mode`, `undo_redo`, `floor_plan_canvas`, `multi_project`.

**Feature flags** (disabled by default): `ar_measurement`, `ai_detection`, `cloud_sync`, `offline_maps`, `pdf_export`, `camera_capture`.

### AppLogger (`core/logging/app_logger.dart`)

Structured logging with tags. Levels: `debug`, `info`, `warning`, `error`. Global instance: `logger`.

### CommandManager (`core/commands/command.dart`)

Undo/redo stack with configurable max depth. Implements the Command pattern for measurement operations.

### SecureStorage (`core/security/secure_storage.dart`)

`HiveSecureStorage` — AES-256 encrypted Hive box with Base64 encoding layer. Interface: `SecureStorageService` with `read`, `write`, `delete`, `deleteAll`, `containsKey`.

### ExportManager (`core/export/export_manager.dart`)

Unified export dispatcher for 9 formats:

| Format | Extension | MIME Type |
|--------|-----------|-----------|
| DXF | `.dxf` | `application/dxf` |
| CSV | `.csv` | `text/csv` |
| GeoJSON | `.geojson` | `application/geo+json` |
| SVG | `.svg` | `image/svg+xml` |
| KML | `.kml` | `application/vnd.google-earth.kml+xml` |
| PDF | `.pdf` | `application/pdf` |
| JSON | `.json` | `application/json` |
| Excel | `.xlsx` | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |

### JsonExporter (`core/export/json_exporter.dart`)

Pure Dart JSON serialisation for `MeasurementResult`, `QuantityTakeoff`, `CostEstimate`, and measurement history.

---

## Measurement Engine (`lib/features/measurement_engine/`)

### Spatial Shapes (`domain/entities/spatial_shape.dart`)

25 shape types with full geometry:

| Category | Shapes |
|----------|--------|
| **Rooms** | RectangularRoom, LShapeRoom, TShapeRoom, UShapeRoom |
| **3D Primitives** | CuboidShape, CylinderShape, SphereShape, ConeShape, FrustumShape |
| **Structures** | ArchShape, GableRoofShape, HipRoofShape |
| **Infrastructure** | PipeShape, PoolShape, ExcavationShape |
| **Land** | PlotShape (GPS polygon, Vincenty/Haversine geodetics) |
| **Basic** | RectangleShape, CircleShape, TriangleShape, TrapezoidShape, EllipseShape, PolygonShape |

Each shape implements:
- `calculateAreaInSquareMeters()` — surface area
- `calculatePerimeterInMeters()` — boundary perimeter
- `calculateVolumeInCubicMeters()` — volume (3D shapes)
- `validate()` — dimension validation with error messages
- `toJson()` / `fromJson()` — serialisation

### Algorithm Selection (`domain/services/algorithm_selector.dart`)

Priority hierarchy based on `CapabilityProfile`:

1. **LiDAR** — <1 cm accuracy
2. **Depth Sensor (ToF)** — <5 cm accuracy
3. **ARCore/ARKit** — Visual-Inertial Odometry
4. **Visual SLAM** — Monocular camera + AI
5. **GPS + IMU** — Geodetic outdoor measurement
6. **Manual** — User-entered dimensions

### Geodetic Calculator (`domain/services/geodetic_calculator.dart`)

- **Vincenty formula** — high-precision ellipsoidal distance (WGS-84)
- **Haversine formula** — spherical distance approximation
- **Shoelace formula** — polygon area from GPS coordinates

### Unit Converter (`domain/services/unit_converter.dart`)

**Distance**: meters, feet, inches, centimetres, millimetres, yards, kilometres, miles.
**Area**: m², ft², acres, hectares, cents, guntha.

### Sensor Fusion (`domain/services/sensor_fusion.dart`)

Weighted multi-sensor fusion engine:

| Sensor Type | Weight |
|-------------|--------|
| RTK GPS | 10.0 |
| LiDAR | 9.0 |
| ARCore | 7.0 |
| GPS | 5.0 |
| IMU | 3.0 |
| UWB | 6.0 |
| Camera | 4.0 |
| Barometer | 2.0 |
| Magnetometer | 1.0 |

Features: circular heading averaging, confidence scoring (diversity 40% + volume 30% + recency 30%), fused accuracy = `bestAccuracy / √(sensorCount)`.

### Exporters

Individual format exporters in `domain/services/`:
- `dxf_exporter.dart` — AutoCAD DXF
- `csv_exporter.dart` — CSV schedule
- `geojson_exporter.dart` — RFC 7946 GeoJSON
- `svg_exporter.dart` — SVG vector drawing
- `kml_exporter.dart` — Google Earth KML

---

## AI Vision (`lib/features/ai_vision/`)

### Edge Detector (`domain/services/edge_detector.dart`)

Pure Dart implementations:
- **Sobel** edge detection (3×3 gradient kernels)
- **Harris** corner detection (structure tensor, eigenvalue scoring)
- **Line detection** (connected-component run-length analysis)
- **RGBA → grayscale** conversion

### Object Counter (`domain/services/object_counter.dart`)

- 50+ `ObjectCategory` enum values
- Non-Maximum Suppression (NMS) deduplication via IoU threshold
- Confidence filtering, density estimation, multi-frame averaging

### Photogrammetry (`domain/services/photogrammetry.dart`)

Pure Dart 3D reconstruction pipeline:
- **FAST corner detector** — 16-point Bresenham circle, 9-contiguous threshold
- **NCC patch matching** — normalised cross-correlation
- **DLT triangulation** — mid-point from two calibrated views
- **Scale calibration** — from known reference distance
- **Surface area estimation** — convex hull with Shoelace formula

### Vision Service (`data/services/vision_service.dart`)

`VisionService` abstract interface with two implementations:
- `LocalVisionService` — pure Dart analysis (all platforms)
- `MlKitVisionService` — Google ML Kit integration scaffold (Android/iOS)

`VisionServiceFactory.create()` returns the appropriate implementation.

### Building Analysis (`domain/entities/building_analysis.dart`)

`BuildingAnalysis` entity with 20+ metrics: FAR, ground coverage, open area ratio, floor area, roof type (8 types), window/door counts. `BuildingAnalyzer` factory from detected objects.

### Measurement Validation (`domain/entities/measurement_validation.dart`)

5 quality grades: `surveyGrade`, `highAccuracy`, `standard`, `rough`, `estimate`. Includes `CalibrationStatus` and `EnvironmentalConditions`.

---

## Estimation (`lib/features/estimation/`)

### Material Estimator (`domain/entities/material_estimate.dart`)

- 15 `MaterialType` values: cement, sand, aggregate, bricks, steel, concrete, paint, tiles, plaster, wood, glass, insulation, roofing, waterproofing, electrical
- `MaterialEstimate` — quantity, unit, unit cost
- `QuantityTakeoff` — project-level bill of quantities
- `CostEstimate` — materials + labour + overhead + contingency
- `MaterialEstimator` — calculates estimates from shape measurements

---

## Export (`lib/features/export/`)

### PDF Exporter (`pdf_exporter.dart`)

Standard PDF report with measurement summary, detailed results table, and project metadata. Uses the `pdf` package.

### PDF Report Generator (`pdf_report_generator.dart`)

5 professional report templates:

| Template | Use Case |
|----------|----------|
| Construction | Site info, BOQ, cost estimate, signature blocks |
| Inspection | Findings, recommendations, building analysis |
| Property | Valuation, zoning, FAR, room-by-room |
| Inventory | Object counts with measurements |
| Material Estimate | BOQ + cost breakdown with approvals |

### Excel Exporter (`excel_exporter.dart`)

Pure Dart XLSX generator — no external packages. Builds valid Open XML ZIP archives with:
- Shared strings table
- Bold header styles
- Numeric cell detection
- CRC-32 checksums

Three export methods: `exportMeasurements()`, `exportTakeoff()`, `exportCostEstimate()`.

---

## Platform Services

| Service | File | Implementation |
|---------|------|---------------|
| Auth | `features/auth/auth_service.dart` | Firebase auth with email/password, guest mode, session persistence |
| Camera | `features/camera/camera_service.dart` | `image_picker` integration |
| GPS | `features/gps_tracking/gps_tracking_service.dart` | `geolocator` real-time positioning |
| AR | `features/ar_measurement/ar_measurement_service.dart` | ARCore/ARKit interface (requires native binding) |
| Cloud Sync | `features/cloud_sync/cloud_sync_service.dart` | Remote sync interface |
| Offline Maps | `features/offline_maps/map_tile_cache_service.dart` | Tile caching service |

---

## Presentation (`lib/features/presentation/`)

### Pages

- **DashboardPage** — Main screen with measurement mode tabs (Room, Land, Structure, Manual), shape selection, dimension inputs, execution, results display, unit toggles, export actions
- **MeasurementHistoryPage** — Chronological measurement list with search, delete, re-export
- **GpsTrackingPage** — Real-time GPS coordinate display and tracking

### Widgets

- **CapabilityCard** — Sensor availability status display
- **MeasurementDisplay** — Formatted measurement result with algorithm and accuracy info
- **FloorPlanCanvas** — Interactive 2D floor plan rendering (`features/visualization/`)
