import '../../features/measurement_engine/domain/entities/measurement_result.dart';
import '../../features/measurement_engine/domain/services/dxf_exporter.dart';
import '../../features/measurement_engine/domain/services/csv_exporter.dart';
import '../../features/measurement_engine/domain/services/geojson_exporter.dart';
import '../../features/measurement_engine/domain/services/svg_exporter.dart';
import '../../features/measurement_engine/domain/services/kml_exporter.dart';
import '../../features/measurement_engine/domain/entities/spatial_shape.dart';
import 'json_exporter.dart';

/// Unified export manager that handles all export formats.
///
/// Provides a single interface for exporting measurements
/// in DXF, CSV, GeoJSON, SVG, KML, PDF, JSON, and Excel formats.
enum ExportFormat {
  dxf,
  csv,
  geoJson,
  svg,
  kml,
  pdf,
  json,
  excel,
}

class ExportManager {
  /// Generate export content as a string for the given format.
  static String exportToString({
    required ExportFormat format,
    SpatialShape? shape,
    List<MeasurementResult>? history,
  }) {
    switch (format) {
      case ExportFormat.dxf:
        if (shape == null) return '';
        return DxfExporter.generateDxf(shape);

      case ExportFormat.csv:
        return CsvExporter.generateCsv(history ?? []);

      case ExportFormat.geoJson:
        if (shape is PlotShape) {
          return GeoJsonExporter.generateGeoJson(shape);
        }
        return '';

      case ExportFormat.svg:
        if (shape == null) return '';
        return SvgExporter.generateSvg(shape);

      case ExportFormat.kml:
        if (shape is PlotShape) {
          return KmlExporter.generateKml(shape);
        }
        return '';

      case ExportFormat.pdf:
        // PDF uses byte generation, not string — use PdfExporter directly
        return '[PDF export requires PdfExporter.generateMeasurementReport()]';

      case ExportFormat.json:
        return JsonExporter.exportHistory(history ?? []);

      case ExportFormat.excel:
        // Excel uses byte generation — use ExcelExporter directly
        return '[Excel export requires ExcelExporter.exportMeasurements()]';
    }
  }

  /// Get the file extension for a format.
  static String fileExtension(ExportFormat format) {
    switch (format) {
      case ExportFormat.dxf:
        return '.dxf';
      case ExportFormat.csv:
        return '.csv';
      case ExportFormat.geoJson:
        return '.geojson';
      case ExportFormat.svg:
        return '.svg';
      case ExportFormat.kml:
        return '.kml';
      case ExportFormat.pdf:
        return '.pdf';
      case ExportFormat.json:
        return '.json';
      case ExportFormat.excel:
        return '.xlsx';
    }
  }

  /// Get the MIME type for a format.
  static String mimeType(ExportFormat format) {
    switch (format) {
      case ExportFormat.dxf:
        return 'application/dxf';
      case ExportFormat.csv:
        return 'text/csv';
      case ExportFormat.geoJson:
        return 'application/geo+json';
      case ExportFormat.svg:
        return 'image/svg+xml';
      case ExportFormat.kml:
        return 'application/vnd.google-earth.kml+xml';
      case ExportFormat.pdf:
        return 'application/pdf';
      case ExportFormat.json:
        return 'application/json';
      case ExportFormat.excel:
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
  }

  /// Human-readable format name.
  static String formatDisplayName(ExportFormat format) {
    switch (format) {
      case ExportFormat.dxf:
        return 'AutoCAD DXF';
      case ExportFormat.csv:
        return 'CSV Schedule';
      case ExportFormat.geoJson:
        return 'GeoJSON';
      case ExportFormat.svg:
        return 'SVG Drawing';
      case ExportFormat.kml:
        return 'Google Earth KML';
      case ExportFormat.pdf:
        return 'PDF Report';
      case ExportFormat.json:
        return 'JSON Data';
      case ExportFormat.excel:
        return 'Excel Spreadsheet';
    }
  }

  /// Get list of supported formats for a given shape type.
  static List<ExportFormat> supportedFormats(SpatialShape? shape) {
    final formats = <ExportFormat>[ExportFormat.csv, ExportFormat.json, ExportFormat.excel];
    if (shape != null) {
      formats.addAll([ExportFormat.dxf, ExportFormat.svg, ExportFormat.pdf]);
      if (shape is PlotShape) {
        formats.addAll([ExportFormat.geoJson, ExportFormat.kml]);
      }
    }
    return formats;
  }
}
