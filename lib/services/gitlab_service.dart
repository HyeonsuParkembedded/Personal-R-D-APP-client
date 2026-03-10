import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/gitlab_issue.dart';
import '../models/gitlab_milestone.dart';
import '../models/remote_repo.dart';

import '../models/gitlab_commit.dart';
import '../models/gitlab_member.dart';

class GitLabService {
  static const _baseUrl = 'https://gitlab.com/api/v4';

  Map<String, String> _headers(String token) => {'PRIVATE-TOKEN': token};
  Map<String, String> _jsonHeaders(String token) => {
        'PRIVATE-TOKEN': token,
        'Content-Type': 'application/json',
      };

  // ─── Repos ──────────────────────────────────────────────────────────────────

  Future<List<RemoteRepo>> listRepos(String token) async {
    final repos = <RemoteRepo>[];
    int page = 1;
    while (true) {
      final uri = Uri.parse(
          '$_baseUrl/projects?membership=true&per_page=100&page=$page&order_by=last_activity_at');
      final response = await http.get(uri, headers: _headers(token));
      if (response.statusCode != 200) {
        throw Exception('GitLab API error ${response.statusCode}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) break;
      for (final r in data) {
        final namespace = r['namespace'] as Map<String, dynamic>?;
        final owner = namespace?['path'] ?? namespace?['name'] ?? 'unknown';
        repos.add(RemoteRepo(
          externalId: r['id'].toString(),
          name: r['path'] as String,
          owner: owner as String,
          url: r['web_url'] as String,
          platform: 'gitlab',
          description: r['description'] as String?,
        ));
      }
      if (data.length < 100) break;
      page++;
    }
    return repos;
  }

  // ─── Issues ─────────────────────────────────────────────────────────────────

  Future<List<GitLabIssue>> getProjectIssues(
    String projectId,
    String token, {
    String state = 'opened', // opened | closed | all
  }) async {
    final issues = <GitLabIssue>[];
    int page = 1;
    while (true) {
      final uri = Uri.parse(
          '$_baseUrl/projects/$projectId/issues?state=$state&per_page=50&page=$page');
      final response = await http.get(uri, headers: _headers(token));
      if (response.statusCode != 200) {
        throw Exception(
            'GitLab Issues error ${response.statusCode}: ${response.body}');
      }
      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) break;
      for (final i in data) {
        issues.add(GitLabIssue.fromJson(i as Map<String, dynamic>));
      }
      if (data.length < 50) break;
      page++;
    }
    return issues;
  }

  Future<GitLabIssue> createIssue(
    String projectId,
    String token, {
    required String title,
    String description = '',
    int? milestoneId,
  }) async {
    final uri = Uri.parse('$_baseUrl/projects/$projectId/issues');
    final body = <String, dynamic>{'title': title};
    if (description.isNotEmpty) body['description'] = description;
    if (milestoneId != null) body['milestone_id'] = milestoneId;

    final response = await http.post(uri,
        headers: _jsonHeaders(token), body: jsonEncode(body));
    if (response.statusCode != 201) {
      throw Exception(
          'GitLab createIssue error ${response.statusCode}: ${response.body}');
    }
    return GitLabIssue.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<GitLabIssue> updateIssue(
    String projectId,
    String token,
    int iid, {
    String? title,
    String? description,
    int? milestoneId,
    String? stateEvent, // 'close' | 'reopen'
  }) async {
    final uri = Uri.parse('$_baseUrl/projects/$projectId/issues/$iid');
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (description != null) body['description'] = description;
    if (milestoneId != null) body['milestone_id'] = milestoneId;
    if (stateEvent != null) body['state_event'] = stateEvent;

    final response = await http.put(uri,
        headers: _jsonHeaders(token), body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw Exception(
          'GitLab updateIssue error ${response.statusCode}: ${response.body}');
    }
    return GitLabIssue.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  // ─── Milestones ─────────────────────────────────────────────────────────────

  Future<List<GitLabMilestone>> getProjectMilestones(
    String projectId,
    String token, {
    String state = 'active', // active | closed | all (no statistics in 'all')
  }) async {
    final uri = Uri.parse(
        '$_baseUrl/projects/$projectId/milestones?state=$state&per_page=50&with_stats=true');
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode != 200) {
      throw Exception(
          'GitLab Milestones error ${response.statusCode}: ${response.body}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((m) => GitLabMilestone.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<GitLabMilestone> createMilestone(
    String projectId,
    String token, {
    required String title,
    DateTime? dueDate,
  }) async {
    final uri = Uri.parse('$_baseUrl/projects/$projectId/milestones');
    final body = <String, dynamic>{'title': title};
    if (dueDate != null) {
      body['due_date'] = dueDate.toIso8601String().split('T').first;
    }
    final response = await http.post(uri,
        headers: _jsonHeaders(token), body: jsonEncode(body));
    if (response.statusCode != 201) {
      throw Exception(
          'GitLab createMilestone error ${response.statusCode}: ${response.body}');
    }
    return GitLabMilestone.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<GitLabMilestone> updateMilestone(
    String projectId,
    String token,
    int milestoneId, {
    String? title,
    DateTime? dueDate,
    String? stateEvent, // 'close' | 'activate'
  }) async {
    final uri = Uri.parse(
        '$_baseUrl/projects/$projectId/milestones/$milestoneId');
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (dueDate != null) {
      body['due_date'] = dueDate.toIso8601String().split('T').first;
    }
    if (stateEvent != null) body['state_event'] = stateEvent;

    final response = await http.put(uri,
        headers: _jsonHeaders(token), body: jsonEncode(body));
    if (response.statusCode != 200) {
      throw Exception(
          'GitLab updateMilestone error ${response.statusCode}: ${response.body}');
    }
    return GitLabMilestone.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  /// Delete an issue. Requires Maintainer/Owner or admin permissions on GitLab.
  Future<void> deleteIssue(
      String projectId, String token, int iid) async {
    final uri =
        Uri.parse('$_baseUrl/projects/$projectId/issues/$iid');
    final response =
        await http.delete(uri, headers: _headers(token));
    if (response.statusCode != 204 && response.statusCode != 200) {
      throw Exception(
          'GitLab deleteIssue error ${response.statusCode}: ${response.body}');
    }
  }

  /// Delete a milestone.
  Future<void> deleteMilestone(
      String projectId, String token, int milestoneId) async {
    final uri = Uri.parse(
        '$_baseUrl/projects/$projectId/milestones/$milestoneId');
    final response =
        await http.delete(uri, headers: _headers(token));
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
          'GitLab deleteMilestone error ${response.statusCode}: ${response.body}');
    }
  }

  // ─── Commits ────────────────────────────────────────────────────────────────

  Future<List<String>> getProjectBranches(
    String projectId,
    String token,
  ) async {
    final uri =
        Uri.parse('$_baseUrl/projects/$projectId/repository/branches?per_page=100');
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      throw Exception(
          'GitLab Branches error ${response.statusCode}: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((b) => b['name'] as String).toList();
  }

  // ─── Commits ────────────────────────────────────────────────────────────────

  Future<List<GitLabCommit>> getProjectCommits(
    String projectId,
    String token, {
    String? refName, // Branch, tag, or SHA
    int perPage = 50,
    int page = 1,
  }) async {
    final query = refName != null ? '&ref_name=$refName' : '';
    final uri = Uri.parse(
        '$_baseUrl/projects/$projectId/repository/commits?per_page=$perPage&page=$page$query');
    final response = await http.get(uri, headers: _headers(token));
    if (response.statusCode != 200) {
      throw Exception(
          'GitLab Commits error ${response.statusCode}: ${response.body}');
    }
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((c) => GitLabCommit.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ─── Members ────────────────────────────────────────────────────────────────

  Future<List<GitLabMember>> getProjectMembers(
    String projectId,
    String token,
  ) async {
    final uri = Uri.parse('$_baseUrl/projects/$projectId/members?per_page=100');
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      throw Exception(
        'GitLab Members error ${response.statusCode}: ${response.body}');
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((m) => GitLabMember.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
