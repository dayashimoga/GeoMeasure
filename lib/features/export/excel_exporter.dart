import 'dart:typed_data';
import 'dart:convert';
import '../measurement_engine/domain/entities/measurement_result.dart';
import '../measurement_engine/domain/entities/measurement_algorithm.dart';
import '../measurement_engine/domain/services/unit_converter.dart';
import '../estimation/domain/entities/material_estimate.dart';

/// Excel exporter — generates XLSX files as bytes.
///
/// Uses a minimal XML-based Open XML (XLSX) generator.
/// No external package required — pure Dart implementation.
class ExcelExporter {
  /// Export measurement history as XLSX bytes.
  static Uint8List exportMeasurements(List<MeasurementResult> results,
      {String sheetName = 'Measurements'}) {
    final rows = <List<String>>[
      // Header row
      [
        '#',
        'Shape Type',
        'Name',
        'Area',
        'Area Unit',
        'Perimeter',
        'Distance Unit',
        'Volume (m³)',
        'Wall Area (m²)',
        'Floor Area (m²)',
        'Surface Area (m²)',
        'Algorithm',
        'Accuracy (%)',
        'Confidence',
        'Sensor',
        'Precision Mode',
        'Timestamp',
      ],
    ];

    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      rows.add([
        '${i + 1}',
        r.shapeType.name,
        r.shapeName,
        r.area.toStringAsFixed(4),
        UnitConverter.areaUnitLabel(r.areaUnit),
        r.perimeter.toStringAsFixed(4),
        UnitConverter.distanceUnitLabel(r.distanceUnit),
        r.volume.toStringAsFixed(4),
        r.wallArea.toStringAsFixed(2),
        r.floorArea.toStringAsFixed(2),
        r.surfaceArea.toStringAsFixed(2),
        r.algorithmUsed.displayName,
        r.estimatedAccuracyPercentage.toStringAsFixed(1),
        r.confidenceScore.toStringAsFixed(2),
        r.sensorUsed,
        r.precisionMode.name,
        r.timestamp.toIso8601String(),
      ]);
    }

