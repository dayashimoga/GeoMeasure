# Project Structure

```
geomeasure/
├── README.md                          # Project overview, quick start
├── pubspec.yaml                       # Dart/Flutter dependencies
├── analysis_options.yaml              # Lint rules
├── Dockerfile                         # Multi-stage Flutter build image
├── docker-compose.yml                 # CI/CD service definitions
├── build-docker.ps1                   # Windows Docker build script
├── LICENSE                            # MIT License
│
├── docs/                              # All project documentation
│   ├── INDEX.md                       # Central navigation
│   ├── ARCHITECTURE.md                # System design
│   ├── IMPLEMENTATION.md              # Module details
│   ├── PROJECT_STATUS.md              # Completion matrix
│   ├── CHANGELOG.md                   # Version history
│   └── ...                            # See docs/INDEX.md
│
├── lib/                               # Application source code
│   ├── main.dart                      # App entry point
│   │
│   ├── core/                          # Cross-cutting concerns
│   │   ├── commands/command.dart       # Undo/redo command manager
│   │   ├── config/app_config.dart     # Feature flags, constants
│   │   ├── di/service_locator.dart    # Dependency injection
│   │   ├── error/failures.dart        # Error types
│   │   ├── export/                    # Export manager + JSON exporter
│   │   ├── logging/app_logger.dart    # Structured logging
│   │   ├── platform/                  # Platform channel service
│   │   ├── security/secure_storage.dart # Encrypted Hive storage
│   │   ├── theme/app_theme.dart       # Light/dark Material themes
│   │   └── usecases/usecase.dart      # Base use case interface
│   │
│   └── features/                      # Feature modules
│       ├── ai_vision/                 # Computer vision & photogrammetry
│       │   ├── data/services/         # VisionService implementations
│       │   └── domain/
│       │       ├── entities/          # DetectedObject, BuildingAnalysis, etc.
│       │       └── services/          # EdgeDetector, ObjectCounter, Photogrammetry
│       │
│       ├── ar_measurement/            # AR measurement interface
│       ├── auth/                      # Firebase authentication
│       ├── camera/                    # Image capture service
│       ├── capability_detection/      # Hardware sensor probing
│       │   ├── data/                  # HardwareCapabilityDataSource
│       │   ├── domain/               # CapabilityProfile, SensorType
│       │   └── presentation/         # CapabilityProvider
│       │
│       ├── cloud_sync/               # Cloud synchronisation
│       ├── estimation/               # Material & cost estimation
│       ├── export/                   # PDF, Excel exporters
│       ├── gps_tracking/             # GPS positioning service
│       ├── measurement_engine/       # Core measurement logic
│       │   ├── data/                 # Local data source, repository impl
│       │   ├── domain/
│       │   │   ├── entities/         # SpatialShape, MeasurementResult, etc.
│       │   │   ├── repositories/     # MeasurementRepository contract
│       │   │   ├── services/         # Exporters, geodetic calc, sensor fusion
│       │   │   └── usecases/         # ExecuteMeasurementUseCase
│       │   └── presentation/        # MeasurementProvider
│       │
│       ├── offline_maps/            # Map tile caching
│       ├── presentation/            # Shared UI
│       │   ├── pages/               # Dashboard, History, GPS pages
│       │   └── widgets/             # CapabilityCard, MeasurementDisplay
│       ├── project_management/      # Project CRUD + Hive persistence
│       └── visualization/           # Floor plan canvas widget
│
├── test/                            # Test suite (226 tests)
│   ├── widget_test.dart             # App smoke test
│   └── features/
│       ├── universal_platform_test.dart              # 209 domain tests
│       └── presentation/pages/
│           └── dashboard_page_test.dart              # Widget tests
│
├── integration_test/                # Integration tests (placeholder)
├── android/                         # Android platform config
├── ios/                             # iOS platform config
├── web/                             # Web platform config
├── assets/                          # Static assets
└── .github/workflows/ci.yml        # GitHub Actions CI/CD
```

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.dart` | `spatial_shape.dart` |
| Classes | `PascalCase` | `MeasurementResult` |
| Methods | `camelCase` | `calculateAreaInSquareMeters()` |
| Constants | `camelCase` | `maxProjectsPerUser` |
| Feature dirs | `snake_case` | `measurement_engine` |
| Test files | `*_test.dart` | `universal_platform_test.dart` |

## Source File Count

| Directory | Files |
|-----------|-------|
| `lib/core/` | 10 |
| `lib/features/` | 57 |
| `test/` | 3 |
| **Total** | 70 |
