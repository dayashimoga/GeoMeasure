# Changelog

All notable changes to GeoMeasure are documented in this file. Format follows [Keep a Changelog](https://keepachangelog.com/).

## [2.8.0] - 2026-07-28

### Added
- **Complete Test Suite Overhaul** — 407/407 tests passing (+168 tests): sensor simulation (13), GPS tracking simulation (12), camera mock (21), accessibility & WCAG contrast (15), structural layout & golden tests (13), outdoor map services (25).
- **MapService & Free Tile Providers** — 4 free map tile providers (OpenStreetMap, OpenTopoMap, Esri Satellite, Stamen Terrain) requiring zero API keys or external paid subscriptions.
- **Zero Analysis Issues** — 173 linter issues resolved, 0 errors, 0 warnings across the entire repository.
- **Documentation Consolidation** — Added `TODO.md`, `TASKS.md`, `CI_CD.md` to `/docs` completing the 23-file specification.

## [2.5.0] - 2026-07-28

### Added
- **PolygonEditor** — vertex add/delete/move, edge split, rotate, scale, snap-to-grid, undo/redo history
- **ProjectVersionHistory** — snapshot recording, version diff comparison, JSON serialization
- **BackupService** — full Hive JSON backup/restore with versioning
- **Settings tab** — Create Backup, Restore, Hardware Diagnostics bottom sheet
- **Dashboard confidence badge** — shows engine confidence % instead of sensor count
- 56 new tests (294 total) covering polygon editing, version history, failure/edge cases

## [2.4.0] - 2026-07-28

### Added
- **Onboarding flow** — 4-slide first-launch walkthrough (Detect → Measure → Camera → Export) with Hive persistence
- **Engine confidence scoring** — per-algorithm confidence percentages (50-98%) based on hardware sensors, RAM, calibration
- **Slope & elevation calculations** — `calculateSlopeDegrees`, `calculateSlopePercent`, `calculateElevationDifference`, `calculateElevationGain`, `calculateBearing`
- **Report templates** — `InspectionReport` (16-item building checklist), `PropertyReport`, `InventoryReport` with category aggregation
- **PNG/JPEG image export** — `ImageExporter` captures floor plan canvas via `RenderRepaintBoundary`
- **Interactive floor plan editing** — drag vertices with snap-to-grid (0.1m), selected vertex glow, `onVerticesChanged` callback
- **Camera measurement page** — capture photo → add dimension annotations → calculate measurement
- **Camera FAB** on dashboard for quick access to camera workflow
- **Capability caching** — cache-first strategy with background hardware refresh, `forceRefresh` for manual rescan
- **Material estimation panel** — expandable card with concrete/cement/brick/steel/paint/tiles, wastage-adjusted costs

### Fixed
- `estimateForRoom`/`estimateForBuilding` — positional argument error (named param fix)
- `MeasurementAlgorithm.displayName` — missing import for extension method
- Platform channel mismatch — `geomeasure/capability_detection` + `detectCapabilities` method name
- `CameraProvider.selectedIndex` — derived from `selectedPhoto` via `indexWhere`

## [2.2.0] - 2026-07-26

### Added
- **Excel exporter** — pure Dart XLSX generator (Open XML + ZIP), no external packages
  - `exportMeasurements()` — 17-column measurement history
  - `exportTakeoff()` — Bill of Quantities with summary
  - `exportCostEstimate()` — cost breakdown with grand total
- **PDF report generator** — 5 professional templates (Construction, Inspection, Property, Inventory, Material Estimate)
- **Sensor fusion engine** — weighted multi-sensor fusion with 9 sensor types, circular heading averaging, confidence scoring
- **Photogrammetry pipeline** — FAST corner detector, NCC patch matching, DLT triangulation, scale calibration, surface area estimation
- Excel format added to ExportManager (8→9 formats)
- 16 new tests (226 total)

### Fixed
- Excel exporter null-aware operator warnings (fields are non-nullable with defaults)
- PDF report generator unnecessary null comparisons
- Photogrammetry curly braces lint warnings
- Renamed `Point3D` → `PgPoint3D` to avoid collision with sensor fusion types

### Changed
- Version bumped to 2.2.0+8

## [2.1.0] - 2026-07-26

### Added
- **T-Shape room** — composite room shape with main rect + perpendicular wing
- **U-Shape room** — composite room shape with main rect + two parallel wings
- **JSON exporter** — export measurements, take-offs, cost estimates as JSON
- **Vision service** — VisionService interface, VisionServiceFactory, LocalVisionService (pure Dart), MlKitVisionService (scaffold)
- JSON format added to ExportManager (7→8 formats)
- 17 new tests (210 total)

### Changed
- Moved all docs from root to `docs/` folder
- Comprehensive `.gitignore`

## [2.0.0] - 2026-07-26

### Added
- **11 universal 3D shapes**: Cylinder, Sphere, Cuboid, Cone, Frustum, L-Shape, Arch, Gable Roof, Hip Roof, Excavation, Pipe, Pool
- **7 precision modes**: Fast, Balanced, High Accuracy, Professional Survey, RTK GPS, LiDAR, Manual Verification
- **13 new measurement fields**: surfaceArea, lateralArea, wallArea, floorArea, ceilingArea, roofArea, footprintArea, excavationVolume, fillVolume, cutVolume, thickness, depth, elevation
- **AI vision entities**: 50+ ObjectCategory, BoundingBox with IoU, DetectedObject, ObjectCount, SegmentationMask, TextBlock, BarcodeResult, ImageLabel
- **Object counter**: NMS deduplication, confidence filtering, density estimation, multi-frame averaging
- **Edge detector**: Sobel edge detection, Harris corner detection, line detection — all pure Dart
- **Building analysis**: BuildingAnalysis with 20+ metrics, BuildingAnalyzer (FAR, coverage, open area)
- **Measurement validation**: MeasurementValidation with 5 quality grades, CalibrationStatus, EnvironmentalConditions
- **Material estimation**: 15 MaterialTypes, MaterialEstimate, QuantityTakeoff, CostEstimate, MaterialEstimator
- MeasurementResult.fromShape() factory constructor

### Changed
- Renamed BoxShape → CuboidShape to avoid Flutter name collision
- Expanded ShapeType enum with 16 new values

## [1.5.0] - 2026-07-26

### Added
- Production Firebase authentication service
- Real GPS tracking with Geolocator
- Camera service with image_picker
- AR engine interface
- Cloud sync service
- Maps service
- PDF export with `pdf` + `printing`

### Fixed
- Android build: resolved Theme.Light.NoActionBar resource error
- compileSdk 35, targetSdk 35, minSdk 24
- Material3 + AppCompat compatibility

## [1.0.0] - Initial Release

### Added
- Core measurement engine with 10 shape types
- Geodetic calculator (Vincenty/Haversine)
- Unit converter (distance + area)
- Floor plan canvas visualisation
- DXF, CSV, GeoJSON, SVG, KML export
- Capability detection service
- Hive local storage
- Dashboard UI with measurement modes
