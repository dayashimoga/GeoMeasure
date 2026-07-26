# Measurement Engine Specification

## Algorithm Hierarchy & Priority

1. **LiDAR (`lidar`)**: High-density hardware depth scanning (< 1cm error).
2. **Depth Sensor / ToF (`depthSensor`)**: Time-of-Flight depth measurement.
3. **ARCore / ARKit (`arCoreArKit`)**: Visual-Inertial Odometry feature tracking.
4. **Visual SLAM (`visualSlam`)**: Monocular camera + AI feature matching fallback.
5. **GPS + IMU (`gpsImu`)**: Geodetic outdoor plot measurement (Haversine / Shoelace).
6. **Manual Fallback (`manual`)**: User-entered dimension inputs.

## Spatial Entities & Geometry Math

- **Rooms / Enclosures**: Multi-wall polygon bounding box & volume calculation ($V = \text{Area} \times \text{Height}$).
- **Walls, Doors, Windows**: Rectangular area subtractions ($\text{Net Area} = \text{Wall Area} - \sum \text{Opening Areas}$).
- **Plots & Land Areas**: Shoelace formula for irregular polygons ($A = \frac{1}{2} |\sum (x_i y_{i+1} - x_{i+1} y_i)|$).

## Supported Units

- **Distance / Length**: Meters ($m$), Feet ($ft$), Inches ($in$), Yards ($yd$).
- **Area**: Square Meters ($m^2$), Square Feet ($sq\ ft$), Square Inches ($sq\ in$), Square Yards ($sq\ yd$), Acres ($ac$), Hectares ($ha$), Cents ($cent$), Guntha ($guntha$).
