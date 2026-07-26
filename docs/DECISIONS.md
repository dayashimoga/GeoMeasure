# Architecture Decision Records

## ADR-001: Clean Architecture with Feature Modules
- **Context**: Need high maintainability, testability, and clear separation between platform sensors and measurement domain logic.
- **Decision**: Adopt Clean Architecture (Presentation → Domain → Data → Platform) organised by feature modules.
- **Consequences**: Enables 100% pure unit testing of domain calculations without native UI dependencies. 226 tests pass without any device or emulator.

## ADR-002: Dockerised Development & CI
- **Context**: Ensure reproducible builds across developer workstations and CI runners.
- **Decision**: Provide Dockerfile (multi-stage, based on `cirrusci/flutter:3.22.0`) and Docker Compose with 8 service targets.
- **Consequences**: Any developer can run the full CI pipeline locally without installing Flutter.

## ADR-003: Manual Service Locator over get_it
- **Context**: Need DI for testability without adding external packages early.
- **Decision**: Implement manual `ServiceLocator` singleton with explicit initialisation order.
- **Consequences**: Simple and zero-dependency, but doesn't scale past ~20 services. Migration path to `get_it` documented in [KNOWN_ISSUES.md](KNOWN_ISSUES.md).

## ADR-004: Hive over SQLite for Local Storage
- **Context**: Need lightweight, fast local persistence that works on all platforms including web.
- **Decision**: Use Hive with JSON string serialisation for projects and measurements.
- **Consequences**: Works cross-platform including web. Trade-off: JSON string storage is slower than TypeAdapters for large datasets.

## ADR-005: Pure Dart Vision & Photogrammetry
- **Context**: Need computer vision capabilities that work on all platforms without native dependencies.
- **Decision**: Implement Sobel edge detection, Harris corners, FAST corners, NCC matching, and DLT triangulation in pure Dart.
- **Consequences**: Works everywhere (including web and tests) but accuracy is limited compared to ML Kit or OpenCV. ML Kit integration scaffolded for future upgrade.

## ADR-006: Pure Dart Excel Export
- **Context**: Need Excel export without adding heavy native packages that may break web/test compatibility.
- **Decision**: Build XLSX files from scratch using Open XML format with a hand-rolled ZIP builder and CRC-32 checksums.
- **Consequences**: Zero external dependencies, works on all platforms. Generates valid XLSX files verified by ZIP header tests.

## ADR-007: Feature Flags System
- **Context**: Not all features are production-ready; need to gate unfinished features.
- **Decision**: `AppConfig` singleton with a `Map<String, bool>` of feature flags, runtime-configurable.
- **Consequences**: Features like AR, AI, cloud sync are disabled by default. Can be enabled per-device or via remote config in future.
