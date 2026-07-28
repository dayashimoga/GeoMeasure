import 'dart:convert';
import 'dart:io';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/logging/app_logger.dart';

/// Handles project data backup and restore using Hive + JSON serialization.
///
/// Exports all project data to a single JSON file.
/// Imports from JSON, merging or replacing existing data.
class BackupService {
  static const _projectBoxName = 'projects';
  static const _measurementBoxName = 'measurements';
  static const _settingsBoxName = 'app_settings';

  /// Creates a full backup of all app data as a JSON map.
  static Future<Map<String, dynamic>> createBackup() async {
    final projects = await _boxToMap(_projectBoxName);
    final measurements = await _boxToMap(_measurementBoxName);
    final settings = await _boxToMap(_settingsBoxName);

    return {
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'app': 'GeoMeasure',
      'data': {
        'projects': projects,
        'measurements': measurements,
        'settings': settings,
      },
    };
  }

  /// Exports backup to a JSON file at the given path.
  static Future<File> exportToFile(String filePath) async {
    final backup = await createBackup();
    final json = const JsonEncoder.withIndent('  ').convert(backup);
    final file = File(filePath);
    await file.writeAsString(json);
    logger.info('Backup exported to $filePath', tag: 'Backup');
    return file;
  }

  /// Imports backup from a JSON file, merging with existing data.
  static Future<BackupResult> importFromFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return BackupResult(
          success: false, message: 'File not found: $filePath');
    }

    try {
      final json = await file.readAsString();
      final backup = jsonDecode(json) as Map<String, dynamic>;

      if (backup['app'] != 'GeoMeasure') {
        return const BackupResult(
            success: false, message: 'Not a GeoMeasure backup file');
      }

      final data = backup['data'] as Map<String, dynamic>;
      int restored = 0;

      if (data.containsKey('projects')) {
        restored += await _mapToBox(
            _projectBoxName, data['projects'] as Map<String, dynamic>);
      }
      if (data.containsKey('measurements')) {
        restored += await _mapToBox(
            _measurementBoxName, data['measurements'] as Map<String, dynamic>);
      }

      logger.info('Backup restored: $restored items', tag: 'Backup');
      return BackupResult(
        success: true,
        message: 'Restored $restored items from backup',
        itemCount: restored,
      );
    } catch (e) {
      logger.error('Backup import failed: $e', tag: 'Backup');
      return BackupResult(success: false, message: 'Import failed: $e');
    }
  }

  /// Generates a default backup filename with timestamp.
  static String defaultFilename() {
    final now = DateTime.now();
    final ts = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
    return 'geomeasure_backup_$ts.json';
  }

  static Future<Map<String, dynamic>> _boxToMap(String boxName) async {
    try {
      final box = await Hive.openBox(boxName);
      final map = <String, dynamic>{};
      for (final key in box.keys) {
        map[key.toString()] = box.get(key);
      }
      return map;
    } catch (_) {
      return {};
    }
  }

  static Future<int> _mapToBox(
      String boxName, Map<String, dynamic> data) async {
    final box = await Hive.openBox(boxName);
    int count = 0;
    for (final entry in data.entries) {
      await box.put(entry.key, entry.value);
      count++;
    }
    return count;
  }
}

/// Result of a backup/restore operation.
class BackupResult {
  final bool success;
  final String message;
  final int itemCount;

  const BackupResult({
    required this.success,
    required this.message,
    this.itemCount = 0,
  });
}
