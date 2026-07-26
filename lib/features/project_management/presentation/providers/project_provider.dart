import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../measurement_engine/domain/entities/measurement_result.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';

/// Manages project state with auto-save and change notification.
class ProjectProvider extends ChangeNotifier {
  final ProjectRepository repository;
  final Uuid _uuid = const Uuid();

  List<Project> _projects = [];
  Project? _activeProject;
  bool _isLoading = false;
  String? _searchQuery;
  String? _errorMessage;

  List<Project> get projects => _projects;
  Project? get activeProject => _activeProject;
  bool get isLoading => _isLoading;
  String? get searchQuery => _searchQuery;
  String? get errorMessage => _errorMessage;

  ProjectProvider({required this.repository});

  Future<void> loadProjects() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _projects = await repository.getAllProjects();
    } catch (e, st) {
      _errorMessage = 'Failed to load projects: $e';
      logger.error('Failed to load projects', error: e, stackTrace: st);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Project> createProject({
    required String name,
    String? description,
    String? folder,
    List<String> tags = const [],
    ProjectType type = ProjectType.general,
  }) async {
    final project = Project(
      id: _uuid.v4(),
      name: name,
      description: description,
      folder: folder,
      tags: tags,
      type: type,
    );

    await repository.saveProject(project);
    _projects.insert(0, project);
    _activeProject = project;
    logger.info('Project created: ${project.name}', tag: 'ProjectProvider');
    notifyListeners();
    return project;
  }

  Future<void> updateProject(Project project) async {
    final updated = project.copyWith(updatedAt: DateTime.now());
    await repository.saveProject(updated);

    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) _projects[index] = updated;
    if (_activeProject?.id == project.id) _activeProject = updated;

    notifyListeners();
  }

  Future<void> deleteProject(String id) async {
    await repository.deleteProject(id);
    _projects.removeWhere((p) => p.id == id);
    if (_activeProject?.id == id) _activeProject = null;
    logger.info('Project deleted: $id', tag: 'ProjectProvider');
    notifyListeners();
  }

  Future<void> addMeasurementToProject(
    String projectId,
    MeasurementResult result,
  ) async {
    final project = _projects.firstWhere(
      (p) => p.id == projectId,
      orElse: () => throw StateError('Project not found: $projectId'),
    );

    final updatedMeasurements = [...project.measurements, result];
    final updated = project.copyWith(measurements: updatedMeasurements);
    await updateProject(updated);
  }

  void setActiveProject(Project? project) {
    _activeProject = project;
    notifyListeners();
  }

  Future<void> searchProjects(String query) async {
    _searchQuery = query;
    if (query.isEmpty) {
      await loadProjects();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _projects = await repository.searchProjects(query);
    } catch (e) {
      _errorMessage = 'Search failed: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
