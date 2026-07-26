import '../entities/project.dart';

abstract class ProjectRepository {
  Future<List<Project>> getAllProjects();
  Future<Project?> getProject(String id);
  Future<void> saveProject(Project project);
  Future<void> deleteProject(String id);
  Future<List<Project>> searchProjects(String query);
  Future<List<Project>> getProjectsByFolder(String folder);
  Future<List<Project>> getProjectsByTag(String tag);
  Future<List<Project>> getProjectsByStatus(ProjectStatus status);
}
