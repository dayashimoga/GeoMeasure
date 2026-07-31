import 'package:flutter/material.dart' hide MaterialType;
import '../../measurement_engine/domain/entities/spatial_shape.dart';
import '../../measurement_engine/domain/entities/room_templates.dart';
import '../../estimation/domain/entities/material_estimate.dart';
import '../widgets/paint_tile_calculator.dart';

/// Multi-room batch measurement page.
///
/// Measure an entire house/building room-by-room with running totals
/// and combined BOQ export.
class MultiRoomPage extends StatefulWidget {
  const MultiRoomPage({super.key});

  @override
  State<MultiRoomPage> createState() => _MultiRoomPageState();
}

class _MultiRoomPageState extends State<MultiRoomPage> {
  final List<_RoomEntry> _rooms = [];

  double get _totalArea =>
      _rooms.fold(0.0, (s, r) => s + r.shape.calculateAreaInSquareMeters());
  double get _totalWallArea => _rooms.fold(0.0, (s, r) => s + r.shape.wallArea);
  double get _totalVolume =>
      _rooms.fold(0.0, (s, r) => s + r.shape.calculateVolumeInCubicMeters());

  void _addRoom() {
    _showAddRoomDialog();
  }

  void _addFromTemplate(RoomTemplate tpl) {
    setState(() {
      _rooms.add(_RoomEntry(
        name: tpl.name,
        shape: tpl.toRoomShape(),
        template: tpl,
      ));
    });
  }

  void _addCustomRoom(String name, double length, double width, double height) {
    setState(() {
      _rooms.add(_RoomEntry(
        name: name,
        shape: RoomShape(
          vertices: [
            const Point3D(0, 0),
            Point3D(length, 0),
            Point3D(length, width),
            Point3D(0, width),
          ],
          heightMeters: height,
        ),
      ));
    });
  }

  void _removeRoom(int index) {
    setState(() => _rooms.removeAt(index));
  }

