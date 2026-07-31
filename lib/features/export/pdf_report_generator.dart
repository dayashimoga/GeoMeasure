import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../measurement_engine/domain/entities/measurement_result.dart';
import '../measurement_engine/domain/services/unit_converter.dart';
import '../estimation/domain/entities/material_estimate.dart';
import '../ai_vision/domain/entities/building_analysis.dart';

/// Report type templates for extended PDF generation.
enum ReportType {
  measurement,
  construction,
  inspection,
  property,
  inventory,
  materialEstimate,
}

/// Extended PDF report generator with multiple professional templates.
class PdfReportGenerator {
  static const _version = 'v2.1.0';

  // ── Construction Report ──────────────────────────────────────

  /// Generate a construction site report with materials and costs.
  static Future<Uint8List> generateConstructionReport({
    required List<MeasurementResult> measurements,
    required QuantityTakeoff takeoff,
    CostEstimate? costEstimate,
    String siteName = 'Construction Site',
    String? siteAddress,
    String? contractorName,
    String? engineerName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _header('Construction Report', siteName),
      footer: (ctx) => _footer(ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        // Site info
        _sectionTitle('Site Information'),
        _keyValue('Site Name', siteName),
        if (siteAddress != null) _keyValue('Address', siteAddress),
        if (contractorName != null) _keyValue('Contractor', contractorName),
        if (engineerName != null) _keyValue('Engineer', engineerName),
        _keyValue('Date', DateTime.now().toString().substring(0, 10)),
        pw.SizedBox(height: 16),

        // Measurements summary
        _sectionTitle('Site Measurements'),
        _measurementSummaryTable(measurements),
        pw.SizedBox(height: 16),

        // Materials
        _sectionTitle('Bill of Quantities'),
        _takeoffTable(takeoff),
        pw.SizedBox(height: 16),

        // Cost summary
        if (costEstimate != null) ...[
          _sectionTitle('Cost Estimate'),
          _costSummaryTable(costEstimate),
        ],

        pw.SizedBox(height: 24),
        _signatureBlock(
          left: 'Contractor',
          right: 'Site Engineer',
        ),
      ],
    ));

