import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import '../../../core/data/backup_service.dart';
import '../../../core/di/service_locator.dart';

/// Extracted settings tab widget from the dashboard monolith.
///
/// Provides theme toggle, floor plan grid toggle, feature flags,
/// backup/restore, hardware diagnostics, and app version info.
class SettingsTab extends StatefulWidget {
  final VoidCallback? onToggleTheme;

  const SettingsTab({super.key, this.onToggleTheme});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  bool _showGrid = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: [
        // ── Appearance ──
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.palette_rounded),
                title: const Text('Dark Mode'),
                trailing: Switch.adaptive(
                  value: theme.brightness == Brightness.dark,
                  onChanged: (_) => widget.onToggleTheme?.call(),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.grid_on_rounded),
                title: const Text('Show Grid in Floor Plan'),
                trailing: Switch.adaptive(
                  value: _showGrid,
                  onChanged: (v) => setState(() => _showGrid = v),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Feature Flags ──
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'FEATURE FLAGS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              ...sl.config.allFlags.entries.map((e) => SwitchListTile.adaptive(
                    title: Text(e.key.replaceAll('_', ' '),
                        style: const TextStyle(fontSize: 14)),
                    value: e.value,
                    dense: true,
                    onChanged: (v) {
                      setState(() => sl.config.setFeatureFlag(e.key, v));
                    },
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Data Management & Hardware ──
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'DATA MANAGEMENT & HARDWARE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.backup_rounded,
                    color: theme.colorScheme.primary),
                title: const Text('Create Backup'),
                subtitle: const Text('Export all projects & measurements'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () async {
                  final backup = await BackupService.createBackup();
                  final count = (backup['data'] as Map)
                      .values
                      .whereType<Map>()
                      .fold<int>(0, (s, m) => s + m.length);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Backup ready: $count items'),
                    behavior: SnackBarBehavior.floating,
                  ));
                },
              ),
              ListTile(
                leading: Icon(Icons.restore_rounded,
                    color: theme.colorScheme.primary),
                title: const Text('Restore from Backup'),
                subtitle: const Text('Import from backup file'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Restore from Backup'),
                      content: const Text(
                        'Place a GeoMeasure backup file (.json) in your '
                        'device storage, then use the file manager to open it.\n\n'
                        'Filename format: geomeasure_backup_YYYYMMDD_HHMM.json',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.sensors_rounded,
                    color: theme.colorScheme.primary),
                title: const Text('Hardware Diagnostics'),
                subtitle: const Text('View detected sensors & AI accelerators'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  final profile = sl.capabilityProvider.profile;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (ctx) => DraggableScrollableSheet(
                      initialChildSize: 0.6,
                      maxChildSize: 0.9,
                      minChildSize: 0.3,
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
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Text('Hardware Diagnostics',
                              style: theme.textTheme.titleLarge),
                          const SizedBox(height: 8),
                          ...profile.toJson().entries.map(
                                (e) => ListTile(
                                  dense: true,
                                  title: Text(e.key),
                                  trailing: Text(
                                    e.value.toString(),
                                    style: TextStyle(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── App Info ──
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('GeoMeasure v${AppConfig.appVersion}',
                    key: const Key('app_version_text'),
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary)),
                const SizedBox(height: 4),
                Text(
                  'Universal AI Spatial & Land Measurement Engine',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
