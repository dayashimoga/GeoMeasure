# GeoMeasure - Capability-Aware Spatial & Land Measurement Engine

GeoMeasure is a production-grade cross-platform mobile application designed to measure rooms, houses, plots, sites, and land areas. It automatically probes device hardware/software capabilities and selects the highest-accuracy measurement technique available.

## Primary Objective
Ensure accurate spatial measurement across all smartphones, with fallback paths guaranteeing the app **never fails** regardless of missing hardware:

`LiDAR` → `Depth Sensor (ToF)` → `ARCore / ARKit` → `Visual SLAM (Camera + AI)` → `GPS + IMU + Compass` → `Manual Fallback`

---

## Technical Stack & Architecture

- **Framework**: Flutter / Dart
- **Architecture**: Clean Architecture (Presentation, Domain, Data, Platform, Infrastructure) + Feature Modules
- **Design Patterns**: Repository Pattern, SOLID, DRY, KISS, YAGNI, Hexagonal Architecture
- **Containerization**: Docker & Docker Compose
- **CI/CD**: GitHub Actions

---

## Quick Start (Docker)

Run tests and static analysis inside isolated Docker environment:

```bash
# Run Unit Tests
docker compose run --rm app-test

# Run Static Analysis
docker compose run --rm app-analyze
```

---

## Repository Documentation Index

- [ARCHITECTURE.md](ARCHITECTURE.md) - System architecture design
- [MEASUREMENT_ENGINE.md](MEASUREMENT_ENGINE.md) - Measurement algorithms & geometry specs
- [DEVICE_CAPABILITIES.md](DEVICE_CAPABILITIES.md) - Capability detection matrix
- [REQUIREMENTS.md](REQUIREMENTS.md) - Functional & non-functional specifications
- [TESTING.md](TESTING.md) - Test strategy & coverage guidelines
- [PERFORMANCE.md](PERFORMANCE.md) - Performance benchmarks & targets
