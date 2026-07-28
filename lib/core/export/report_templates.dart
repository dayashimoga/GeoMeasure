import '../../features/measurement_engine/domain/entities/spatial_shape.dart';
import '../../features/estimation/domain/entities/material_estimate.dart';

/// Template types for different report generation.
enum ReportType {
  measurement,
  inspection,
  property,
  inventory,
}

/// Inspection item for building/site inspection reports.
class InspectionItem {
  final String category;
  final String item;
  final InspectionStatus status;
  final String notes;
  final DateTime inspectedAt;

  InspectionItem({
    required this.category,
    required this.item,
    this.status = InspectionStatus.pending,
    this.notes = '',
    DateTime? inspectedAt,
  }) : inspectedAt = inspectedAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'category': category,
        'item': item,
        'status': status.name,
        'notes': notes,
        'inspectedAt': inspectedAt.toIso8601String(),
      };
}

enum InspectionStatus {
  pass,
  fail,
  needsRepair,
  pending,
  notApplicable,
}

/// Property valuation report data.
class PropertyReport {
  final String propertyName;
  final String address;
  final String propertyType;
  final double totalAreaSqm;
  final double builtUpAreaSqm;
  final int numberOfRooms;
  final int numberOfFloors;
  final List<SpatialShape> measurements;
  final QuantityTakeoff? materialEstimate;
  final String notes;

  const PropertyReport({
    required this.propertyName,
    this.address = '',
    this.propertyType = 'Residential',
    required this.totalAreaSqm,
    this.builtUpAreaSqm = 0,
    this.numberOfRooms = 0,
    this.numberOfFloors = 1,
    this.measurements = const [],
    this.materialEstimate,
    this.notes = '',
  });

  Map<String, dynamic> toJson() => {
        'propertyName': propertyName,
        'address': address,
        'propertyType': propertyType,
        'totalAreaSqm': totalAreaSqm,
        'builtUpAreaSqm': builtUpAreaSqm,
        'numberOfRooms': numberOfRooms,
        'numberOfFloors': numberOfFloors,
        'notes': notes,
      };
}

/// Inventory item for counting and measurement reports.
class InventoryItem {
  final String name;
  final String category;
  final int quantity;
  final double unitLengthM;
  final double unitWidthM;
  final double unitHeightM;
  final String condition;
  final String location;
  final DateTime countedAt;

  InventoryItem({
    required this.name,
    this.category = 'General',
    this.quantity = 1,
    this.unitLengthM = 0,
    this.unitWidthM = 0,
    this.unitHeightM = 0,
    this.condition = 'Good',
    this.location = '',
    DateTime? countedAt,
  }) : countedAt = countedAt ?? DateTime.now();

  double get totalVolume =>
      quantity * unitLengthM * unitWidthM * unitHeightM;

  double get totalFloorArea => quantity * unitLengthM * unitWidthM;

  Map<String, dynamic> toJson() => {
        'name': name,
        'category': category,
        'quantity': quantity,
        'unitLengthM': unitLengthM,
        'unitWidthM': unitWidthM,
        'unitHeightM': unitHeightM,
        'condition': condition,
        'location': location,
        'countedAt': countedAt.toIso8601String(),
      };
}

/// Inventory report with summary statistics.
class InventoryReport {
  final String siteName;
  final List<InventoryItem> items;
  final DateTime reportDate;
  final String inspector;

  InventoryReport({
    required this.siteName,
    this.items = const [],
    DateTime? reportDate,
    this.inspector = '',
  }) : reportDate = reportDate ?? DateTime.now();

  int get totalItemCount =>
      items.fold(0, (sum, item) => sum + item.quantity);

  double get totalVolumeM3 =>
      items.fold(0.0, (sum, item) => sum + item.totalVolume);

  Map<String, List<InventoryItem>> get itemsByCategory {
    final map = <String, List<InventoryItem>>{};
    for (final item in items) {
      (map[item.category] ??= []).add(item);
    }
    return map;
  }

  Map<String, dynamic> toJson() => {
        'siteName': siteName,
        'totalItemCount': totalItemCount,
        'totalVolumeM3': totalVolumeM3,
        'inspector': inspector,
        'reportDate': reportDate.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Inspection report for building/site analysis.
class InspectionReport {
  final String siteName;
  final String inspector;
  final List<InspectionItem> items;
  final DateTime inspectionDate;
  final String overallRating;
  final String notes;

  InspectionReport({
    required this.siteName,
    this.inspector = '',
    this.items = const [],
    DateTime? inspectionDate,
    this.overallRating = 'Pending',
    this.notes = '',
  }) : inspectionDate = inspectionDate ?? DateTime.now();

  int get passCount =>
      items.where((i) => i.status == InspectionStatus.pass).length;

  int get failCount =>
      items.where((i) => i.status == InspectionStatus.fail).length;

  int get repairCount =>
      items.where((i) => i.status == InspectionStatus.needsRepair).length;

  double get passRate =>
      items.isEmpty ? 0.0 : (passCount / items.length) * 100;

  /// Standard building inspection checklist template.
  static List<InspectionItem> buildingTemplate() => [
        InspectionItem(
            category: 'Structure', item: 'Foundation integrity'),
        InspectionItem(
            category: 'Structure', item: 'Wall cracks / damage'),
        InspectionItem(
            category: 'Structure', item: 'Roof condition'),
        InspectionItem(
            category: 'Structure', item: 'Floor levelness'),
        InspectionItem(
            category: 'Electrical', item: 'Wiring condition'),
        InspectionItem(
            category: 'Electrical', item: 'Circuit breaker panel'),
        InspectionItem(
            category: 'Electrical', item: 'Grounding system'),
        InspectionItem(
            category: 'Plumbing', item: 'Water supply pipes'),
        InspectionItem(
            category: 'Plumbing', item: 'Drainage system'),
        InspectionItem(
            category: 'Plumbing', item: 'Water heater'),
        InspectionItem(
            category: 'Safety', item: 'Fire extinguishers'),
        InspectionItem(
            category: 'Safety', item: 'Emergency exits'),
        InspectionItem(
            category: 'Safety', item: 'Smoke detectors'),
        InspectionItem(
            category: 'Exterior', item: 'Paint / cladding'),
        InspectionItem(
            category: 'Exterior', item: 'Windows & doors'),
        InspectionItem(
            category: 'Exterior', item: 'Parking / driveway'),
      ];

  Map<String, dynamic> toJson() => {
        'siteName': siteName,
        'inspector': inspector,
        'inspectionDate': inspectionDate.toIso8601String(),
        'overallRating': overallRating,
        'passRate': passRate,
        'notes': notes,
        'items': items.map((i) => i.toJson()).toList(),
      };
}
