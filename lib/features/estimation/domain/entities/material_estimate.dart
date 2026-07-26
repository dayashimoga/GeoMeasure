import '../../../measurement_engine/domain/entities/spatial_shape.dart';

/// Material type for estimation.
enum MaterialType {
  concrete,
  cement,
  sand,
  gravel,
  brick,
  steel,
  wood,
  paint,
  tile,
  glass,
  plumbing,
  electrical,
  plaster,
  waterproofing,
  insulation,
}

/// Unit for material quantity.
enum MaterialUnit {
  cubicMeters,
  squareMeters,
  linearMeters,
  kilograms,
  tonnes,
  pieces,
  bags,
  litres,
  sheets,
}

/// Single material line item.
class MaterialEstimate {
  final MaterialType material;
  final double quantity;
  final MaterialUnit unit;
  final double unitCost;
  final double wastagePercent;

  const MaterialEstimate({
    required this.material,
    required this.quantity,
    required this.unit,
    this.unitCost = 0.0,
    this.wastagePercent = 5.0,
  });

  /// Quantity including wastage.
  double get adjustedQuantity =>
      quantity * (1 + wastagePercent / 100);

  /// Total cost = adjusted quantity × unit cost.
  double get totalCost => adjustedQuantity * unitCost;

  Map<String, dynamic> toJson() => {
        'material': material.name,
        'quantity': quantity,
        'adjustedQuantity': adjustedQuantity,
        'unit': unit.name,
        'unitCost': unitCost,
        'wastagePercent': wastagePercent,
        'totalCost': totalCost,
      };
}

/// Grouped quantity take-off.
class QuantityTakeoff {
  final String projectName;
  final List<MaterialEstimate> items;
  final DateTime generatedAt;

