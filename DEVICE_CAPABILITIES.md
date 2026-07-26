# Device Capabilities Matrix

## Probed Sensors & Hardware Features

- **Sensors**: LiDAR, ToF Depth, ARCore/ARKit, GPS, Gyroscope, Accelerometer, Magnetometer/Compass, Barometer, UWB, NFC, Bluetooth.
- **Compute & Platform**: CPU Cores, GPU, AI Accelerator, RAM, OS Version, Battery Level, Thermal State.
- **Camera Specs**: Camera types, display resolution, focal length calibration status.
- **Permissions**: Location, Camera, Sensor permissions.

## Capability Profile Normalization

Returns a normalized `CapabilityProfile` containing sensor availability flags, thermal throttling warnings, and overall system accuracy classification (`high`, `medium`, `low`, `basic`).
