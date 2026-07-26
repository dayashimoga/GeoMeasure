# Project Requirements

## Functional Requirements
1. **Capability Probing**: Probe all hardware sensors (LiDAR, ToF, AR, Cameras, GPS, Gyro, Battery, RAM, OS).
2. **Dynamic Strategy Selection**: Dynamically select measurement strategy based on hardware availability.
3. **Geometry Calculation**: Support Rooms, Walls, Openings, Buildings, Irregular Polygons, Circles, Rectangles.
4. **Multi-Unit Conversion**: Convert distances and areas between metric, imperial, and land units (Acres, Hectares, Cents, Guntha).

## Non-Functional Requirements
1. **Cold Startup**: Under 2.0 seconds.
2. **Reliability**: Zero failure policy regardless of missing device sensors.
3. **Offline First**: All calculations executed locally without requiring network connectivity.
