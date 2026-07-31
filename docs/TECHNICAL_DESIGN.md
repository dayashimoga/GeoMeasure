# Technical Design — GeoMeasure

## Architecture

```
┌──────────────────────────────────────────────────────┐
│                    Presentation                       │
│  DashboardPage · WizardPage · CameraPage · GPSPage   │
│  MeasurementDisplay · FloorPlanCanvas · CapabilityCard│
├──────────────────────────────────────────────────────┤
│                     Providers                         │
│  MeasurementProvider · ProjectProvider · CapabilityPr.│
├──────────────────────────────────────────────────────┤
│                    Domain Layer                       │
│  UseCases: ExecuteMeasurement · SlopeCalculation      │
│  Entities: SpatialShape · MeasurementResult · Project │
│  Services: UnitConverter · GeodeticCalc · Estimator   │
├──────────────────────────────────────────────────────┤
│                    Export Layer                        │
│  DXF · CSV · SVG · KML · GeoJSON · JSON · Excel · PDF│
├──────────────────────────────────────────────────────┤
│                    Data Layer                          │
│  HiveRepository · BackupService · CameraService       │
├──────────────────────────────────────────────────────┤
│                  Platform Layer                        │
│  Geolocator · Camera · Sensors · MLKit (disabled)     │
└──────────────────────────────────────────────────────┘
```

## Dependency Injection

Manual `ServiceLocator` singleton (`core/di/service_locator.dart`).

```dart
class ServiceLocator {
  late AppConfig config;
  late MeasurementProvider measurementProvider;
  late ProjectProvider projectProvider;
  late CapabilityProvider capabilityProvider;
  late CommandManager commandManager;
}
```

## Measurement Pipeline

1. **User selects mode** (Room/Wall/Land/Object/Building)
2. **Enter dimensions** (manual input or GPS waypoints)
3. **Algorithm selection** — `AlgorithmSelector` picks best based on `CapabilityProfile`
4. **Calculation** — `ExecuteMeasurementUseCase` computes area, perimeter, volume
5. **Result** — `MeasurementResult` with shape, area, perimeter, volume, algorithm, accuracy
6. **Export** — DXF/CSV/SVG/KML/GeoJSON/JSON/Excel/PDF

## Shape Hierarchy

| Shape | Properties | Computes |
|-------|-----------|----------|
| `RectangleShape` | length × width | area, perimeter |
| `CircleShape` | radius | area, circumference |
| `TriangleShape` | sideA, sideB, sideC | area (Heron), perimeter |
| `RoomShape` | vertices[] + height | floor area, wall area, volume |
| `WallShape` | length, height, openings[] | net area (minus openings) |
| `BuildingShape` | width, depth, floors, floorHeight | total area, volume |
| `PlotShape` | GPS coordinates[] | geodetic area (Shoelace), perimeter |
| `IrregularPolygonShape` | vertices[] | area, perimeter |

## Algorithm Selection

| Algorithm | Trigger | Accuracy |
|-----------|---------|----------|
| `manual` | Always available (fallback) | 50-70% |
| `gps` | Geolocator available | 60-85% |
| `camera` | Camera available | 65-80% |
| `arCore` / `arKit` | AR hardware detected | 85-98% |
| `lidar` | LiDAR sensor detected | 90-99% |
| `slam` | Camera + IMU + processing | 80-95% |

## Export Formats

| Format | Engine | Status |
|--------|--------|--------|
| DXF | `DxfExporter` | ✅ Working |
| CSV | `CsvExporter` | ✅ Working |
| SVG | `SvgExporter` | ✅ Working |
| GeoJSON | `GeoJsonExporter` | ✅ Working |
| KML | `KmlExporter` | ✅ Working |
| JSON | `MeasurementResult.toJson()` | ✅ Working |
| Excel | `ExcelExporter` (pure Dart XLSX) | ✅ Working |
| PDF | Text summary (planned: pdf package) | 🟡 Text-only |

## State Management

- `ChangeNotifier` + `ListenableBuilder`
- Undo/redo via `CommandManager` (Command pattern)
- Persistence via Hive (JSON string storage)

## Feature Flags

Runtime-configurable via `AppConfig.setFeatureFlag()`.

| Flag | Default | Purpose |
|------|---------|---------|
| `manual_measurement` | true | Manual dimension input |
| `gps_tracking` | true | GPS waypoint collection |
| `ar_measurement` | false | AR measurement (not impl.) |
| `ai_detection` | true | AI object detection |
| `camera_capture` | true | Camera photo capture |
| `cloud_sync` | false | Remote sync (not impl.) |
| `export_*` | true | Individual export formats |
| `sensor_fusion` | true | Multi-sensor fusion |

## Security Considerations

- All processing is on-device (no cloud dependency)
- GPS coordinates stored locally in Hive
- No external API keys required for core functionality
- Backup files are plain JSON (user responsibility to secure)
- No authentication system (planned for cloud sync)

## Performance

- Algorithm selection: O(1) — hardware profile cached
- Area calculation: O(n) where n = vertices
- Export generation: O(n) where n = measurements
- Hive persistence: O(1) per read/write
- Auto-save interval: 30 seconds