    return pdf.save();
  }

  // ── Inspection Report ────────────────────────────────────────

  /// Generate a property inspection report.
  static Future<Uint8List> generateInspectionReport({
    required List<MeasurementResult> measurements,
    required String propertyAddress,
    BuildingAnalysis? buildingAnalysis,
    String inspectorName = '',
    String? licenseNumber,
    List<String> findings = const [],
    List<String> recommendations = const [],
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _header('Property Inspection Report', propertyAddress),
      footer: (ctx) => _footer(ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        _sectionTitle('Property Details'),
        _keyValue('Address', propertyAddress),
        _keyValue('Inspector', inspectorName),
        if (licenseNumber != null) _keyValue('License #', licenseNumber),
        _keyValue(
            'Inspection Date', DateTime.now().toString().substring(0, 10)),
        pw.SizedBox(height: 16),

        // Building analysis
        if (buildingAnalysis != null) ...[
          _sectionTitle('Building Analysis'),
          _buildingAnalysisTable(buildingAnalysis),
          pw.SizedBox(height: 16),
        ],

        // Measurements
        _sectionTitle('Dimensional Survey'),
        _measurementSummaryTable(measurements),
        pw.SizedBox(height: 16),

        // Findings
        if (findings.isNotEmpty) ...[
          _sectionTitle('Findings'),
          ...findings.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${e.key + 1}. ',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Expanded(
                        child: pw.Text(e.value,
                            style: const pw.TextStyle(fontSize: 10))),
                  ],
                ),
              )),
          pw.SizedBox(height: 16),
        ],

        // Recommendations
        if (recommendations.isNotEmpty) ...[
          _sectionTitle('Recommendations'),
          ...recommendations.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${e.key + 1}. ',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.Expanded(
                        child: pw.Text(e.value,
                            style: const pw.TextStyle(fontSize: 10))),
                  ],
                ),
              )),
        ],

        pw.SizedBox(height: 24),
        _signatureBlock(left: 'Inspector', right: 'Property Owner'),
      ],
    ));

    return pdf.save();
  }

  // ── Property Valuation Report ────────────────────────────────

  /// Generate a property valuation / real estate report.
  static Future<Uint8List> generatePropertyReport({
    required List<MeasurementResult> measurements,
    required String propertyAddress,
    BuildingAnalysis? buildingAnalysis,
    double? plotAreaSqm,
    double? builtUpAreaSqm,
    double? estimatedValuePerSqm,
    String? zoning,
    int? yearBuilt,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _header('Property Report', propertyAddress),
      footer: (ctx) => _footer(ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        _sectionTitle('Property Summary'),
        _keyValue('Address', propertyAddress),
        if (plotAreaSqm != null)
          _keyValue('Plot Area', '${plotAreaSqm.toStringAsFixed(2)} m²'),
        if (builtUpAreaSqm != null)
          _keyValue('Built-Up Area', '${builtUpAreaSqm.toStringAsFixed(2)} m²'),
        if (zoning != null) _keyValue('Zoning', zoning),
        if (yearBuilt != null) _keyValue('Year Built', '$yearBuilt'),
        if (estimatedValuePerSqm != null && builtUpAreaSqm != null)
          _keyValue('Estimated Value',
              '₹ ${(estimatedValuePerSqm * builtUpAreaSqm).toStringAsFixed(0)}'),
        pw.SizedBox(height: 16),
        if (buildingAnalysis != null) ...[
          _sectionTitle('Building Details'),
          _buildingAnalysisTable(buildingAnalysis),
          pw.SizedBox(height: 16),
        ],
        _sectionTitle('Room-wise Measurements'),
        _measurementSummaryTable(measurements),
        pw.SizedBox(height: 24),
        _signatureBlock(left: 'Surveyor', right: 'Property Owner'),
      ],
    ));

    return pdf.save();
  }

  // ── Inventory Report ─────────────────────────────────────────

  /// Generate an inventory / object counting report.
  static Future<Uint8List> generateInventoryReport({
    required Map<String, int> objectCounts,
    required String locationName,
    List<MeasurementResult>? measurements,
    String? operatorName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _header('Inventory Report', locationName),
      footer: (ctx) => _footer(ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        _sectionTitle('Location Details'),
        _keyValue('Location', locationName),
        if (operatorName != null) _keyValue('Operator', operatorName),
        _keyValue('Date', DateTime.now().toString().substring(0, 10)),
        _keyValue('Total Items',
            '${objectCounts.values.fold<int>(0, (s, v) => s + v)}'),
        pw.SizedBox(height: 16),
        _sectionTitle('Object Counts'),
        pw.TableHelper.fromTextArray(
          headerStyle: const pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
              color: PdfColors.white),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.all(6),
          headers: ['Object Type', 'Count'],
          data: objectCounts.entries.map((e) => [e.key, '${e.value}']).toList(),
        ),
        if (measurements != null && measurements.isNotEmpty) ...[
          pw.SizedBox(height: 16),
          _sectionTitle('Associated Measurements'),
          _measurementSummaryTable(measurements),
        ],
      ],
    ));

    return pdf.save();
  }

  // ── Material Estimate Report ─────────────────────────────────

  /// Generate a material estimation report with BOQ and costing.
  static Future<Uint8List> generateMaterialEstimateReport({
    required QuantityTakeoff takeoff,
    CostEstimate? costEstimate,
    String projectName = 'Material Estimate',
    List<MeasurementResult>? measurements,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(40),
      header: (ctx) => _header('Material Estimation Report', projectName),
      footer: (ctx) => _footer(ctx.pageNumber, ctx.pagesCount),
      build: (ctx) => [
        _sectionTitle('Project Information'),
        _keyValue('Project', projectName),
        _keyValue('Date', DateTime.now().toString().substring(0, 10)),
        _keyValue('Line Items', '${takeoff.items.length}'),
        pw.SizedBox(height: 16),
        _sectionTitle('Bill of Quantities'),
        _takeoffTable(takeoff),
        pw.SizedBox(height: 16),
        if (costEstimate != null) ...[
          _sectionTitle('Cost Breakdown'),
          _costSummaryTable(costEstimate),
          pw.SizedBox(height: 16),
        ],
        if (measurements != null && measurements.isNotEmpty) ...[
          _sectionTitle('Source Measurements'),
          _measurementSummaryTable(measurements),
        ],
        pw.SizedBox(height: 24),
        _signatureBlock(left: 'Quantity Surveyor', right: 'Approved By'),
      ],
    ));

    return pdf.save();
  }

  // ── Shared components ────────────────────────────────────────

  static pw.Widget _header(String title, String subtitle) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('GeoMeasure',
              style: const pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800)),
          pw.Text(DateTime.now().toString().substring(0, 16),
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
        ],
      ),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title,
              style:
                  const pw.TextStyle(fontSize: 14, color: PdfColors.grey600)),
          pw.Text(subtitle,
              style:
                  const pw.TextStyle(fontSize: 10, color: PdfColors.grey500)),
        ],
      ),
      pw.Divider(color: PdfColors.blue200, thickness: 2),
      pw.SizedBox(height: 8),
    ]);
  }

  static pw.Widget _footer(int page, int total) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by GeoMeasure $_version',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          pw.Text('Page $page of $total',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
        ],
      ),
    ]);
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8, top: 4),
      child: pw.Text(title,
          style: const pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900)),
    );
  }

  static pw.Widget _keyValue(String key, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(children: [
        pw.SizedBox(
            width: 140,
            child: pw.Text(key,
                style: const pw.TextStyle(
                    fontSize: 10, color: PdfColors.grey700))),
        pw.Expanded(
            child: pw.Text(value,
                style: const pw.TextStyle(
                    fontSize: 10, fontWeight: pw.FontWeight.bold))),
      ]),
    );
  }

  static pw.Widget _measurementSummaryTable(List<MeasurementResult> results) {
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.all(5),
      headers: ['#', 'Shape', 'Area', 'Perimeter', 'Volume', 'Accuracy'],
      data: results.asMap().entries.map((e) {
        final r = e.value;
        return [
          '${e.key + 1}',
          r.shapeName.isNotEmpty ? r.shapeName : r.shapeType.name,
          '${r.area.toStringAsFixed(2)} ${UnitConverter.areaUnitLabel(r.areaUnit)}',
          '${r.perimeter.toStringAsFixed(2)} ${UnitConverter.distanceUnitLabel(r.distanceUnit)}',
          r.volume > 0 ? '${r.volume.toStringAsFixed(2)} m³' : '-',
          '${r.estimatedAccuracyPercentage.toStringAsFixed(0)}%',
        ];
      }).toList(),
    );
  }

  static pw.Widget _takeoffTable(QuantityTakeoff takeoff) {
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(
          fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green800),
      cellStyle: const pw.TextStyle(fontSize: 9),
      cellPadding: const pw.EdgeInsets.all(5),
      headers: [
        'Material',
        'Quantity',
        'Unit',
        'Wastage',
        'Adjusted',
        'Unit Cost',
        'Total'
      ],
      data: takeoff.items.map((item) {
        return [
          item.material.name,
          item.quantity.toStringAsFixed(2),
          item.unit.name,
          '${item.wastagePercent.toStringAsFixed(0)}%',
          item.adjustedQuantity.toStringAsFixed(2),
          item.unitCost > 0 ? item.unitCost.toStringAsFixed(0) : '-',
          item.totalCost > 0 ? item.totalCost.toStringAsFixed(0) : '-',
        ];
      }).toList(),
    );
  }

  static pw.Widget _costSummaryTable(CostEstimate estimate) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        _costRow('Material Cost', estimate.materialCost),
        _costRow('Labor Cost', estimate.laborCost),
        pw.Divider(color: PdfColors.grey200),
        _costRow('Subtotal', estimate.subtotal),
        _costRow('Overhead (${estimate.overheadPercent}%)', estimate.overhead),
        _costRow('Contingency (${estimate.contingencyPercent}%)',
            estimate.contingency),
        _costRow('Profit (${estimate.profitPercent}%)', estimate.profit),
        pw.Divider(color: PdfColors.blue800, thickness: 2),
        _costRow('Grand Total', estimate.grandTotal, bold: true),
      ]),
    );
  }

  static pw.Widget _costRow(String label, double amount, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text('₹ ${amount.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  static pw.Widget _buildingAnalysisTable(BuildingAnalysis analysis) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(children: [
        _keyValue('Dimensions',
            '${analysis.lengthMeters.toStringAsFixed(1)} × ${analysis.widthMeters.toStringAsFixed(1)} × ${analysis.heightMeters.toStringAsFixed(1)} m'),
        _keyValue('Floors', '${analysis.numberOfFloors}'),
        _keyValue('Roof Type', analysis.roofType.name),
        _keyValue(
            'Footprint', '${analysis.footprintAreaSqm.toStringAsFixed(2)} m²'),
        _keyValue('Total Floor Area',
            '${analysis.totalFloorAreaSqm.toStringAsFixed(2)} m²'),
        if (analysis.floorAreaRatio > 0)
          _keyValue('FAR', analysis.floorAreaRatio.toStringAsFixed(2)),
        if (analysis.windowCount > 0)
          _keyValue('Windows', '${analysis.windowCount}'),
        if (analysis.doorCount > 0) _keyValue('Doors', '${analysis.doorCount}'),
      ]),
    );
  }

  static pw.Widget _signatureBlock(
      {required String left, required String right}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        _signatureLine(left),
        _signatureLine(right),
      ],
    );
  }

  static pw.Widget _signatureLine(String label) {
    return pw.Column(children: [
      pw.Container(
        width: 150,
        decoration: const pw.BoxDecoration(
          border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey500, width: 1)),
        ),
        height: 40,
      ),
      pw.SizedBox(height: 4),
      pw.Text(label,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
    ]);
  }
}
