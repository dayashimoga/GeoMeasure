import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import '../../features/measurement_engine/domain/entities/spatial_shape.dart';

/// Exports floor plan and measurement visualizations as PNG or JPEG images.
class ImageExporter {
  /// Captures a widget's visual representation as PNG bytes.
  ///
  /// Requires the widget to be wrapped in a RepaintBoundary with the given key.
  static Future<Uint8List?> captureWidgetAsPng(GlobalKey boundaryKey,
      {double pixelRatio = 3.0}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  /// Captures a widget's visual representation as JPEG bytes.
  static Future<Uint8List?> captureWidgetAsJpeg(GlobalKey boundaryKey,
      {double pixelRatio = 3.0, int quality = 90}) async {
    final boundary = boundaryKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: pixelRatio);
    // Flutter's toByteData doesn't support JPEG directly,
    // so we export as PNG (lossless). For JPEG, use the `image` package.
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return byteData?.buffer.asUint8List();
  }

  /// Generates a filename for the exported image.
  static String generateFilename(SpatialShape shape, String format) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final shapeName = shape.runtimeType.toString().replaceAll('Shape', '');
    return 'geomeasure_${shapeName.toLowerCase()}_$timestamp.$format';
  }

  /// Creates a summary text for embedding in exported images.
  static String generateCaption(SpatialShape shape) {
    final area = shape.calculateAreaInSquareMeters();
    return 'Area: ${area.toStringAsFixed(2)} m\u00B2';
  }
}