  QuantityTakeoff _combinedBOQ() {
    final allItems = <MaterialEstimate>[];
    for (final room in _rooms) {
      final takeoff =
          MaterialEstimator.estimateForRoom(room.shape, projectName: room.name);
      allItems.addAll(takeoff.items);
    }

    // Merge quantities by material type
    final merged = <MaterialType, MaterialEstimate>{};
    for (final item in allItems) {
      if (merged.containsKey(item.material)) {
        final existing = merged[item.material]!;
        merged[item.material] = MaterialEstimate(
          material: item.material,
          quantity: existing.quantity + item.quantity,
          unit: item.unit,
          unitCost: item.unitCost,
          wastagePercent: item.wastagePercent,
        );
      } else {
        merged[item.material] = item;
      }
    }

    return QuantityTakeoff(
      projectName: 'Multi-Room Estimate (${_rooms.length} rooms)',
      items: merged.values.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Room Measurement'),
        centerTitle: false,
        actions: [
          if (_rooms.isNotEmpty)
            TextButton.icon(
              onPressed: _showCombinedBOQ,
              icon: const Icon(Icons.receipt_long_rounded, size: 18),
              label: const Text('Combined BOQ'),
            ),
        ],
      ),
      body: _rooms.isEmpty ? _buildEmptyState(theme) : _buildRoomList(theme),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRoom,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Room'),
      ),
      bottomNavigationBar: _rooms.isEmpty ? null : _buildSummaryBar(theme),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_work_rounded,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text('No Rooms Added',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              )),
          const SizedBox(height: 8),
          Text('Add rooms one by one to measure your entire house',
              style: TextStyle(color: theme.colorScheme.outline)),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _addRoom,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add First Room'),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomList(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _rooms.length,
      itemBuilder: (ctx, i) {
        final room = _rooms[i];
        final area = room.shape.calculateAreaInSquareMeters();
        final wallA = room.shape.wallArea;
        final vol = room.shape.calculateVolumeInCubicMeters();

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text('${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onPrimaryContainer,
                          )),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(room.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 15)),
                          if (room.template != null)
                            Text(room.template!.description,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                )),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      onPressed: () => _removeRoom(i),
                      tooltip: 'Remove room',
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _miniStat(theme, Icons.square_foot_rounded,
                        '${area.toStringAsFixed(1)} m²', 'Floor'),
                    const SizedBox(width: 8),
                    _miniStat(theme, Icons.wallpaper_rounded,
                        '${wallA.toStringAsFixed(1)} m²', 'Walls'),
                    const SizedBox(width: 8),
                    _miniStat(theme, Icons.view_in_ar_rounded,
                        '${vol.toStringAsFixed(1)} m³', 'Volume'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(ThemeData theme, IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: theme.colorScheme.primary),
            const SizedBox(height: 2),
            Text(value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border:
            Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(child: _summaryChip(theme, '${_rooms.length}', 'Rooms')),
            const SizedBox(width: 8),
            Expanded(
                child: _summaryChip(theme,
                    '${_totalArea.toStringAsFixed(1)} m²', 'Total Area')),
            const SizedBox(width: 8),
            Expanded(
                child: _summaryChip(theme,
                    '${_totalWallArea.toStringAsFixed(1)} m²', 'Wall Area')),
            const SizedBox(width: 8),
            Expanded(
                child: _summaryChip(
                    theme, '${_totalVolume.toStringAsFixed(1)} m³', 'Volume')),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip(ThemeData theme, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            )),
        Text(label,
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
      ],
    );
  }

  void _showAddRoomDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, ctrl) => _AddRoomSheet(
          scrollController: ctrl,
          onTemplateSelected: (tpl) {
            _addFromTemplate(tpl);
            Navigator.pop(ctx);
          },
          onCustomRoom: (name, l, w, h) {
            _addCustomRoom(name, l, w, h);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  void _showCombinedBOQ() {
    final boq = _combinedBOQ();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          expand: false,
          builder: (_, ctrl) => ListView(
            controller: ctrl,
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Combined Bill of Quantities',
                  style: theme.textTheme.titleLarge),
              Text(
                  '${_rooms.length} rooms • ${_totalArea.toStringAsFixed(1)} m² total',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  )),
              const SizedBox(height: 16),
              ...boq.items.map((item) => ListTile(
                    dense: true,
                    leading: Icon(_materialIcon(item.material),
                        color: theme.colorScheme.primary),
                    title: Text(item.material.name.toUpperCase(),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text('${item.wastagePercent}% wastage included'),
                    trailing: Text(
                      '${item.adjustedQuantity.toStringAsFixed(1)} ${item.unit.name}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  )),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) =>
                        PaintTileCalculator(prefillAreaSqm: _totalWallArea),
                  ));
                },
                icon: const Icon(Icons.format_paint_rounded, size: 18),
                label: const Text('Open Paint & Tile Calculator'),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _materialIcon(MaterialType m) {
    switch (m) {
      case MaterialType.concrete:
        return Icons.foundation_rounded;
      case MaterialType.cement:
        return Icons.inventory_2_rounded;
      case MaterialType.brick:
        return Icons.grid_view_rounded;
      case MaterialType.steel:
        return Icons.construction_rounded;
      case MaterialType.paint:
        return Icons.format_paint_rounded;
      case MaterialType.tile:
        return Icons.grid_on_rounded;
      case MaterialType.plaster:
        return Icons.layers_rounded;
      default:
        return Icons.build_rounded;
    }
  }
}

/// Bottom sheet for adding a room (template or custom).
class _AddRoomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final void Function(RoomTemplate) onTemplateSelected;
  final void Function(String name, double l, double w, double h) onCustomRoom;

  const _AddRoomSheet({
    required this.scrollController,
    required this.onTemplateSelected,
    required this.onCustomRoom,
  });

  @override
  State<_AddRoomSheet> createState() => _AddRoomSheetState();
}

class _AddRoomSheetState extends State<_AddRoomSheet> {
  bool _showCustom = false;
  final _nameCtrl = TextEditingController(text: 'Custom Room');
  final _lCtrl = TextEditingController();
  final _wCtrl = TextEditingController();
  final _hCtrl = TextEditingController(text: '3.0');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _lCtrl.dispose();
    _wCtrl.dispose();
    _hCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        Text('Add Room', style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text('Choose a template or enter custom dimensions',
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
        const SizedBox(height: 16),

        // Template grid
        Text('TEMPLATES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: RoomTemplate.all
              .map((tpl) => ActionChip(
                    avatar:
                        Text(tpl.icon, style: const TextStyle(fontSize: 16)),
                    label: Text(tpl.name, style: const TextStyle(fontSize: 12)),
                    tooltip: tpl.description,
                    onPressed: () => widget.onTemplateSelected(tpl),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),

        // Custom input
        TextButton.icon(
          onPressed: () => setState(() => _showCustom = !_showCustom),
          icon: Icon(_showCustom
              ? Icons.expand_less_rounded
              : Icons.expand_more_rounded),
          label: const Text('Custom Dimensions'),
        ),
        if (_showCustom) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Room Name',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: TextField(
                controller: _lCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Length (m)',
                  hintText: 'e.g. 5.0',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                controller: _wCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Width (m)',
                  hintText: 'e.g. 4.0',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                controller: _hCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height (m)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              )),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              final l = double.tryParse(_lCtrl.text);
              final w = double.tryParse(_wCtrl.text);
              final h = double.tryParse(_hCtrl.text);
              if (l == null ||
                  l <= 0 ||
                  w == null ||
                  w <= 0 ||
                  h == null ||
                  h <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Enter valid dimensions'),
                      behavior: SnackBarBehavior.floating),
                );
                return;
              }
              widget.onCustomRoom(_nameCtrl.text.trim(), l, w, h);
            },
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Custom Room'),
          ),
        ],
      ],
    );
  }
}

class _RoomEntry {
  final String name;
  final RoomShape shape;
  final RoomTemplate? template;

  const _RoomEntry({
    required this.name,
    required this.shape,
    this.template,
  });
}
