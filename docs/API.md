# API Reference

Public interfaces and service contracts.

## Capability Detection

```dart
/// lib/features/capability_detection/domain/repositories/capability_repository.dart
abstract class CapabilityRepository {
  Future<CapabilityProfile> detectCapabilities();
}
```

```dart
/// lib/features/capability_detection/domain/entities/capability_profile.dart
class CapabilityProfile {
  final bool hasLidar;
  final bool hasDepthSensor;
  final bool hasArCore;
  final bool hasGps;
  final bool hasGyroscope;
  final bool hasAccelerometer;
  final bool hasMagnetometer;
  final bool hasBarometer;
  final int cameraCount;
  final int cpuCores;
  final int ramMb;
  final String osVersion;
  final double batteryLevel;
  final String thermalState;
  final AccuracyClassification overallAccuracy;
}
```

## Measurement Engine

```dart
/// lib/features/measurement_engine/domain/usecases/execute_measurement_usecase.dart
class ExecuteMeasurementUseCase {
  MeasurementResult call({
    required SpatialShape shape,
    required CapabilityProfile profile,
    required DistanceUnit distanceUnit,
    required AreaUnit areaUnit,
  });
}
```

```dart
/// lib/features/measurement_engine/domain/entities/spatial_shape.dart
abstract class SpatialShape {
  double calculateAreaInSquareMeters();
  double calculatePerimeterInMeters();
  double calculateVolumeInCubicMeters();
  bool validate();
  String? get validationError;
  Map<String, dynamic> toJson();
}
```

## Vision Service

```dart
/// lib/features/ai_vision/data/services/vision_service.dart
abstract class VisionService {
  bool get isAvailable;
  Future<List<DetectedObject>> detectObjects(Uint8List imageBytes, int width, int height);
  Future<List<ImageLabel>> labelImage(Uint8List imageBytes);
  Future<List<BarcodeResult>> scanBarcodes(Uint8List imageBytes);
  void dispose();
}

class VisionServiceFactory {
  static VisionService create();
}
```

## Export

```dart
/// lib/core/export/export_manager.dart
class ExportManager {
  static String export(ExportFormat format, {...});
  static String fileExtension(ExportFormat format);
  static String mimeType(ExportFormat format);
  static String formatDisplayName(ExportFormat format);
  static List<ExportFormat> supportedFormats(SpatialShape? shape);
}
```

```dart
/// lib/features/export/excel_exporter.dart
class ExcelExporter {
  static Uint8List exportMeasurements(List<MeasurementResult> results);
  static Uint8List exportTakeoff(QuantityTakeoff takeoff);
  static Uint8List exportCostEstimate(CostEstimate estimate);
}
```

## Sensor Fusion

```dart
/// lib/features/measurement_engine/domain/services/sensor_fusion.dart
class SensorFusionEngine {
  FusedState addReading(SensorReading reading);
  FusedState get currentState;
  void reset();
  static double distance(FusedState a, FusedState b);
}
```

## Secure Storage

```dart
/// lib/core/security/secure_storage.dart
abstract class SecureStorageService {
  Future<void> write(String key, String value);
  Future<String?> read(String key);
  Future<void> delete(String key);
  Future<void> deleteAll();
  Future<bool> containsKey(String key);
}
```
