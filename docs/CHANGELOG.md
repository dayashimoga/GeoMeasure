# Changelog

All notable changes to this project will be documented in this file.

## [1.1.0] - 2026-07-26 — Gap Analysis & Production Hardening
### Fixed
- G1: Added 8 missing capability fields (flash, microphone, GPU, displayResolution, cameraCalibrated, networkType, storageAvailableMb, osVersion).
- G2: Added thermal throttle guard and low-battery fallback to AlgorithmSelector.
- G3: Replaced bare in-memory Map storage with serialized JSON round-trip datasource including delete/clearAll.
- G4: Added degenerate triangle input validation (triangle inequality check).
- G5: Added timestamp, shapeType, shapeName to MeasurementResult with toJson/fromJson serialization.
- G6: Added format check, secret scan, dependency audit steps to CI workflow.
- G7: Removed obsolete `version` key from docker-compose.yml; added app-format service.
- G8: Added comprehensive edge-case tests (50+ test cases across 13 files).
- G9: Added all 6 algorithm fallback path tests plus thermal/battery guard tests.
- G10: Fixed garbled unicode character in LICENSE.
- G11: Fixed package name typo from meassure_app to geomeasure.
- G12: Removed unused SensorType import from datasource.
- G13: Fixed updateUnits to recalculate last measurement instead of being a dead no-op.

### Added
- E1: MeasurementResult.toJson/fromJson for offline persistence round-trip.
- E3: CapabilityProfile.toJson for session caching.
- E4: Shape input validation (validate() method on all SpatialShape subclasses).
- E5: BuildingShape.calculateTotalWallSurfaceArea() for multi-floor exterior surface area.
- E8: 13 comprehensive test suites with edge-case and failure-path coverage.

## [1.0.0] - 2026-07-26
### Added
- Initial Clean Architecture foundation.
- Capability Detection Engine with normalized profile.
- Measurement Engine with dynamic algorithm fallback hierarchy.
- CAD Exporters (DXF, GeoJSON, CSV).
- WGS-84 Geodetic land plot calculator.
- Native Android/iOS platform channel bindings.
- Docker environment and GitHub Actions CI/CD pipeline.
