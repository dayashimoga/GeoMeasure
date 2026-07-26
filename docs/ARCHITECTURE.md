# Architecture

## Overview

GeoMeasure follows **Clean Architecture** with **feature-based modularisation**. Each feature is a self-contained module with its own domain, data, and presentation layers.

```mermaid
graph TB
    subgraph Presentation["Presentation Layer"]
        UI["UI Widgets & Pages"]
        Providers["State Providers"]
    end
    subgraph Domain["Domain Layer"]
        Entities["Entities & Value Objects"]
        UseCases["Use Cases"]
        RepoContracts["Repository Contracts"]
        Services["Domain Services"]
    end
    subgraph Data["Data Layer"]
        RepoImpl["Repository Implementations"]
        DataSources["Local & Remote Data Sources"]
    end
    subgraph Platform["Platform Layer"]
        Channels["Platform Channels"]
        NativeSDK["LiDAR / ARCore / GPS / Sensors"]
    end

    UI --> Providers --> UseCases --> RepoContracts
    RepoContracts -.-> RepoImpl --> DataSources --> Channels --> NativeSDK
    UseCases --> Entities
    UseCases --> Services
```

## Layer Responsibilities

| Layer | Responsibility | Dependencies |
|-------|---------------|-------------|
| **Presentation** | UI widgets, state management, user interaction | Domain |
| **Domain** | Business logic, entities, use cases, service contracts | None (pure Dart) |
| **Data** | Repository implementations, local/remote data sources | Domain contracts |
| **Platform** | Native SDK bridges, platform channels | Data layer |

## Dependency Injection

Manual service locator pattern in [`lib/core/di/service_locator.dart`](../lib/core/di/service_locator.dart).

```mermaid
graph LR
    SL["ServiceLocator (sl)"] --> Config["AppConfig"]
    SL --> Logger["AppLogger"]
    SL --> CmdMgr["CommandManager"]
    SL --> Platform["PlatformChannelService"]
    SL --> CapRepo["CapabilityRepository"]
    SL --> CapUC["DetectCapabilitiesUseCase"]
    SL --> CapProv["CapabilityProvider"]
    SL --> MeasRepo["MeasurementRepository"]
    SL --> MeasUC["ExecuteMeasurementUseCase"]
    SL --> MeasProv["MeasurementProvider"]
    SL --> ProjRepo["ProjectRepository"]
    SL --> ProjProv["ProjectProvider"]
```

**Initialisation order**: Core → Platform → Capability Detection → Measurement Engine → Project Management.

Global singleton: `final sl = ServiceLocator();` accessed throughout the app.

## Feature Modules

```mermaid
graph TB
    subgraph Features
        CD["capability_detection"]
        ME["measurement_engine"]
        AV["ai_vision"]
        AR["ar_measurement"]
        Auth["auth"]
        Cam["camera"]
        GPS["gps_tracking"]
        CS["cloud_sync"]
        OM["offline_maps"]
        EST["estimation"]
        EXP["export"]
        PM["project_management"]
        VIS["visualization"]
        PRES["presentation"]
    end

    PRES --> ME
    PRES --> CD
    PRES --> PM
    ME --> CD
    EXP --> ME
    EXP --> EST
    EST --> ME
    AV --> ME
```

| Module | Purpose |
|--------|---------|
| `capability_detection` | Probes device sensors, returns normalised `CapabilityProfile` |
| `measurement_engine` | Shape geometry, algorithm selection, unit conversion, geodetics |
| `ai_vision` | Edge detection, object counting, photogrammetry, building analysis |
| `ar_measurement` | ARCore/ARKit measurement interface |
| `auth` | Firebase authentication service |
| `camera` | Image capture via `image_picker` |
| `gps_tracking` | Real-time GPS positioning via `geolocator` |
| `cloud_sync` | Remote data synchronisation |
| `offline_maps` | Map tile caching |
| `estimation` | Material estimation, quantity take-offs, cost estimates |
| `export` | PDF, Excel exporters; PDF report templates |
| `project_management` | Project CRUD, Hive persistence |
| `visualization` | Floor plan canvas rendering |
| `presentation` | Dashboard, history, GPS pages, shared widgets |

## State Management

ChangeNotifier-based providers, manually wired through `ServiceLocator`:

- `CapabilityProvider` — device capability state
- `MeasurementProvider` — measurement history and active result
- `ProjectProvider` — project list and active project

## Design Patterns

| Pattern | Usage |
|---------|-------|
| **Repository** | Abstract data access contracts in Domain, implementations in Data |
| **Use Case** | Single-responsibility business operations |
| **Command** | Undo/redo support via `CommandManager` with configurable stack depth |
| **Factory** | `VisionServiceFactory`, `MeasurementResult.fromShape()` |
| **Strategy** | `AlgorithmSelector` picks measurement algorithm based on capability profile |
| **Singleton** | `AppConfig`, `ServiceLocator` |

## Data Flow

```mermaid
sequenceDiagram
    participant UI as Dashboard
    participant Prov as MeasurementProvider
    participant UC as ExecuteMeasurementUseCase
    participant Algo as AlgorithmSelector
    participant Shape as SpatialShape
    participant Repo as MeasurementRepository

    UI->>Prov: executeMeasurement(shape, profile)
    Prov->>UC: call(shape, profile, unit)
    UC->>Algo: selectAlgorithm(profile)
    UC->>Shape: calculateAreaInSquareMeters()
    UC->>Repo: saveMeasurement(result)
    UC-->>Prov: MeasurementResult
    Prov-->>UI: notifyListeners()
```
