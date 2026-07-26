# Engine Public API Interface

## Capability Detection Engine

```dart
abstract class CapabilityRepository {
  Future<CapabilityProfile> detectCapabilities();
}
```

## Measurement Engine

```dart
abstract class MeasurementEngine {
  MeasurementResult measureShape({
    required SpatialShape shape,
    required CapabilityProfile profile,
    required MeasurementUnit targetUnit,
  });
}
```
