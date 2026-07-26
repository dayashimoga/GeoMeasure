import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_local_datasource.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  final ProjectLocalDataSource dataSource;

  ProjectRepositoryImpl(this.dataSource);

  @override
  Future<List<Project>> getAllProjects() => dataSource.getAll();

  @override
  Future<Project?> getProject(String id) => dataSource.getById(id);

  @override
  Future<void> saveProject(Project project) => dataSource.save(project);

  @override
  Future<void> deleteProject(String id) => dataSource.delete(id);

  @override
  Future<List<Project>> searchProjects(String query) async {
    final all = await dataSource.getAll();
    final lowerQuery = query.toLowerCase();
    return all
        .where((p) =>
            p.name.toLowerCase().contains(lowerQuery) ||
            (p.description?.toLowerCase().contains(lowerQuery) ?? false) ||
            p.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  @override
  Future<List<Project>> getProjectsByFolder(String folder) async {
    final all = await dataSource.getAll();
    return all.where((p) => p.folder == folder).toList();
  }

  @override
  Future<List<Project>> getProjectsByTag(String tag) async {
    final all = await dataSource.getAll();
    return all.where((p) => p.tags.contains(tag)).toList();
  }

  @override
  Future<List<Project>> getProjectsByStatus(ProjectStatus status) async {
    final all = await dataSource.getAll();
    return all.where((p) => p.status == status).toList();
  }
}
