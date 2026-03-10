import '../models/hardware_issue.dart';
import '../services/api_client.dart';

class HardwareIssueRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<HardwareIssueRead>> getProjectIssues(int projectId) async {
    final response = await _apiClient.get('/hardware-issues?project_id=$projectId');
    return (response as List).map((json) => HardwareIssueRead.fromJson(json)).toList();
  }

  Future<HardwareIssueRead> createIssue(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/hardware-issues', body: data);
    return HardwareIssueRead.fromJson(response);
  }

  Future<HardwareIssueRead> updateIssue(int issueId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/hardware-issues/$issueId', body: data);
    return HardwareIssueRead.fromJson(response);
  }

  Future<void> deleteIssue(int issueId) async {
    await _apiClient.delete('/hardware-issues/$issueId');
  }

  Future<void> uploadAttachment(int issueId, String filePath) async {
    await _apiClient.uploadFile('/hardware-issues/$issueId/attachments', filePath);
  }
}
