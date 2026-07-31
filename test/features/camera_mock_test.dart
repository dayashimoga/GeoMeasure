import 'package:flutter_test/flutter_test.dart';
import 'package:geomeasure/features/camera/camera_service.dart';

/// Camera mock tests — verifies CameraProvider behavior using
/// a mock CameraService that doesn't require actual device camera.
///
/// Tests photo CRUD, annotation management, selection, and error handling.
void main() {
  group('CameraProvider — Mock Tests', () {
    late CameraProvider provider;

    setUp(() {
      provider = CameraProvider(service: _MockCameraService());
    });

    test('starts with empty photo list', () {
      expect(provider.photos, isEmpty);
      expect(provider.photoCount, equals(0));
      expect(provider.selectedPhoto, isNull);
    });

    test('capturePhoto adds photo to list', () async {
      await provider.capturePhoto();
      expect(provider.photoCount, equals(1));
      expect(provider.selectedPhoto, isNotNull);
      expect(provider.selectedPhoto!.filePath, contains('mock'));
    });

    test('pickFromGallery adds photo', () async {
      await provider.pickFromGallery();
      expect(provider.photoCount, equals(1));
      expect(provider.selectedPhoto, isNotNull);
    });

    test('pickMultiple adds multiple photos', () async {
      await provider.pickMultiple();
      expect(provider.photoCount, equals(3)); // Mock returns 3
    });

    test('multiple captures accumulate', () async {
      await provider.capturePhoto();
      await provider.capturePhoto();
      await provider.capturePhoto();
      expect(provider.photoCount, equals(3));
    });

    test('selectPhoto updates selected', () async {
      await provider.capturePhoto();
      await provider.capturePhoto();
      provider.selectPhoto(0);
      // First captured photo should be selected
      expect(provider.selectedPhoto, isNotNull);
      expect(provider.selectedPhoto!.filePath,
          equals(provider.photos[0].filePath));
    });

    test('selectPhoto ignores invalid index', () async {
      await provider.capturePhoto();
      provider.selectPhoto(99);
      expect(provider.selectedPhoto, isNotNull); // unchanged
    });

    test('removePhoto decreases count', () async {
      await provider.capturePhoto();
      await provider.capturePhoto();
      provider.removePhoto(0);
      expect(provider.photoCount, equals(1));
    });

    test('removePhoto updates selected if removed was selected', () async {
      await provider.capturePhoto();
      await provider.capturePhoto();
      provider.selectPhoto(0);
      provider.removePhoto(0);
      expect(provider.selectedPhoto, isNotNull);
    });

    test('removePhoto last photo sets selected to null', () async {
      await provider.capturePhoto();
      provider.removePhoto(0);
      expect(provider.selectedPhoto, isNull);
      expect(provider.photoCount, equals(0));
    });

    test('clearAll empties everything', () async {
      await provider.capturePhoto();
      await provider.capturePhoto();
      provider.clearAll();
      expect(provider.photoCount, equals(0));
      expect(provider.selectedPhoto, isNull);
    });

    test('addAnnotation stores annotation on photo', () async {
      await provider.capturePhoto();
      provider.addAnnotation(
        0,
        const PhotoAnnotation(
          x: 100,
          y: 200,
          label: '5.2m',
          type: AnnotationType.dimension,
        ),
      );
      expect(provider.photos[0].annotations.length, equals(1));
      expect(provider.photos[0].annotations[0].label, equals('5.2m'));
    });

    test('addAnnotation ignores invalid index', () async {
      await provider.capturePhoto();
      provider.addAnnotation(
        99,
        const PhotoAnnotation(x: 0, y: 0, label: 'x'),
      );
      // Should not crash
      expect(provider.photoCount, equals(1));
    });

    test('updateDescription modifies photo', () async {
      await provider.capturePhoto();
      provider.updateDescription(0, 'Living room north wall');
      expect(provider.photos[0].description, equals('Living room north wall'));
    });

    test('multiple annotations on same photo', () async {
      await provider.capturePhoto();
      for (int i = 0; i < 5; i++) {
        provider.addAnnotation(
          0,
          PhotoAnnotation(
            x: i * 50.0,
            y: i * 50.0,
            label: '${i + 1}m',
            type: AnnotationType.dimension,
          ),
        );
      }
      expect(provider.photos[0].annotations.length, equals(5));
    });

    test('error state remains null on successful ops', () async {
      await provider.capturePhoto();
      expect(provider.errorMessage, isNull);
    });
  });

  group('CameraProvider — Failure Simulation', () {
    test('capturePhoto with failing service gracefully handles null', () async {
      final provider = CameraProvider(service: _FailingCameraService());
      await provider.capturePhoto();
      expect(provider.photoCount, equals(0));
      expect(provider.selectedPhoto, isNull);
    });

    test('pickFromGallery with failing service handles null', () async {
      final provider = CameraProvider(service: _FailingCameraService());
      await provider.pickFromGallery();
      expect(provider.photoCount, equals(0));
    });

    test('pickMultiple with failing service returns empty', () async {
      final provider = CameraProvider(service: _FailingCameraService());
      await provider.pickMultiple();
      expect(provider.photoCount, equals(0));
    });
  });

  group('CapturedPhoto — Model Tests', () {
    test('CapturedPhoto serialization round-trip', () {
      final photo = CapturedPhoto(
        filePath: '/test/photo.jpg',
        description: 'Room measurement',
        annotations: [
          const PhotoAnnotation(x: 10, y: 20, label: '3m'),
        ],
      );
      final json = photo.toJson();
      final restored = CapturedPhoto.fromJson(json);
      expect(restored.filePath, equals('/test/photo.jpg'));
      expect(restored.description, equals('Room measurement'));
      expect(restored.annotations.length, equals(1));
    });

    test('PhotoAnnotation serialization round-trip', () {
      const ann = PhotoAnnotation(
        x: 50,
        y: 100,
        label: '4.5m',
        type: AnnotationType.area,
      );
      final json = ann.toJson();
      final restored = PhotoAnnotation.fromJson(json);
      expect(restored.x, equals(50));
      expect(restored.label, equals('4.5m'));
      expect(restored.type, equals(AnnotationType.area));
    });

    test('CapturedPhoto copyWith preserves unmodified fields', () {
      final photo = CapturedPhoto(
        filePath: '/a.jpg',
        description: 'original',
      );
      final updated = photo.copyWith(description: 'modified');
      expect(updated.filePath, equals('/a.jpg'));
      expect(updated.description, equals('modified'));
    });
  });
}

// ━━━ Mock Camera Services ━━━

int _mockCounter = 0;

class _MockCameraService extends CameraService {
  @override
  Future<CapturedPhoto?> capturePhoto({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    return CapturedPhoto(filePath: '/mock/photo_${_mockCounter++}.jpg');
  }

  @override
  Future<CapturedPhoto?> pickFromGallery({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    return CapturedPhoto(filePath: '/mock/gallery_${_mockCounter++}.jpg');
  }

  @override
  Future<List<CapturedPhoto>> pickMultiple({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    return [
      CapturedPhoto(filePath: '/mock/multi_0.jpg'),
      CapturedPhoto(filePath: '/mock/multi_1.jpg'),
      CapturedPhoto(filePath: '/mock/multi_2.jpg'),
    ];
  }
}

class _FailingCameraService extends CameraService {
  @override
  Future<CapturedPhoto?> capturePhoto({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async =>
      null;

  @override
  Future<CapturedPhoto?> pickFromGallery({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async =>
      null;

  @override
  Future<List<CapturedPhoto>> pickMultiple({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async =>
      [];
}
