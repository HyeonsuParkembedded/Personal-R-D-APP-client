import '../models/project.dart';
import '../models/remote_repo.dart';
import '../services/api_client.dart';

class ProjectRepository {
  final ApiClient _apiClient = ApiClient();

  /// Fetches a list of all projects
  Future<List<ProjectListItem>> getProjects() async {
    // Note: The backend route in router.py maps to slightly different endpoint versions
    // `app/api/router.py` shows no `/v1` prefix internally but depends on FASTAPI `api_prefix`.
    // We'll set the endpoint string properly. Assuming `/projects`.
    final data = await _apiClient.get('/projects');
    if (data is List) {
      return data.map((json) => ProjectListItem.fromJson(json)).toList();
    }
    return [];
  }

  /// Fetches summary activity for a single project
  Future<ProjectActivitySummary> getProjectSummary(int projectId) async {
    final data = await _apiClient.get('/projects/$projectId/summary');
    return ProjectActivitySummary.fromJson(data);
  }

  /// Fetches a project's timeline
  Future<List<TimelineEvent>> getProjectTimeline(int projectId, {int limit = 20}) async {
    final data = await _apiClient.get('/projects/$projectId/timeline?limit=$limit');
    if (data is List) {
      return data.map((json) => TimelineEvent.fromJson(json)).toList();
    }
    return [];
  }

  /// Optional: Create a quick test project
  Future<ProjectDetail> createProject(String name, String description) async {
    final data = await _apiClient.post('/projects', body: {
      'name': name,
      'description': description,
      'status': 'idea',
    });
    return ProjectDetail.fromJson(data);
  }

  /// Updates a project's name, description, and/or status.
  Future<void> updateProject(int projectId,
      {String? name, String? description, String? status}) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (status != null) body['status'] = status;
    await _apiClient.patch('/projects/$projectId', body: body);
  }

  /// Links a remote GitHub/GitLab repository to a LabPilot project.
  Future<void> linkRepository(int projectId, RemoteRepo repo) async {
    await _apiClient.post('/projects/$projectId/repositories', body: {
      'platform': repo.platform,
      'name': repo.name,
      'owner': repo.owner,
      'url': repo.url,
      'external_id': repo.externalId,
    });
  }

  /// Deletes a project permanently.
  Future<void> deleteProject(int projectId) async {
    await _apiClient.delete('/projects/$projectId');
  }

  /// Unlinks/Deletes a repository from a project.
  Future<void> deleteRepository(int projectId, int repositoryId) async {
    await _apiClient.delete('/projects/$projectId/repositories/$repositoryId');
  }
}
