import 'package:flutter/material.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../camera/camera_service.dart';
import '../../capability_detection/domain/entities/capability_profile.dart';
import '../../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../../measurement_engine/domain/entities/spatial_shape.dart';

/// Camera-first measurement page.
///
/// Captures photo → annotate dimensions → calculate measurement.
class CameraMeasurementPage extends StatefulWidget {
  final CapabilityProfile profile;

  const CameraMeasurementPage({super.key, required this.profile});

  @override
  State<CameraMeasurementPage> createState() => _CameraMeasurementPageState();
}

class _CameraMeasurementPageState extends State<CameraMeasurementPage> {
  final CameraProvider _cameraProvider = CameraProvider();
  bool _showDimensionOverlay = false;
  final _lengthCtrl = TextEditingController(text: '3.0');
  final _widthCtrl = TextEditingController(text: '2.5');

  @override
  void dispose() {
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    super.dispose();
  }

  /// Get selected photo index from the provider's selectedPhoto.
  int get _selectedIndex {
    final sel = _cameraProvider.selectedPhoto;
    if (sel == null) return 0;
    final idx = _cameraProvider.photos.indexWhere(
        (p) => p.filePath == sel.filePath);
    return idx >= 0 ? idx : 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final algoColor = AppTheme.algorithmColor(
        widget.profile.bestAlgorithm.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Camera Measure'),
        actions: [
          IconButton(
            icon: const Icon(Icons.photo_library_rounded),
            onPressed: () => _cameraProvider.pickFromGallery(),
            tooltip: 'Pick from Gallery',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _cameraProvider,
        builder: (context, _) {
          final photos = _cameraProvider.photos;

          if (photos.isEmpty) {
            return _buildEmptyState(theme, algoColor);
          }

          final selected = _selectedIndex;
          return Column(
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      color: theme.colorScheme.surfaceContainerLowest,
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.image_rounded,
                                size: 80, color: theme.colorScheme.outline),
                            const SizedBox(height: 8),
                            Text(
                              photos[selected].filePath.split('/').last,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            if (photos[selected].latitude != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  '\u{1F4CD} ${photos[selected].latitude!.toStringAsFixed(4)}, '
                                  '${photos[selected].longitude!.toStringAsFixed(4)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.colorScheme.onSurface
                                        .withValues(alpha: 0.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_showDimensionOverlay)
                      _buildDimensionOverlay(theme, algoColor),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface
                              .withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: algoColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.straighten_rounded,
                                size: 14, color: algoColor),
                            const SizedBox(width: 4),
                            Text(
                              '${photos[selected].annotations.length} annotations',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: algoColor),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _buildControls(theme),
              if (photos.length > 1)
                _buildPhotoStrip(theme, photos, selected),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _cameraProvider.capturePhoto(),
        icon: const Icon(Icons.camera_alt_rounded),
        label: const Text('Capture'),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, Color algoColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    algoColor.withValues(alpha: 0.15),
                    algoColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt_rounded,
                  size: 64, color: algoColor),
            ),
            const SizedBox(height: 24),
            Text(
              'Camera Measurement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Capture a photo of the surface to measure.\n'
              'Add dimension annotations, then calculate.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _cameraProvider.capturePhoto(),
                  icon: const Icon(Icons.camera_alt_rounded),
                  label: const Text('Take Photo'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () => _cameraProvider.pickFromGallery(),
                  icon: const Icon(Icons.photo_library_rounded),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: algoColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sensors_rounded, size: 16, color: algoColor),
                  const SizedBox(width: 6),
                  Text(
                    'Engine: ${widget.profile.bestAlgorithm.displayName}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: algoColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionOverlay(ThemeData theme, Color algoColor) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.3),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.straighten_rounded, color: algoColor),
                      const SizedBox(width: 8),
                      Text(
                        'Enter Dimensions',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _lengthCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Length (m)',
                      prefixIcon: Icon(Icons.straighten_rounded, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _widthCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Width (m)',
                      prefixIcon: Icon(Icons.straighten_rounded, size: 20),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () =>
                            setState(() => _showDimensionOverlay = false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        icon: const Icon(Icons.calculate_rounded, size: 18),
                        label: const Text('Calculate'),
                        onPressed: () {
                          final l = double.tryParse(_lengthCtrl.text) ?? 3.0;
                          final w = double.tryParse(_widthCtrl.text) ?? 2.5;
                          _addAnnotationAndMeasure(l, w);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildControls(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () =>
                setState(() => _showDimensionOverlay = true),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add Dimension'),
          ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _cameraProvider.photos.isNotEmpty
                ? () => _cameraProvider.removePhoto(_selectedIndex)
                : null,
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            label: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoStrip(
      ThemeData theme, List<CapturedPhoto> photos, int selected) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: photos.length,
        itemBuilder: (ctx, i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => _cameraProvider.selectPhoto(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: theme.colorScheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Icon(
                  Icons.image_rounded,
                  size: 24,
                  color: isSelected
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.outline,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _addAnnotationAndMeasure(double length, double width) {
    setState(() => _showDimensionOverlay = false);

    final idx = _selectedIndex;
    _cameraProvider.addAnnotation(
      idx,
      PhotoAnnotation(
        label: '${length}m \u00D7 ${width}m',
        x: 0.5,
        y: 0.5,
        type: AnnotationType.dimension,
      ),
    );

    final shape = RectangleShape(
      lengthMeters: length,
      widthMeters: width,
    );
    sl.measurementProvider.calculateMeasurement(
      shape: shape,
      profile: widget.profile,
      shapeName: 'Camera: ${length}m \u00D7 ${width}m',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Area: ${(length * width).toStringAsFixed(2)} m\u00B2 \u2022 '
            'Perimeter: ${((length + width) * 2).toStringAsFixed(2)} m',
          ),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }
  }
}
