import '../models/experiment_log.dart';
import '../services/api_client.dart';

class ExperimentLogRepository {
  final ApiClient _apiClient = ApiClient();

  Future<List<ExperimentLogRead>> getProjectLogs(int projectId) async {
    final response = await _apiClient.get('/experiment-logs?project_id=$projectId');
    return (response as List).map((json) => ExperimentLogRead.fromJson(json)).toList();
  }

  Future<ExperimentLogRead> createLog(Map<String, dynamic> data) async {
    final response = await _apiClient.post('/experiment-logs', body: data);
    return ExperimentLogRead.fromJson(response);
  }

  Future<ExperimentLogRead> updateLog(int logId, Map<String, dynamic> data) async {
    final response = await _apiClient.patch('/experiment-logs/$logId', body: data);
    return ExperimentLogRead.fromJson(response);
  }

  Future<void> deleteLog(int logId) async {
    await _apiClient.delete('/experiment-logs/$logId');
  }

  Future<void> uploadAttachment(int logId, String filePath) async {
    await _apiClient.uploadFile('/experiment-logs/$logId/attachments', filePath);
  }
}
