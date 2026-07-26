# Measurement Engine

## Algorithm Hierarchy

The measurement engine selects the highest-accuracy algorithm available on the device:

| Priority | Algorithm | Accuracy | Sensor Required |
|----------|-----------|----------|----------------|
| 1 | LiDAR | <1 cm | LiDAR scanner |
| 2 | Depth Sensor (ToF) | <5 cm | Time-of-Flight sensor |
| 3 | ARCore/ARKit | ~2-5 cm | AR-capable device |
| 4 | Visual SLAM | ~5-15 cm | Camera + AI |
| 5 | GPS + IMU | 1-5 m | GPS + motion sensors |
| 6 | Manual | User-defined | None |

Selection is performed by `AlgorithmSelector.selectAlgorithm(CapabilityProfile)`.

## Supported Shapes (25)

### Room Shapes

| Shape | Parameters | Geometry |
|-------|-----------|----------|
| RectangularRoom | width, length, height | V = w × l × h |
| LShapeRoom | mainW, mainL, wingW, wingL, height | Composite rectangle |
| TShapeRoom | mainW, mainL, wingW, wingL, height | Main + centred wing |
| UShapeRoom | mainW, mainL, wingW, wingL, gapW, height | Main + 2 wings + courtyard |

### 3D Primitives

| Shape | Parameters | Volume |
|-------|-----------|--------|
| CuboidShape | width, length, height | V = w × l × h |
| CylinderShape | radius, height | V = π r² h |
| SphereShape | radius | V = 4/3 π r³ |
| ConeShape | radius, height | V = 1/3 π r² h |
| FrustumShape | topR, bottomR, height | V = πh/3(r₁² + r₁r₂ + r₂²) |

### Structures

| Shape | Parameters | Notes |
|-------|-----------|-------|
| ArchShape | span, rise, depth | Parabolic arch |
| GableRoofShape | span, rise, length | Triangular prism |
| HipRoofShape | width, length, rise | Pyramid-truncated prism |

### Infrastructure

| Shape | Parameters | Notes |
|-------|-----------|-------|
| PipeShape | outerR, innerR, length | Hollow cylinder |
| PoolShape | width, length, depth | + water volume in litres |
| ExcavationShape | width, length, depth | Cut/fill volumes |

### Land (Geodetic)

| Shape | Parameters | Notes |
|-------|-----------|-------|
| PlotShape | List of GPS coordinates | Vincenty/Haversine + Shoelace |

### Basic 2D

RectangleShape, CircleShape, TriangleShape, TrapezoidShape, EllipseShape, PolygonShape.

## Units

### Distance

| Unit | Label |
|------|-------|
| Meters | m |
| Feet | ft |
| Inches | in |
| Centimetres | cm |
| Millimetres | mm |
| Yards | yd |
| Kilometres | km |
| Miles | mi |

### Area

| Unit | Label | Conversion (from m²) |
|------|-------|----------------------|
| Square Metres | m² | 1 |
| Square Feet | sq ft | 10.7639 |
| Acres | ac | 0.000247105 |
| Hectares | ha | 0.0001 |
| Cents | cent | 0.024711 |
| Guntha | guntha | 0.000988 |

## Precision Modes

| Mode | Description |
|------|-------------|
| Fast | Quick estimate, lower accuracy |
| Balanced | Default trade-off |
| High Accuracy | Extended sensor sampling |
| Professional Survey | Survey-grade calibration |
| RTK GPS | Real-Time Kinematic correction |
| LiDAR | Hardware depth scanning |
| Manual Verification | User validates each measurement |

## Sensor Fusion

9 sensor types fused with weighted averaging. See [IMPLEMENTATION.md](IMPLEMENTATION.md#sensor-fusion-domainservicessensor_fusiondart) for weights and algorithm details.
