import 'package:flutter/material.dart';
import '../models/remote_repo.dart';
import '../repositories/project_repository.dart';
import '../services/github_service.dart';
import '../services/gitlab_service.dart';
import '../services/settings_service.dart';
import '../utils/responsive_layout.dart';

class LinkRepositoryScreen extends StatefulWidget {
  final int projectId;
  const LinkRepositoryScreen({super.key, required this.projectId});

  @override
  State<LinkRepositoryScreen> createState() => _LinkRepositoryScreenState();
}

class _LinkRepositoryScreenState extends State<LinkRepositoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _settingsService = SettingsService();
  final _projectRepo = ProjectRepository();

  List<RemoteRepo>? _githubRepos;
  List<RemoteRepo>? _gitlabRepos;
  String? _githubError;
  String? _gitlabError;
  bool _loadingGithub = false;
  bool _loadingGitlab = false;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        if (_tabController.index == 0 && _githubRepos == null) _loadGithub();
        if (_tabController.index == 1 && _gitlabRepos == null) _loadGitlab();
      }
    });
    _loadGithub();
  }

  Future<void> _loadGithub() async {
    final token = await _settingsService.getGithubToken();
    if (token == null || token.isEmpty) {
      setState(
        () => _githubError = 'GitHub 토큰이 설정되지 않았습니다.\n설정 화면에서 토큰을 입력해주세요.',
      );
      return;
    }
    setState(() {
      _loadingGithub = true;
      _githubError = null;
    });
    try {
      final repos = await GitHubService().listRepos(token);
      setState(() {
        _githubRepos = repos;
        _loadingGithub = false;
      });
    } catch (e) {
      setState(() {
        _githubError = 'GitHub 로드 실패: $e';
        _loadingGithub = false;
      });
    }
  }

  Future<void> _loadGitlab() async {
    final token = await _settingsService.getGitlabToken();
    if (token == null || token.isEmpty) {
      setState(
        () => _gitlabError = 'GitLab 토큰이 설정되지 않았습니다.\n설정 화면에서 토큰을 입력해주세요.',
      );
      return;
    }
    setState(() {
      _loadingGitlab = true;
      _gitlabError = null;
    });
    try {
      final repos = await GitLabService().listRepos(token);
      setState(() {
        _gitlabRepos = repos;
        _loadingGitlab = false;
      });
    } catch (e) {
      setState(() {
        _gitlabError = 'GitLab 로드 실패: $e';
        _loadingGitlab = false;
      });
    }
  }

  Future<void> _linkRepo(RemoteRepo repo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('저장소 연결'),
        content: Text('"${repo.owner}/${repo.name}" 저장소를 이 프로젝트에 연결하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('연결'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await _projectRepo.linkRepository(widget.projectId, repo);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${repo.owner}/${repo.name} 연결 완료!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('연결 실패: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  List<RemoteRepo> _filtered(List<RemoteRepo>? repos) {
    if (repos == null) return [];
    if (_search.isEmpty) return repos;
    final q = _search.toLowerCase();
    return repos
        .where(
          (r) =>
              r.name.toLowerCase().contains(q) ||
              r.owner.toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('저장소 연결'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.code), text: 'GitHub'),
            Tab(icon: Icon(Icons.merge_type), text: 'GitLab'),
          ],
        ),
      ),
      body: AdaptiveContainer(
        child: Column(
          children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: '저장소 이름 또는 소유자 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _repoList(
                  repos: _filtered(_githubRepos),
                  loading: _loadingGithub,
                  error: _githubError,
                  onRefresh: _loadGithub,
                  icon: Icons.code,
                  accentColor: Colors.black87,
                ),
                _repoList(
                  repos: _filtered(_gitlabRepos),
                  loading: _loadingGitlab,
                  error: _gitlabError,
                  onRefresh: _loadGitlab,
                  icon: Icons.merge_type,
                  accentColor: Colors.deepOrange,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _repoList({
    required List<RemoteRepo> repos,
    required bool loading,
    required String? error,
    required VoidCallback onRefresh,
    required IconData icon,
    required Color accentColor,
  }) {
    if (loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('저장소 불러오는 중...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(error, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('다시 시도'),
              ),
            ],
          ),
        ),
      );
    }

    if (repos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('저장소가 없거나 검색 결과가 없습니다.'),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: repos.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final repo = repos[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: accentColor.withAlpha(25), // 0.1 opacity
            child: Icon(icon, color: accentColor, size: 20),
          ),
          title: Text(
            '${repo.owner}/${repo.name}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: repo.description != null && repo.description!.isNotEmpty
              ? Text(
                  repo.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              : null,
          trailing: FilledButton.tonal(
            onPressed: () => _linkRepo(repo),
            child: const Text('연결'),
          ),
        );
      },
    );
  }
}
