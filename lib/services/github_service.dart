import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/remote_repo.dart';
import '../models/github_issue.dart';
import '../models/github_milestone.dart';
import '../models/github_commit.dart';
import '../models/github_member.dart';

class GitHubService {
  static const _baseUrl = 'https://api.github.com';

  Map<String, String> _headers(String token) => {
    'Authorization': 'Bearer $token',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  };

  Map<String, String> _jsonHeaders(String token) => {
    ..._headers(token),
    'Content-Type': 'application/json',
  };

  Future<List<RemoteRepo>> listRepos(String token) async {
    final repos = <RemoteRepo>[];
    int page = 1;

    while (true) {
      final uri = Uri.parse(
        '$_baseUrl/user/repos?per_page=100&page=$page&sort=updated',
      );
      final response = await http.get(uri, headers: _headers(token));

      if (response.statusCode != 200) {
        throw Exception(
          'GitHub API error ${response.statusCode}: ${response.body}',
        );
      }

      final List<dynamic> data = jsonDecode(response.body);
      if (data.isEmpty) break;

      for (final r in data) {
        repos.add(
          RemoteRepo(
            externalId: r['id'].toString(),
            name: r['name'] as String,
            owner: (r['owner'] as Map)['login'] as String,
            url: r['html_url'] as String,
            platform: 'github',
            description: r['description'] as String?,
          ),
        );
      }

      if (data.length < 100) break;
      page++;
    }
    return repos;
  }

  // ─── Issues ─────────────────────────────────────────────────────────────────

  Future<List<GitHubIssue>> getRepoIssues(
    String owner,
    String repo,
    String token, {
    String state = 'open', // open | closed | all
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/repos/$owner/$repo/issues?state=$state&per_page=50&page=$page',
    );
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub Issues error ${response.statusCode}: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    // GitHub API returns both issues and pull requests. We filter for only issues.
    return data
        .where((i) => i['pull_request'] == null)
        .map((i) => GitHubIssue.fromJson(i as Map<String, dynamic>))
        .toList();
  }

  Future<GitHubIssue> createIssue(
    String owner,
    String repo,
    String token, {
    required String title,
    String body = '',
    int? milestone,
  }) async {
    final uri = Uri.parse('$_baseUrl/repos/$owner/$repo/issues');
    final payload = <String, dynamic>{'title': title};
    if (body.isNotEmpty) payload['body'] = body;
    if (milestone != null) payload['milestone'] = milestone;

    final response = await http.post(
      uri,
      headers: _jsonHeaders(token),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201) {
      throw Exception(
        'GitHub createIssue error ${response.statusCode}: ${response.body}',
      );
    }
    return GitHubIssue.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GitHubIssue> updateIssue(
    String owner,
    String repo,
    String token,
    int number, {
    String? title,
    String? body,
    int? milestone,
    String? state, // 'open' | 'closed'
  }) async {
    final uri = Uri.parse('$_baseUrl/repos/$owner/$repo/issues/$number');
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (body != null) payload['body'] = body;
    if (milestone != null) payload['milestone'] = milestone;
    if (state != null) payload['state'] = state;

    final response = await http.patch(
      uri,
      headers: _jsonHeaders(token),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GitHub updateIssue error ${response.statusCode}: ${response.body}',
      );
    }
    return GitHubIssue.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  // ─── Milestones ─────────────────────────────────────────────────────────────

  Future<List<GitHubMilestone>> getRepoMilestones(
    String owner,
    String repo,
    String token, {
    String state = 'open', // open | closed | all
    int page = 1,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/repos/$owner/$repo/milestones?state=$state&per_page=50&page=$page',
    );
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub Milestones error ${response.statusCode}: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((m) => GitHubMilestone.fromJson(m as Map<String, dynamic>))
        .toList();
  }

  Future<GitHubMilestone> createMilestone(
    String owner,
    String repo,
    String token, {
    required String title,
    DateTime? dueDate,
  }) async {
    final uri = Uri.parse('$_baseUrl/repos/$owner/$repo/milestones');
    final payload = <String, dynamic>{'title': title};
    if (dueDate != null) {
      payload['due_on'] = dueDate.toUtc().toIso8601String();
    }

    final response = await http.post(
      uri,
      headers: _jsonHeaders(token),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 201) {
      throw Exception(
        'GitHub createMilestone error ${response.statusCode}: ${response.body}',
      );
    }
    return GitHubMilestone.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GitHubMilestone> updateMilestone(
    String owner,
    String repo,
    String token,
    int number, {
    String? title,
    DateTime? dueDate,
    String? state, // 'open' | 'closed'
  }) async {
    final uri = Uri.parse('$_baseUrl/repos/$owner/$repo/milestones/$number');
    final payload = <String, dynamic>{};
    if (title != null) payload['title'] = title;
    if (dueDate != null) {
      payload['due_on'] = dueDate.toUtc().toIso8601String();
    }
    if (state != null) payload['state'] = state;

    final response = await http.patch(
      uri,
      headers: _jsonHeaders(token),
      body: jsonEncode(payload),
    );
    if (response.statusCode != 200) {
      throw Exception(
        'GitHub updateMilestone error ${response.statusCode}: ${response.body}',
      );
    }
    return GitHubMilestone.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteMilestone(
    String owner,
    String repo,
    String token,
    int number,
  ) async {
    final uri = Uri.parse('$_baseUrl/repos/$owner/$repo/milestones/$number');
    final response = await http.delete(uri, headers: _headers(token));
    if (response.statusCode != 204) {
      throw Exception(
        'GitHub deleteMilestone error ${response.statusCode}: ${response.body}',
      );
    }
  }

  // ─── Commits ────────────────────────────────────────────────────────────────

  Future<List<String>> getRepoBranches(
    String owner,
    String repo,
    String token,
  ) async {
    final uri = Uri.parse('$_baseUrl/repos/$owner/$repo/branches?per_page=100');
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub Branches error ${response.statusCode}: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data.map((b) => b['name'] as String).toList();
  }

  // ─── Commits ────────────────────────────────────────────────────────────────

  Future<List<GitHubCommit>> getRepoCommits(
    String owner,
    String repo,
    String token, {
    String? sha,
    int page = 1,
  }) async {
    final query = sha != null ? '&sha=$sha' : '';
    final uri =
        Uri.parse('$_baseUrl/repos/$owner/$repo/commits?per_page=50&page=$page$query');
    print('GitHubService: GET $uri');
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      print('GitHubService Error ${response.statusCode}: ${response.body}');
      throw Exception(
        'GitHub Commits error ${response.statusCode}: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    print('GitHubService: Parsed ${data.length} commit JSON objects');
    return data
        .map((c) => GitHubCommit.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  // ─── Members ────────────────────────────────────────────────────────────────

  Future<List<GitHubMember>> getRepoContributors(
    String owner,
    String repo,
    String token,
  ) async {
    final uri = Uri.parse('$_baseUrl/repos/$owner/$repo/contributors?per_page=100');
    final response = await http.get(uri, headers: _headers(token));

    if (response.statusCode != 200) {
      throw Exception(
        'GitHub Contributors error ${response.statusCode}: ${response.body}',
      );
    }

    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((m) => GitHubMember.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
