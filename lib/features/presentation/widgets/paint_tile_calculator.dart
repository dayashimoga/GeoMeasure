import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Standalone paint & tile calculator widget.
///
/// Computes litres of paint and number of tiles needed for a given area.
/// Can auto-fill area from last measurement or accept manual input.
class PaintTileCalculator extends StatefulWidget {
  /// Pre-filled area in m² from a measurement result.
  final double? prefillAreaSqm;

  const PaintTileCalculator({super.key, this.prefillAreaSqm});

  @override
  State<PaintTileCalculator> createState() => _PaintTileCalculatorState();
}

class _PaintTileCalculatorState extends State<PaintTileCalculator>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _areaCtrl = TextEditingController();
  final _coatsCtrl = TextEditingController(text: '2');
  final _coverageCtrl = TextEditingController(text: '10.0');
  final _pricePerLitreCtrl = TextEditingController(text: '350');

  final _tileAreaCtrl = TextEditingController();
  final _tileLengthCtrl = TextEditingController(text: '300');
  final _tileWidthCtrl = TextEditingController(text: '300');
  final _gapMmCtrl = TextEditingController(text: '3');
  final _tilePriceCtrl = TextEditingController(text: '45');
  int _tilesPerBox = 10;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    if (widget.prefillAreaSqm != null) {
      _areaCtrl.text = widget.prefillAreaSqm!.toStringAsFixed(2);
      _tileAreaCtrl.text = widget.prefillAreaSqm!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _areaCtrl.dispose();
    _coatsCtrl.dispose();
    _coverageCtrl.dispose();
    _pricePerLitreCtrl.dispose();
    _tileAreaCtrl.dispose();
    _tileLengthCtrl.dispose();
    _tileWidthCtrl.dispose();
    _gapMmCtrl.dispose();
    _tilePriceCtrl.dispose();
    super.dispose();
  }

  // ── Paint Calculation ──
  Map<String, double> _calculatePaint() {
    final area = double.tryParse(_areaCtrl.text) ?? 0;
    final coats = int.tryParse(_coatsCtrl.text) ?? 2;
    final coverage = double.tryParse(_coverageCtrl.text) ?? 10;
    final pricePerL = double.tryParse(_pricePerLitreCtrl.text) ?? 0;

    if (area <= 0 || coverage <= 0) return {};

    final litresNeeded = (area * coats) / coverage;
    final litresWithWastage = litresNeeded * 1.10; // 10% wastage
    final cans1L = litresWithWastage.ceil();
    final cans4L = (litresWithWastage / 4).ceil();
    final cans10L = (litresWithWastage / 10).ceil();
    final cans20L = (litresWithWastage / 20).ceil();
    final cost = litresWithWastage * pricePerL;

    return {
      'litres': litresWithWastage,
      'cans_1L': cans1L.toDouble(),
      'cans_4L': cans4L.toDouble(),
      'cans_10L': cans10L.toDouble(),
      'cans_20L': cans20L.toDouble(),
      'cost': cost,
    };
  }

  // ── Tile Calculation ──
  Map<String, double> _calculateTiles() {
    final area = double.tryParse(_tileAreaCtrl.text) ?? 0;
    final tileL = double.tryParse(_tileLengthCtrl.text) ?? 300;
    final tileW = double.tryParse(_tileWidthCtrl.text) ?? 300;
    final gap = double.tryParse(_gapMmCtrl.text) ?? 3;
    final pricePerTile = double.tryParse(_tilePriceCtrl.text) ?? 0;

    if (area <= 0 || tileL <= 0 || tileW <= 0) return {};

    // Convert mm to meters, include gap
    final effectiveL = (tileL + gap) / 1000;
    final effectiveW = (tileW + gap) / 1000;
    final tileArea = effectiveL * effectiveW;
    final tilesNeeded = (area / tileArea).ceil();
    final tilesWithWastage = (tilesNeeded * 1.10).ceil(); // 10% wastage
    final boxes = (tilesWithWastage / _tilesPerBox).ceil();
    final cost = tilesWithWastage * pricePerTile;

    return {
      'tiles': tilesWithWastage.toDouble(),
      'boxes': boxes.toDouble(),
      'cost': cost,
      'tileArea': (tileL * tileW / 1e6), // single tile area in m²
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paint & Tile Calculator'),
        centerTitle: false,
        bottom: TabBar(
          controller: _tabCtrl,
          tabs: const [
            Tab(icon: Icon(Icons.format_paint_rounded), text: 'Paint'),
            Tab(icon: Icon(Icons.grid_view_rounded), text: 'Tiles'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildPaintTab(theme),
          _buildTileTab(theme),
        ],
      ),
    );
  }

  Widget _buildPaintTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel(theme, 'INPUT'),
        const SizedBox(height: 8),
        _inputField(
            _areaCtrl, 'Wall/Ceiling Area', 'm²', Icons.square_foot_rounded),
        _inputField(
            _coatsCtrl, 'Number of Coats', 'coats', Icons.layers_rounded),
        _inputField(_coverageCtrl, 'Paint Coverage', 'm²/litre',
            Icons.color_lens_rounded),
        _inputField(_pricePerLitreCtrl, 'Price per Litre', '₹',
            Icons.currency_rupee_rounded),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.calculate_rounded),
          label: const Text('Calculate Paint'),
        ),
        const SizedBox(height: 24),
        _buildPaintResults(theme),
      ],
    );
  }

  Widget _buildPaintResults(ThemeData theme) {
    final r = _calculatePaint();
    if (r.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      color: theme.colorScheme.primary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'PAINT ESTIMATE'),
            const SizedBox(height: 12),
            _resultRow(theme, Icons.water_drop_rounded, 'Total Paint Needed',
                '${r['litres']!.toStringAsFixed(1)} litres',
                subtitle: 'Including 10% wastage'),
            const Divider(height: 24),
            Text('Can Options:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                )),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _canChip(theme, '1L', r['cans_1L']!.toInt()),
                _canChip(theme, '4L', r['cans_4L']!.toInt()),
                _canChip(theme, '10L', r['cans_10L']!.toInt()),
                _canChip(theme, '20L', r['cans_20L']!.toInt()),
              ],
            ),
            if (r['cost']! > 0) ...[
              const Divider(height: 24),
              _resultRow(theme, Icons.currency_rupee_rounded, 'Estimated Cost',
                  '₹${r['cost']!.toStringAsFixed(0)}'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTileTab(ThemeData theme) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionLabel(theme, 'INPUT'),
        const SizedBox(height: 8),
        _inputField(
            _tileAreaCtrl, 'Floor/Wall Area', 'm²', Icons.square_foot_rounded),
        Row(
          children: [
            Expanded(
                child: _inputField(_tileLengthCtrl, 'Tile Length', 'mm',
                    Icons.straighten_rounded)),
            const SizedBox(width: 8),
            Expanded(
                child: _inputField(_tileWidthCtrl, 'Tile Width', 'mm',
                    Icons.straighten_rounded)),
          ],
        ),
        _inputField(
            _gapMmCtrl, 'Joint/Gap Width', 'mm', Icons.space_bar_rounded),
        Row(
          children: [
            Expanded(
                child: _inputField(_tilePriceCtrl, 'Price per Tile', '₹',
                    Icons.currency_rupee_rounded)),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                initialValue: _tilesPerBox,
                decoration: const InputDecoration(
                  labelText: 'Tiles per Box',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [4, 6, 8, 10, 12, 15, 20]
                    .map((n) =>
                        DropdownMenuItem(value: n, child: Text('$n pcs')))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _tilesPerBox = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => setState(() {}),
          icon: const Icon(Icons.calculate_rounded),
          label: const Text('Calculate Tiles'),
        ),
        const SizedBox(height: 24),
        _buildTileResults(theme),
      ],
    );
  }

  Widget _buildTileResults(ThemeData theme) {
    final r = _calculateTiles();
    if (r.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
            color: theme.colorScheme.tertiary.withValues(alpha: 0.3)),
      ),
      color: theme.colorScheme.tertiary.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel(theme, 'TILE ESTIMATE'),
            const SizedBox(height: 12),
            _resultRow(theme, Icons.grid_view_rounded, 'Tiles Needed',
                '${r['tiles']!.toInt()} pieces',
                subtitle: 'Including 10% wastage'),
            const SizedBox(height: 8),
            _resultRow(theme, Icons.inventory_2_rounded, 'Boxes to Buy',
                '${r['boxes']!.toInt()} boxes',
                subtitle: '$_tilesPerBox tiles per box'),
            if (r['tileArea'] != null) ...[
              const SizedBox(height: 8),
              _resultRow(theme, Icons.crop_square_rounded, 'Single Tile Area',
                  '${(r['tileArea']! * 10000).toStringAsFixed(0)} cm²'),
            ],
            if (r['cost']! > 0) ...[
              const Divider(height: 24),
              _resultRow(theme, Icons.currency_rupee_rounded, 'Estimated Cost',
                  '₹${r['cost']!.toStringAsFixed(0)}'),
            ],
          ],
        ),
      ),
    );
  }

  // ── Helpers ──

  Widget _sectionLabel(ThemeData theme, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _inputField(
      TextEditingController ctrl, String label, String suffix, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          suffixText: suffix,
          prefixIcon: Icon(icon, size: 20),
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }

  Widget _resultRow(ThemeData theme, IconData icon, String label, String value,
      {String? subtitle}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 13)),
              if (subtitle != null)
                Text(subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    )),
            ],
          ),
        ),
        Text(value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
            )),
      ],
    );
  }

  Widget _canChip(ThemeData theme, String size, int count) {
    return Chip(
      avatar: Icon(Icons.color_lens_rounded,
          size: 16, color: theme.colorScheme.primary),
      label: Text('$count × $size'),
      backgroundColor:
          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
      side: BorderSide.none,
    );
  }
}
