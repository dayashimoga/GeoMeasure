# GeoMeasure

**Capability-Aware Spatial & Land Measurement Engine**

GeoMeasure is a cross-platform Flutter application for measuring rooms, buildings, plots, and land areas. It probes device hardware capabilities and selects the highest-accuracy measurement technique available, with automatic fallback.

```
LiDAR → Depth Sensor (ToF) → ARCore/ARKit → Visual SLAM → GPS + IMU → Manual
```

| Metric | Value |
|--------|-------|
| Version | 2.2.0+8 |
| Tests | 226 passing |
| Analysis | 0 errors, 0 warnings |
| Platforms | Android, iOS, Web |
| Architecture | Clean Architecture + Feature Modules |

## Quick Start

```bash
# Flutter (local)
flutter pub get
flutter test
flutter run

# Docker (containerised)
docker compose run --rm app-test
docker compose run --rm app-analyze
docker compose run --rm app-build-web
```

## Documentation

All project documentation is in [`docs/`](docs/INDEX.md).

| Document | Description |
|----------|-------------|
| [INDEX](docs/INDEX.md) | Central navigation page |
| [ARCHITECTURE](docs/ARCHITECTURE.md) | System design, layers, patterns |
| [IMPLEMENTATION](docs/IMPLEMENTATION.md) | Module-by-module technical detail |
| [PROJECT_STATUS](docs/PROJECT_STATUS.md) | Completion matrix, readiness assessment |
| [CHANGELOG](docs/CHANGELOG.md) | Version history |

## License

See [LICENSE](LICENSE).