    return _generateXlsx(sheetName, rows);
  }

  /// Export a quantity takeoff as XLSX bytes.
  static Uint8List exportTakeoff(QuantityTakeoff takeoff,
      {String sheetName = 'Quantity Takeoff'}) {
    final rows = <List<String>>[
      [
        'Material',
        'Quantity',
        'Unit',
        'Wastage %',
        'Adjusted Qty',
        'Unit Cost',
        'Total Cost'
      ],
    ];

    for (final item in takeoff.items) {
      rows.add([
        item.material.name,
        item.quantity.toStringAsFixed(2),
        item.unit.name,
        item.wastagePercent.toStringAsFixed(1),
        item.adjustedQuantity.toStringAsFixed(2),
        item.unitCost.toStringAsFixed(2),
        item.totalCost.toStringAsFixed(2),
      ]);
    }

    // Summary row
    rows.add([]);
    rows.add([
      'Total Cost',
      '',
      '',
      '',
      '',
      '',
      takeoff.totalCost.toStringAsFixed(2)
    ]);

    return _generateXlsx(sheetName, rows);
  }

  /// Export a cost estimate as XLSX bytes.
  static Uint8List exportCostEstimate(CostEstimate estimate,
      {String sheetName = 'Cost Estimate'}) {
    final rows = <List<String>>[
      ['Category', 'Amount'],
      ['Material Cost', estimate.materialCost.toStringAsFixed(2)],
      ['Labor Cost', estimate.laborCost.toStringAsFixed(2)],
      ['Subtotal', estimate.subtotal.toStringAsFixed(2)],
      [
        'Overhead (${estimate.overheadPercent}%)',
        estimate.overhead.toStringAsFixed(2)
      ],
      [
        'Contingency (${estimate.contingencyPercent}%)',
        estimate.contingency.toStringAsFixed(2)
      ],
      [
        'Profit (${estimate.profitPercent}%)',
        estimate.profit.toStringAsFixed(2)
      ],
      [],
      ['Grand Total', estimate.grandTotal.toStringAsFixed(2)],
    ];

    return _generateXlsx(sheetName, rows);
  }

  /// Generate a minimal valid XLSX file (ZIP of XML parts).
  ///
  /// XLSX = ZIP archive with:
  ///  - [Content_Types].xml
  ///  - _rels/.rels
  ///  - xl/workbook.xml
  ///  - xl/_rels/workbook.xml.rels
  ///  - xl/worksheets/sheet1.xml
  ///  - xl/styles.xml
  ///  - xl/sharedStrings.xml
  static Uint8List _generateXlsx(String sheetName, List<List<String>> rows) {
    // Collect all unique strings for shared strings table
    final allStrings = <String>[];
    final stringIndex = <String, int>{};
    for (final row in rows) {
      for (final cell in row) {
        if (!stringIndex.containsKey(cell)) {
          stringIndex[cell] = allStrings.length;
          allStrings.add(cell);
        }
      }
    }

    // Build sheet XML
    final sheetXml = StringBuffer();
    sheetXml.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sheetXml.writeln(
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    sheetXml.writeln('<sheetData>');
    for (int r = 0; r < rows.length; r++) {
      sheetXml.write('<row r="${r + 1}">');
      for (int c = 0; c < rows[r].length; c++) {
        final cellRef = '${_columnLetter(c)}${r + 1}';
        final value = rows[r][c];
        final numVal = double.tryParse(value);
        if (numVal != null && value.isNotEmpty) {
          // Numeric cell
          final style = r == 0 ? ' s="1"' : '';
          sheetXml.write('<c r="$cellRef"$style><v>$numVal</v></c>');
        } else {
          // String cell (reference shared strings)
          final idx = stringIndex[value] ?? 0;
          final style = r == 0 ? ' s="1"' : '';
          sheetXml.write('<c r="$cellRef" t="s"$style><v>$idx</v></c>');
        }
      }
      sheetXml.writeln('</row>');
    }
    sheetXml.writeln('</sheetData>');
    sheetXml.writeln('</worksheet>');

    // Shared strings XML
    final ssXml = StringBuffer();
    ssXml.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    ssXml.writeln(
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${allStrings.length}" uniqueCount="${allStrings.length}">');
    for (final s in allStrings) {
      ssXml.writeln('<si><t>${_xmlEscape(s)}</t></si>');
    }
    ssXml.writeln('</sst>');

    // Styles XML (bold header)
    const stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2">
<font><sz val="11"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><name val="Calibri"/></font>
</fonts>
<fills count="2"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill></fills>
<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>
<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
<cellXfs count="2">
<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>
</cellXfs>
</styleSheet>''';

    // Workbook XML
    final wbXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="${_xmlEscape(sheetName)}" sheetId="1" r:id="rId1"/></sheets>
</workbook>''';

    // Relationships
    const relsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

    const wbRelsXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
</Relationships>''';

    const contentTypesXml =
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>''';

    // Build ZIP archive
    final files = <String, String>{
      '[Content_Types].xml': contentTypesXml,
      '_rels/.rels': relsXml,
      'xl/workbook.xml': wbXml,
      'xl/_rels/workbook.xml.rels': wbRelsXml,
      'xl/worksheets/sheet1.xml': sheetXml.toString(),
      'xl/styles.xml': stylesXml,
      'xl/sharedStrings.xml': ssXml.toString(),
    };

    return _buildZip(files);
  }

  static String _columnLetter(int col) {
    String result = '';
    int c = col;
    while (c >= 0) {
      result = String.fromCharCode(65 + (c % 26)) + result;
      c = (c ~/ 26) - 1;
    }
    return result;
  }

  static String _xmlEscape(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// Build a minimal ZIP archive from a map of filename → content.
  ///
  /// Implements ZIP format (PKZIP APPNOTE) with STORE method (no compression)
  /// for maximum compatibility and simplicity.
  static Uint8List _buildZip(Map<String, String> files) {
    final buffer = BytesBuilder();
    final centralDir = BytesBuilder();
    final offsets = <int>[];

    for (final entry in files.entries) {
      final nameBytes = utf8.encode(entry.key);
      final dataBytes = utf8.encode(entry.value);
      final crc = _crc32(dataBytes);

      offsets.add(buffer.length);

      // Local file header
      buffer.add(_u32le(0x04034b50)); // signature
      buffer.add(_u16le(20)); // version needed
      buffer.add(_u16le(0)); // flags
      buffer.add(_u16le(0)); // compression (STORE)
      buffer.add(_u16le(0)); // mod time
      buffer.add(_u16le(0)); // mod date
      buffer.add(_u32le(crc));
      buffer.add(_u32le(dataBytes.length)); // compressed size
      buffer.add(_u32le(dataBytes.length)); // uncompressed size
      buffer.add(_u16le(nameBytes.length)); // name length
      buffer.add(_u16le(0)); // extra length
      buffer.add(nameBytes);
      buffer.add(dataBytes);

      // Central directory entry
      centralDir.add(_u32le(0x02014b50)); // signature
      centralDir.add(_u16le(20)); // version made by
      centralDir.add(_u16le(20)); // version needed
      centralDir.add(_u16le(0)); // flags
      centralDir.add(_u16le(0)); // compression
      centralDir.add(_u16le(0)); // mod time
      centralDir.add(_u16le(0)); // mod date
      centralDir.add(_u32le(crc));
      centralDir.add(_u32le(dataBytes.length));
      centralDir.add(_u32le(dataBytes.length));
      centralDir.add(_u16le(nameBytes.length));
      centralDir.add(_u16le(0)); // extra length
      centralDir.add(_u16le(0)); // comment length
      centralDir.add(_u16le(0)); // disk number start
      centralDir.add(_u16le(0)); // internal attrs
      centralDir.add(_u32le(0)); // external attrs
      centralDir.add(_u32le(offsets.last)); // relative offset
      centralDir.add(nameBytes);
    }

    final centralDirOffset = buffer.length;
    final centralDirBytes = centralDir.takeBytes();
    buffer.add(centralDirBytes);

    // End of central directory
    buffer.add(_u32le(0x06054b50)); // signature
    buffer.add(_u16le(0)); // disk number
    buffer.add(_u16le(0)); // disk of central dir
    buffer.add(_u16le(files.length)); // entries on disk
    buffer.add(_u16le(files.length)); // total entries
    buffer.add(_u32le(centralDirBytes.length)); // central dir size
    buffer.add(_u32le(centralDirOffset)); // central dir offset
    buffer.add(_u16le(0)); // comment length

    return buffer.takeBytes();
  }

  static Uint8List _u16le(int v) =>
      Uint8List.fromList([v & 0xFF, (v >> 8) & 0xFF]);

  static Uint8List _u32le(int v) => Uint8List.fromList([
        v & 0xFF,
        (v >> 8) & 0xFF,
        (v >> 16) & 0xFF,
        (v >> 24) & 0xFF,
      ]);

  /// CRC-32 (ISO 3309 / ITU-T V.42).
  static int _crc32(List<int> data) {
    int crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (int i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc >>= 1;
        }
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
