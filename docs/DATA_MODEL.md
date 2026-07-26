# Data Model

## Core Entities

### MeasurementResult

Primary output entity from `ExecuteMeasurementUseCase`.

| Field | Type | Default |
|-------|------|---------|
| `id` | `String` | UUID |
| `area` | `double` | required |
| `areaUnit` | `AreaUnit` | required |
| `perimeter` | `double` | required |
| `distanceUnit` | `DistanceUnit` | required |
| `volume` | `double` | 0.0 |
| `wallArea` | `double` | 0.0 |
| `floorArea` | `double` | 0.0 |
| `ceilingArea` | `double` | 0.0 |
| `surfaceArea` | `double` | 0.0 |
| `lateralArea` | `double` | 0.0 |
| `roofArea` | `double` | 0.0 |
| `footprintArea` | `double` | 0.0 |
| `excavationVolume` | `double` | 0.0 |
| `fillVolume` | `double` | 0.0 |
| `cutVolume` | `double` | 0.0 |
| `thickness` | `double` | 0.0 |
| `depth` | `double` | 0.0 |
| `elevation` | `double` | 0.0 |
| `shapeType` | `ShapeType` | required |
| `shapeName` | `String` | '' |
| `algorithmUsed` | `MeasurementAlgorithm` | required |
| `estimatedAccuracyPercentage` | `double` | required |
| `confidenceScore` | `double` | 0.0 |
| `sensorUsed` | `String` | '' |
| `precisionMode` | `PrecisionMode` | `.balanced` |
| `timestamp` | `DateTime` | `DateTime.now()` |

Serialisation: `toJson()` / `MeasurementResult.fromJson()`.

### CapabilityProfile

Device hardware profile returned by `DetectCapabilitiesUseCase`.

| Field | Type | Description |
|-------|------|-------------|
| `hasLidar` | `bool` | LiDAR scanner available |
| `hasDepthSensor` | `bool` | ToF depth sensor |
| `hasArCore` | `bool` | ARCore support |
| `hasGps` | `bool` | GPS available |
| Sensors | `bool` flags | Gyro, accel, magnetometer, barometer |
| `overallAccuracy` | `AccuracyClassification` | high, medium, low, basic |

### Project

| Field | Type |
|-------|------|
| `id` | `String` (UUID) |
| `name` | `String` |
| `description` | `String` |
| `measurements` | `List<MeasurementResult>` |
| `createdAt` | `DateTime` |
| `updatedAt` | `DateTime` |

### MaterialEstimate

| Field | Type |
|-------|------|
| `material` | `MaterialType` (15 values) |
| `quantity` | `double` |
| `unit` | `MaterialUnit` |
| `unitCost` | `double` |
| `totalCost` | `double` (computed) |

### BuildingAnalysis

| Field | Type |
|-------|------|
| `numberOfFloors` | `int` |
| `roofType` | `RoofType` (8 values) |
| `footprintAreaSqm` | `double` |
| `totalFloorAreaSqm` | `double` |
| `floorAreaRatio` | `double` |
| `groundCoverageRatio` | `double` |
| `openAreaRatio` | `double` |
| `windowCount` | `int` |
| `doorCount` | `int` |

## Storage

### Hive Local Storage

- **Projects**: Stored as JSON strings in Hive box `projects`
- **Measurements**: Embedded within Project JSON
- **Secure data**: AES-256 encrypted Hive box `secure_storage`

### Serialisation

All entities implement `toJson()` and static `fromJson()` / `fromMap()` for Hive and export compatibility.
