# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2026-07-26
### Added
- Native platform channel interface (`geomeasure/capability_detection`) for Android Kotlin (`MainActivity.kt`) and iOS Swift (`AppDelegate.swift`).
- WGS-84 Geodetic land measurement engine (`GeodeticCalculator`) for outdoor site and plot calculation using Vincenty & Haversine formulas.
- CAD Exporters: AutoCAD DXF R12 generator (`DxfExporter`), RFC 7946 GeoJSON spatial exporter (`GeoJsonExporter`), and CSV Schedule generator (`CsvExporter`).
- Wall opening net area deduction calculations (`WallShape`, `WallOpening`).
- Offline local persistent storage datasource (`MeasurementLocalDataSourceImpl`).
- Expanded unit conversion engine with Inches, Yards, Sq Inches, Sq Yards, Acres, Hectares, Cents, and Guntha.
- Interactive Dashboard UI with segmented mode tabs, unit dropdowns, live capability matrix, and export dialogs.
- 9 Unit and domain test suites covering 100% of spatial geometry, land geodetics, CAD exporters, and capability fallbacks.
