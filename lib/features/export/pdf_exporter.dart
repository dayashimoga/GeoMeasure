import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../measurement_engine/domain/entities/measurement_result.dart';
import '../measurement_engine/domain/services/unit_converter.dart';
import '../project_management/domain/entities/project.dart';

/// Generates professional PDF reports for measurements and projects.
///
/// Uses the `pdf` package for pure Dart PDF generation — works on
/// all platforms including web without native dependencies.
class PdfExporter {
  /// Generate a single measurement report.
  static Future<Uint8List> generateMeasurementReport(
    MeasurementResult result, {
    String title = 'Measurement Report',
    String? projectName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(title, projectName),
            pw.SizedBox(height: 24),
            _buildMeasurementTable(result),
            pw.SizedBox(height: 16),
            _buildMetadataSection(result),
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  /// Generate a project summary report with all measurements.
  static Future<Uint8List> generateProjectReport(Project project) async {
    final pdf = pw.Document();

    // Cover page
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader('Project Report', null),
            pw.SizedBox(height: 32),
            pw.Container(
              padding: const pw.EdgeInsets.all(20),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.blue800),
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    project.name,
                    style: const pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue900,
                    ),
                  ),
                  if (project.description != null) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      project.description!,
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                  pw.SizedBox(height: 16),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      _infoBlock('Type', project.type.name.toUpperCase()),
                      _infoBlock('Status', project.status.name.toUpperCase()),
                      _infoBlock('Measurements', '${project.measurementCount}'),
                      _infoBlock('Total Area',
                          '${project.totalArea.toStringAsFixed(2)} m²'),
                    ],
                  ),
                ],
              ),
            ),
            if (project.tags.isNotEmpty) ...[
              pw.SizedBox(height: 16),
              pw.Wrap(
                spacing: 8,
                children: project.tags
                    .map((t) => pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                          child: pw.Text(t,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.blue800)),
                        ))
                    .toList(),
              ),
            ],
            pw.SizedBox(height: 24),
            pw.Text(
              'Measurement Details',
              style: const pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 12),
            // Measurement table
            if (project.measurements.isNotEmpty)
              pw.TableHelper.fromTextArray(
                headerStyle: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellStyle: const pw.TextStyle(fontSize: 9),
                cellPadding: const pw.EdgeInsets.all(6),
                headers: [
                  '#',
                  'Shape',
                  'Area',
                  'Perimeter',
                  'Algorithm',
                  'Accuracy'
                ],
                data: project.measurements.asMap().entries.map((entry) {
                  final i = entry.key;
                  final m = entry.value;
                  return [
                    '${i + 1}',
                    m.shapeName.isNotEmpty ? m.shapeName : m.shapeType.name,
                    '${m.area.toStringAsFixed(2)} ${UnitConverter.areaUnitLabel(m.areaUnit)}',
                    '${m.perimeter.toStringAsFixed(2)} ${UnitConverter.distanceUnitLabel(m.distanceUnit)}',
                    m.algorithmUsed.displayName,
                    '${m.estimatedAccuracyPercentage.toStringAsFixed(0)}%',
                  ];
                }).toList(),
              ),
            pw.Spacer(),
            _buildFooter(),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(String title, String? subtitle) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'GeoMeasure',
                  style: const pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue800,
                  ),
                ),
                pw.Text(
                  title,
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  DateTime.now().toString().substring(0, 16),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
                if (subtitle != null)
                  pw.Text(
                    subtitle,
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey500,
                    ),
                  ),
              ],
            ),
          ],
        ),
        pw.Divider(color: PdfColors.blue200, thickness: 2),
      ],
    );
  }

  static pw.Widget _buildMeasurementTable(MeasurementResult result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _metricRow('Area',
              '${result.area.toStringAsFixed(4)} ${UnitConverter.areaUnitLabel(result.areaUnit)}'),
          _metricRow('Perimeter',
              '${result.perimeter.toStringAsFixed(4)} ${UnitConverter.distanceUnitLabel(result.distanceUnit)}'),
          if (result.volume > 0)
            _metricRow('Volume', '${result.volume.toStringAsFixed(4)} m³'),
          _metricRow('Algorithm', result.algorithmUsed.displayName),
          _metricRow('Accuracy',
              '${result.estimatedAccuracyPercentage.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }

  static pw.Widget _metricRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: const pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 11,
                  color: PdfColors.grey800)),
          pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  static pw.Widget _metadataSection(MeasurementResult result) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Metadata',
              style:
                  const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
          pw.SizedBox(height: 4),
          pw.Text('Shape: ${result.shapeType.name}',
              style: const pw.TextStyle(fontSize: 9)),
          pw.Text('Timestamp: ${result.timestamp.toIso8601String()}',
              style: const pw.TextStyle(fontSize: 9)),
          if (result.shapeName.isNotEmpty)
            pw.Text('Name: ${result.shapeName}',
                style: const pw.TextStyle(fontSize: 9)),
        ],
      ),
    );
  }

  static pw.Widget _buildMetadataSection(MeasurementResult result) =>
      _metadataSection(result);

  static pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey300),
        pw.SizedBox(height: 4),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated by GeoMeasure v1.4.0',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
            pw.Text(
              'www.geomeasure.app',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _infoBlock(String label, String value) {
    return pw.Column(
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        pw.SizedBox(height: 2),
        pw.Text(value,
            style: const pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }
}
