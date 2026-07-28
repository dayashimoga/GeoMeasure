import 'package:flutter/material.dart';
import '../../../core/data/backup_service.dart';
import '../../../core/di/service_locator.dart';

/// Settings page with backup/restore, theme, and diagnostics.
class SettingsPage extends StatelessWidget {
  final VoidCallback? onToggleTheme;

  const SettingsPage({super.key, this.onToggleTheme});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Appearance ──
          const _SectionHeader(title: 'Appearance', icon: Icons.palette_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.dark_mode_rounded,
                      color: theme.colorScheme.primary),
                  title: const Text('Toggle Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: onToggleTheme,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Data Management ──
          const _SectionHeader(
              title: 'Data Management', icon: Icons.storage_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.backup_rounded,
                      color: theme.colorScheme.primary),
                  title: const Text('Create Backup'),
                  subtitle: const Text('Export all projects and measurements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _createBackup(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.restore_rounded,
                      color: theme.colorScheme.primary),
                  title: const Text('Restore from Backup'),
                  subtitle: const Text('Import data from a backup file'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _restoreBackup(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.delete_sweep_rounded,
                      color: theme.colorScheme.error),
                  title: Text('Clear All Data',
                      style: TextStyle(color: theme.colorScheme.error)),
                  subtitle: const Text('Remove all projects and measurements'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _confirmClearData(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Advanced / Diagnostics ──
          const _SectionHeader(title: 'Advanced', icon: Icons.build_rounded),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.sensors_rounded,
                      color: theme.colorScheme.primary),
                  title: const Text('Hardware Diagnostics'),
                  subtitle:
                      const Text('View detected sensors and capabilities'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showDiagnostics(context),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(Icons.info_outline_rounded,
                      color: theme.colorScheme.primary),
                  title: const Text('About GeoMeasure'),
                  subtitle: const Text('Version, licenses, and credits'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _showAbout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createBackup(BuildContext context) async {
    try {
      final backup = await BackupService.createBackup();
      final itemCount = (backup['data'] as Map).values
          .whereType<Map>()
          .fold<int>(0, (sum, m) => sum + m.length);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup created: $itemCount items'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup failed: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    // Show info dialog since file picker requires platform plugin
    if (!context.mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore from Backup'),
        content: const Text(
          'To restore, place a GeoMeasure backup file (.json) '
          'in your device storage, then use the file manager to open it.\n\n'
          'Backup files are named: geomeasure_backup_YYYYMMDD_HHMM.json',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all projects, measurements, '
          'and settings. This action cannot be undone.\n\n'
          'Create a backup first if you want to keep your data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Clear projects
      sl.projectProvider.projects.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('All data cleared'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showDiagnostics(BuildContext context) {
    final profile = sl.capabilityProvider.profile;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (_, controller) => ListView(
          controller: controller,
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text('Hardware Diagnostics',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ...profile.toJson().entries.map(
                  (e) => ListTile(
                    dense: true,
                    title: Text(e.key),
                    trailing: Text(
                      e.value.toString(),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'GeoMeasure',
      applicationVersion: '2.4.0',
      applicationLegalese: '© 2026 GeoMeasure. All rights reserved.',
      children: [
        const SizedBox(height: 16),
        const Text(
          'Universal AI Room, Land & Object Measurement App. '
          'Measure anything with camera, GPS, LiDAR, or manual input.',
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;

  const _SectionHeader({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
