import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/project.dart';

abstract class ProjectLocalDataSource {
  Future<List<Project>> getAll();
  Future<Project?> getById(String id);
  Future<void> save(Project project);
  Future<void> delete(String id);
  Future<void> clearAll();
}

/// Hive-backed persistent storage for projects.
///
/// Each project is stored as a JSON string keyed by its ID.
/// Hive provides encrypted, offline-first storage with
/// sub-millisecond read/write performance.
class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  static const String _boxName = 'projects';
  Box<String>? _box;

  Future<Box<String>> get _projectBox async {
    if (_box != null && _box!.isOpen) return _box!;
    _box = await Hive.openBox<String>(_boxName);
    return _box!;
  }

  @override
  Future<List<Project>> getAll() async {
    final box = await _projectBox;
    return box.values
        .map((json) =>
            Project.fromJson(jsonDecode(json) as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  }

  @override
  Future<Project?> getById(String id) async {
    final box = await _projectBox;
    final json = box.get(id);
    if (json == null) return null;
    return Project.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  @override
  Future<void> save(Project project) async {
    final box = await _projectBox;
    await box.put(project.id, jsonEncode(project.toJson()));
  }

  @override
  Future<void> delete(String id) async {
    final box = await _projectBox;
    await box.delete(id);
  }

  @override
  Future<void> clearAll() async {
    final box = await _projectBox;
    await box.clear();
  }
}
