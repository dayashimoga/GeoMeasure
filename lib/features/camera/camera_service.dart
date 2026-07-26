import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/logging/app_logger.dart';

/// Captured photo with measurement annotations and GPS metadata.
class CapturedPhoto {
  final String filePath;
  final DateTime capturedAt;
  final double? latitude;
  final double? longitude;
  final String? description;
  final List<PhotoAnnotation> annotations;

  CapturedPhoto({
    required this.filePath,
    DateTime? capturedAt,
    this.latitude,
    this.longitude,
    this.description,
    this.annotations = const [],
  }) : capturedAt = capturedAt ?? DateTime.now();

  CapturedPhoto copyWith({
    String? description,
    List<PhotoAnnotation>? annotations,
  }) =>
      CapturedPhoto(
        filePath: filePath,
        capturedAt: capturedAt,
        latitude: latitude,
        longitude: longitude,
        description: description ?? this.description,
        annotations: annotations ?? this.annotations,
      );

  Map<String, dynamic> toJson() => {
        'filePath': filePath,
        'capturedAt': capturedAt.toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'description': description,
        'annotations': annotations.map((a) => a.toJson()).toList(),
      };

  factory CapturedPhoto.fromJson(Map<String, dynamic> map) => CapturedPhoto(
        filePath: map['filePath'] as String,
        capturedAt: DateTime.tryParse(map['capturedAt'] as String? ?? '') ??
            DateTime.now(),
        latitude: (map['latitude'] as num?)?.toDouble(),
        longitude: (map['longitude'] as num?)?.toDouble(),
        description: map['description'] as String?,
        annotations: (map['annotations'] as List<dynamic>?)
                ?.map(
                    (a) => PhotoAnnotation.fromJson(a as Map<String, dynamic>))
                .toList() ??
            [],
      );
}

/// An annotation overlay on a photo (dimension label, marker, arrow).
class PhotoAnnotation {
  final double x;
  final double y;
  final String label;
  final AnnotationType type;

  const PhotoAnnotation({
    required this.x,
    required this.y,
    required this.label,
    this.type = AnnotationType.dimension,
  });

  Map<String, dynamic> toJson() => {
        'x': x,
        'y': y,
        'label': label,
        'type': type.name,
      };

  factory PhotoAnnotation.fromJson(Map<String, dynamic> map) =>
      PhotoAnnotation(
        x: (map['x'] as num).toDouble(),
        y: (map['y'] as num).toDouble(),
        label: map['label'] as String,
        type: AnnotationType.values.firstWhere(
          (e) => e.name == (map['type'] as String?),
          orElse: () => AnnotationType.dimension,
        ),
      );
}

enum AnnotationType { dimension, point, label, arrow, area }

/// Production camera service using image_picker package.
///
/// Handles real camera capture, gallery selection, and photo management.
class CameraService {
  final ImagePicker _picker = ImagePicker();

  /// Capture a photo using the device camera.
  Future<CapturedPhoto?> capturePhoto({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
        preferredCameraDevice: CameraDevice.rear,
      );
      if (file == null) return null;

      logger.info('Photo captured: ${file.path}', tag: 'Camera');
      return CapturedPhoto(filePath: file.path);
    } catch (e) {
      logger.error('Camera capture failed', error: e, tag: 'Camera');
      return null;
    }
  }

  /// Pick a photo from the device gallery.
  Future<CapturedPhoto?> pickFromGallery({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      if (file == null) return null;

      logger.info('Photo selected: ${file.path}', tag: 'Camera');
      return CapturedPhoto(filePath: file.path);
    } catch (e) {
      logger.error('Gallery pick failed', error: e, tag: 'Camera');
      return null;
    }
  }

  /// Pick multiple photos from the gallery.
  Future<List<CapturedPhoto>> pickMultiple({
    double maxWidth = 1920,
    double maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    try {
      final files = await _picker.pickMultiImage(
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
      );
      return files
          .map((f) => CapturedPhoto(filePath: f.path))
          .toList();
    } catch (e) {
      logger.error('Multi-pick failed', error: e, tag: 'Camera');
      return [];
    }
  }
}

/// Camera state provider with full CRUD and annotation management.
class CameraProvider extends ChangeNotifier {
  final CameraService _service;

  final List<CapturedPhoto> _photos = [];
  CapturedPhoto? _selectedPhoto;
  String? _errorMessage;

  List<CapturedPhoto> get photos => List.unmodifiable(_photos);
  CapturedPhoto? get selectedPhoto => _selectedPhoto;
  String? get errorMessage => _errorMessage;
  int get photoCount => _photos.length;

  CameraProvider({CameraService? service})
      : _service = service ?? CameraService();

  /// Capture a new photo using the device camera.
  Future<void> capturePhoto() async {
    _errorMessage = null;
    final photo = await _service.capturePhoto();
    if (photo != null) {
      _photos.add(photo);
      _selectedPhoto = photo;
      notifyListeners();
    }
  }

  /// Pick a photo from the gallery.
  Future<void> pickFromGallery() async {
    _errorMessage = null;
    final photo = await _service.pickFromGallery();
    if (photo != null) {
      _photos.add(photo);
      _selectedPhoto = photo;
      notifyListeners();
    }
  }

  /// Pick multiple photos from the gallery.
  Future<void> pickMultiple() async {
    _errorMessage = null;
    final photos = await _service.pickMultiple();
    if (photos.isNotEmpty) {
      _photos.addAll(photos);
      _selectedPhoto = photos.last;
      notifyListeners();
    }
  }

  /// Add a measurement annotation to a photo.
  void addAnnotation(int photoIndex, PhotoAnnotation annotation) {
    if (photoIndex < 0 || photoIndex >= _photos.length) return;
    final photo = _photos[photoIndex];
    _photos[photoIndex] = photo.copyWith(
      annotations: [...photo.annotations, annotation],
    );
    if (_selectedPhoto?.filePath == photo.filePath) {
      _selectedPhoto = _photos[photoIndex];
    }
    notifyListeners();
  }

  /// Update photo description.
  void updateDescription(int photoIndex, String description) {
    if (photoIndex < 0 || photoIndex >= _photos.length) return;
    _photos[photoIndex] = _photos[photoIndex].copyWith(
      description: description,
    );
    notifyListeners();
  }

  void selectPhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      _selectedPhoto = _photos[index];
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < _photos.length) {
      final removed = _photos.removeAt(index);
      if (_selectedPhoto?.filePath == removed.filePath) {
        _selectedPhoto = _photos.isNotEmpty ? _photos.last : null;
      }
      notifyListeners();
    }
  }

  void clearAll() {
    _photos.clear();
    _selectedPhoto = null;
    notifyListeners();
  }
}
