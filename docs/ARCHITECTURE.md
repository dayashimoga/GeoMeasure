# Architecture Specification

## Clean & Modular Architecture

GeoMeasure enforces Clean Architecture principles with explicit layer separation and feature-based modularization.

```
+-------------------------------------------------------------+
|                     Presentation Layer                      |
|            (UI Widgets, State Providers, Screens)           |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                        Domain Layer                         |
|     (Entities, Value Objects, Use Cases, Repositories)      |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                         Data Layer                          |
|         (Repository Implementations, Data Sources)          |
+-------------------------------------------------------------+
                              |
                              v
+-------------------------------------------------------------+
|                     Platform Layer                          |
|       (LiDAR, ToF, ARCore/ARKit, GPS, Sensor Channels)      |
+-------------------------------------------------------------+
```

## Feature Modules

- `capability_detection`: Detects device sensors, compute power, camera specs, thermal states, and returns a normalized capability profile.
- `measurement_engine`: Evaluates the normalized profile, dynamically selects the highest-accuracy measurement algorithm, executes spatial/land geometry math, and performs unit conversions.