  QuantityTakeoff({
    required this.projectName,
    required this.items,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  double get totalCost =>
      items.fold(0.0, (sum, i) => sum + i.totalCost);

  int get lineItemCount => items.length;

  Map<String, dynamic> toJson() => {
        'projectName': projectName,
        'lineItemCount': lineItemCount,
        'totalCost': totalCost,
        'generatedAt': generatedAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };
}

/// Cost estimate with labor and overhead.
class CostEstimate {
  final QuantityTakeoff materials;
  final double laborCost;
  final double overheadPercent;
  final double contingencyPercent;
  final double profitPercent;

  const CostEstimate({
    required this.materials,
    this.laborCost = 0.0,
    this.overheadPercent = 10.0,
    this.contingencyPercent = 5.0,
    this.profitPercent = 10.0,
  });

  double get materialCost => materials.totalCost;
  double get subtotal => materialCost + laborCost;
  double get overhead => subtotal * overheadPercent / 100;
  double get contingency => subtotal * contingencyPercent / 100;
  double get profit => subtotal * profitPercent / 100;
  double get grandTotal =>
      subtotal + overhead + contingency + profit;

  Map<String, dynamic> toJson() => {
        'materialCost': materialCost,
        'laborCost': laborCost,
        'overhead': overhead,
        'contingency': contingency,
        'profit': profit,
        'grandTotal': grandTotal,
      };
}

/// Production material estimator — calculates quantities from shapes.
///
/// Uses industry-standard formulas:
/// - Concrete: volume × 1.54 dry volume factor
/// - Bricks: 500 per m³ of wall (standard 230×115×75mm with mortar)
/// - Steel: 1% of concrete volume (residential), 2% (commercial)
/// - Paint: 1 litre per 10 m²
/// - Tiles: area / tile area + 10% wastage
/// - Plaster: wall area × 12mm thickness
class MaterialEstimator {
  /// Estimate all materials for a room.
  static QuantityTakeoff estimateForRoom(RoomShape room,
      {String projectName = 'Room Estimate'}) {
    final floorArea = room.calculateAreaInSquareMeters();
    final wallArea = room.wallArea;

    return QuantityTakeoff(
      projectName: projectName,
      items: [
        // Concrete for floor slab (150mm thick)
        MaterialEstimate(
          material: MaterialType.concrete,
          quantity: floorArea * 0.15 * 1.54, // dry volume factor
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 3,
        ),
        // Cement bags (6.5 bags per m³ of concrete, M20 mix)
        MaterialEstimate(
          material: MaterialType.cement,
          quantity: (floorArea * 0.15) * 6.5,
          unit: MaterialUnit.bags,
          wastagePercent: 2,
        ),
        // Bricks for walls (500 per m³, 230mm thick)
        MaterialEstimate(
          material: MaterialType.brick,
          quantity: wallArea * 0.23 * 500,
          unit: MaterialUnit.pieces,
          wastagePercent: 5,
        ),
        // Steel reinforcement (1% of concrete volume)
        MaterialEstimate(
          material: MaterialType.steel,
          quantity: (floorArea * 0.15) * 0.01 * 7850, // 7850 kg/m³ density
          unit: MaterialUnit.kilograms,
          wastagePercent: 3,
        ),
        // Plaster (12mm on both sides of walls)
        MaterialEstimate(
          material: MaterialType.plaster,
          quantity: wallArea * 2 * 0.012,
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 5,
        ),
        // Paint (1 litre per 10 m², 2 coats)
        MaterialEstimate(
          material: MaterialType.paint,
          quantity: (wallArea * 2 + floorArea) * 2 / 10,
          unit: MaterialUnit.litres,
          wastagePercent: 10,
        ),
        // Floor tiles (300×300mm = 0.09 m²)
        MaterialEstimate(
          material: MaterialType.tile,
          quantity: floorArea / 0.09,
          unit: MaterialUnit.pieces,
          wastagePercent: 10,
        ),
      ],
    );
  }

  /// Estimate materials for a building.
  static QuantityTakeoff estimateForBuilding(BuildingShape building,
      {String projectName = 'Building Estimate'}) {
    final footprint = building.footprintArea;
    final totalFloor = building.calculateAreaInSquareMeters();
    final wallArea = building.calculateTotalWallSurfaceArea();
    final volume = building.calculateVolumeInCubicMeters();

    return QuantityTakeoff(
      projectName: projectName,
      items: [
        // Foundation concrete (600mm deep strip)
        MaterialEstimate(
          material: MaterialType.concrete,
          quantity: building.calculatePerimeterInMeters() * 0.6 * 0.6 * 1.54,
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 5,
        ),
        // Column concrete (4 columns per 25m², 300×300mm, full height)
        MaterialEstimate(
          material: MaterialType.concrete,
          quantity: (footprint / 25).ceil() * 4 * 0.3 * 0.3 *
              building.totalHeight * 1.54,
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 3,
        ),
        // Slab concrete (150mm per floor)
        MaterialEstimate(
          material: MaterialType.concrete,
          quantity: totalFloor * 0.15 * 1.54,
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 3,
        ),
        // Bricks for walls
        MaterialEstimate(
          material: MaterialType.brick,
          quantity: wallArea * 0.23 * 500,
          unit: MaterialUnit.pieces,
          wastagePercent: 5,
        ),
        // Steel (2% for commercial)
        MaterialEstimate(
          material: MaterialType.steel,
          quantity: volume * 0.02 * 7850,
          unit: MaterialUnit.kilograms,
          wastagePercent: 3,
        ),
        // Cement
        MaterialEstimate(
          material: MaterialType.cement,
          quantity: (totalFloor * 0.15 + wallArea * 0.23) * 6.5,
          unit: MaterialUnit.bags,
          wastagePercent: 2,
        ),
        // Sand
        MaterialEstimate(
          material: MaterialType.sand,
          quantity: (totalFloor * 0.15 + wallArea * 0.23) * 1.5,
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 5,
        ),
      ],
    );
  }

  /// Estimate excavation materials.
  static QuantityTakeoff estimateForExcavation(ExcavationShape exc,
      {String projectName = 'Excavation Estimate'}) {
    return QuantityTakeoff(
      projectName: projectName,
      items: [
        const MaterialEstimate(
          material: MaterialType.concrete,
          quantity: 0, // excavation doesn't use concrete by default
          unit: MaterialUnit.cubicMeters,
        ),
        // Backfill gravel (30% of excavation volume typically)
        MaterialEstimate(
          material: MaterialType.gravel,
          quantity: exc.cutVolume * 0.3,
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 10,
        ),
        // Sand bedding (10% of volume)
        MaterialEstimate(
          material: MaterialType.sand,
          quantity: exc.cutVolume * 0.1,
          unit: MaterialUnit.cubicMeters,
          wastagePercent: 10,
        ),
      ],
    );
  }

  /// Estimate paint needed for a surface area.
  static MaterialEstimate estimatePaint(double areaSqm,
      {int coats = 2}) {
    // 1 litre covers ~10 m² per coat
    return MaterialEstimate(
      material: MaterialType.paint,
      quantity: areaSqm * coats / 10,
      unit: MaterialUnit.litres,
      wastagePercent: 10,
    );
  }

  /// Estimate tiles for a floor area.
  static MaterialEstimate estimateTiles(double areaSqm,
      {double tileSizeMm = 300}) {
    final tileAreaSqm = (tileSizeMm / 1000) * (tileSizeMm / 1000);
    return MaterialEstimate(
      material: MaterialType.tile,
      quantity: areaSqm / tileAreaSqm,
      unit: MaterialUnit.pieces,
      wastagePercent: 10,
    );
  }
}
