import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/enums.dart';
import '../repositories/project_repository.dart';
import '../utils/responsive_layout.dart';
import 'gitlab_dashboard_screen.dart';
import 'github_dashboard_screen.dart';
import 'link_repository_screen.dart';
import 'experiment_log_list_screen.dart';
import 'hardware_issue_list_screen.dart';
import '../services/github_service.dart';
import '../services/gitlab_service.dart';
import '../services/settings_service.dart';

class ProjectDetailScreen extends StatefulWidget {
  final int projectId;
  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ProjectRepository _repository = ProjectRepository();
  late Future<ProjectActivitySummary> _summaryFuture;
  late Future<List<TimelineEvent>> _timelineFuture;

  final _githubService = GitHubService();
  final _gitlabService = GitLabService();
  final _settingsService = SettingsService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _summaryFuture = _repository.getProjectSummary(widget.projectId);
      _timelineFuture = _fetchMergedTimeline();
    });
  }

  Future<List<TimelineEvent>> _fetchMergedTimeline() async {
    // 1. Fetch local events
    final localEvents = await _repository.getProjectTimeline(widget.projectId);
    
    // 2. Fetch the summary to know attached repos
    final summary = await _repository.getProjectSummary(widget.projectId);
    
    // 3. Fetch remote commits in parallel for ALL branches
    final githubToken = await _settingsService.getGithubToken();
    final gitlabToken = await _settingsService.getGitlabToken();
    
    final remoteEventFutures = <Future<List<TimelineEvent>>>[];
    
    for (final repo in summary.repositories) {
      if (repo.platform.name == 'github' && githubToken != null && githubToken.isNotEmpty) {
        final owner = repo.owner;
        final name = repo.name.contains('/') ? repo.name.split('/').last : repo.name;
        
        remoteEventFutures.add(_githubService.getRepoBranches(owner, name, githubToken).then((branches) async {
          // Safeguard: Limit to the first 3 branches to prevent API Rate Limit Errors
          final targetBranches = branches.take(3).toList();
          final branchCommitFutures = targetBranches.map((branch) => 
            _githubService.getRepoCommits(owner, name, githubToken, sha: branch)
          );
          
          final nestedCommits = await Future.wait(branchCommitFutures);
          // Flatten lists of GitHubCommit into TimelineEvent
          final allTimelineEvents = <TimelineEvent>[];
          final seenShas = <String>{}; // For deduplication across branches
          
          for (final commits in nestedCommits) {
            for (final c in commits) {
              if (!seenShas.contains(c.sha)) {
                seenShas.add(c.sha);
                allTimelineEvents.add(TimelineEvent(
                  eventType: 'github_commit',
                  title: 'Commit by ${c.authorName}',
                  description: c.message,
                  occurredAt: c.createdAt,
                  projectId: widget.projectId,
                  sourceId: 0,
                ));
              }
            }
          }
          return allTimelineEvents;
        }).catchError((_) => <TimelineEvent>[]));

      } else if (repo.platform.name == 'gitlab' && gitlabToken != null && gitlabToken.isNotEmpty) {
        final path = Uri.encodeComponent('${repo.owner}/${repo.name.contains('/') ? repo.name.split('/').last : repo.name}');
        
        remoteEventFutures.add(_gitlabService.getProjectBranches(path, gitlabToken).then((branches) async {
          // Safeguard: Limit to the first 3 branches to prevent API Rate Limit Errors
          final targetBranches = branches.take(3).toList();
          final branchCommitFutures = targetBranches.map((branch) => 
            _gitlabService.getProjectCommits(path, gitlabToken, refName: branch)
          );
          
          final nestedCommits = await Future.wait(branchCommitFutures);
          // Flatten lists of GitLabCommit into TimelineEvent
          final allTimelineEvents = <TimelineEvent>[];
          final seenIds = <String>{}; // Deduplication
          
          for (final commits in nestedCommits) {
            for (final c in commits) {
              if (!seenIds.contains(c.id)) {
                seenIds.add(c.id);
                allTimelineEvents.add(TimelineEvent(
                  eventType: 'gitlab_commit',
                  title: 'Commit by ${c.authorName}',
                  description: c.message,
                  occurredAt: c.createdAt,
                  projectId: widget.projectId,
                  sourceId: 0,
                ));
              }
            }
          }
          return allTimelineEvents;
        }).catchError((_) => <TimelineEvent>[]));
      }
    }
    
    final remoteEventLists = await Future.wait(remoteEventFutures);
    
    // 4. Merge and sort
    final allEvents = <TimelineEvent>[...localEvents];
    for (final list in remoteEventLists) {
      allEvents.addAll(list);
    }
    
    // Add Experiment Logs
    for (final log in summary.latestExperimentLogs) {
      allEvents.add(TimelineEvent(
        eventType: 'experiment_log',
        title: log.title,
        description: log.objective,
        occurredAt: log.createdAt,
        projectId: widget.projectId,
        sourceId: log.id,
      ));
    }
    
    // Add Hardware Issues
    for (final issue in summary.openHardwareIssues) {
      allEvents.add(TimelineEvent(
        eventType: 'hardware_issue',
        title: issue.title,
        description: issue.symptoms,
        occurredAt: issue.createdAt,
        projectId: widget.projectId,
        sourceId: issue.id,
      ));
    }
    
    allEvents.sort((a, b) => b.occurredAt.compareTo(a.occurredAt)); // Descending
    return allEvents;
  }

  Future<void> _showEditDialog(ProjectDetail project) async {
    final nameCtrl = TextEditingController(text: project.name);
    final descCtrl = TextEditingController(text: project.description);
    ProjectStatus selectedStatus = project.status;
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('프로젝트 수정'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: '프로젝트 이름',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? '이름을 입력해주세요.' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ProjectStatus>(
                  initialValue: selectedStatus,
                  decoration: const InputDecoration(
                    labelText: '상태',
                    border: OutlineInputBorder(),
                  ),
                  items: ProjectStatus.values.map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: status.color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(status.label),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) selectedStatus = val;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    labelText: '설명',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(ctx, true);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await _repository.updateProject(
        widget.projectId,
        name: nameCtrl.text.trim(),
        description: descCtrl.text.trim(),
        status: selectedStatus.name,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ 프로젝트가 수정되었습니다.'),
            backgroundColor: Colors.green,
          ),
        );
        _loadData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('수정 실패: $e')));
      }
    }
  }

  Future<void> _confirmUnlinkRepo(int repoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('저장소 연동 해제'),
        content: const Text('이 저장소 연동을 해제하시겠습니까? 데이터는 삭제되지 않으며 단지 링크만 제거됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('연동 해제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _repository.deleteRepository(widget.projectId, repoId);
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('연동 해제 실패: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로젝트 상세'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
      ),
      body: FutureBuilder<ProjectActivitySummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                '오류 발생:\n${snapshot.error}',
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            );
          } else if (!snapshot.hasData) {
            return const Center(child: Text('데이터가 없습니다.'));
          }

          final summary = snapshot.data!;
          final project = summary.project;

          final isDesktop = ResponsiveLayout.isDesktop(context);

          final leftContent = <Widget>[
            // ---- Action buttons row ----
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showEditDialog(project),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('수정'),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () async {
                    final linked = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            LinkRepositoryScreen(projectId: widget.projectId),
                      ),
                    );
                    if (linked == true) _loadData();
                  },
                  icon: const Icon(Icons.add_link, size: 18),
                  label: const Text('저장소 연결'),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ---- Header ----
            Text(
              project.name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              project.description.isEmpty ? '설명이 없습니다.' : project.description,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Chip(
                label: Text(
                  project.status.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: project.status.color,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            const Divider(height: 32),

            // ---- Stats ----
            const Text(
              '상태 요약',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('저장소', summary.repositoryCount),
                _buildStatCard(
                  '실험 로그',
                  summary.experimentLogCount,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ExperimentLogListScreen(
                          projectId: widget.projectId,
                          projectName: project.name,
                        ),
                      ),
                    );
                    _loadData();
                  },
                ),
                _buildStatCard(
                  '미해결 이슈',
                  summary.hardwareIssueCount,
                  color: summary.openHardwareIssues.isNotEmpty
                      ? Colors.red.shade100
                      : null,
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HardwareIssueListScreen(
                          projectId: widget.projectId,
                          projectName: project.name,
                        ),
                      ),
                    );
                    _loadData();
                  },
                ),
              ],
            ),
            const Divider(height: 32),

            // ---- GitLab Dashboard buttons ----
            if (summary.repositories.any(
              (r) => r.platform.name == 'gitlab',
            )) ...[
              const Text(
                'GitLab 연동',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...summary.repositories
                  .where((r) => r.platform.name == 'gitlab')
                  .map(
                    (repo) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.source,
                        color: Colors.deepOrange,
                      ),
                      title: Text('${repo.owner}/${repo.name}'),
                      subtitle: const Text('이슈, 마일스톤 관리'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GitLabDashboardScreen(
                                    projectPath: Uri.encodeComponent(
                                      '${repo.owner}/${repo.name.contains('/') ? repo.name.split('/').last : repo.name}',
                                    ),
                                    repoDisplayName:
                                        '${repo.owner}/${repo.name.contains('/') ? repo.name.split('/').last : repo.name}',
                                  ),
                                ),
                              );
                            },
                            child: const Text('대시보드'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.link_off,
                              color: Colors.red,
                            ),
                            onPressed: () => _confirmUnlinkRepo(repo.id),
                            tooltip: '연동 해제',
                          ),
                        ],
                      ),
                    ),
                  ),
              const Divider(height: 32),
            ],

            // ---- GitHub Dashboard buttons ----
            if (summary.repositories.any(
              (r) => r.platform.name == 'github',
            )) ...[
              const Text(
                'GitHub 연동',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...summary.repositories
                  .where((r) => r.platform.name == 'github')
                  .map(
                    (repo) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.source,
                        color: Colors.black87,
                      ),
                      title: Text('${repo.owner}/${repo.name}'),
                      subtitle: const Text('이슈, 마일스톤 관리'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FilledButton.tonal(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => GitHubDashboardScreen(
                                    owner: repo.owner,
                                    repo: repo.name.contains('/')
                                        ? repo.name.split('/').last
                                        : repo.name,
                                    repoDisplayName:
                                        '${repo.owner}/${repo.name.contains('/') ? repo.name.split('/').last : repo.name}',
                                  ),
                                ),
                              );
                            },
                            child: const Text('대시보드'),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.link_off,
                              color: Colors.red,
                            ),
                            onPressed: () => _confirmUnlinkRepo(repo.id),
                            tooltip: '연동 해제',
                          ),
                        ],
                      ),
                    ),
                  ),
              const Divider(height: 32),
            ],
          ];

          final rightContent = <Widget>[
            // ---- Timeline ----
            const Text(
              '최근 타임라인',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimelineSection(),
          ];

          if (isDesktop) {
            return AdaptiveContainer(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 5,
                      child: ListView(
                        children: leftContent,
                      ),
                    ),
                    const SizedBox(width: 48),
                    Expanded(
                      flex: 4,
                      child: ListView(
                        children: rightContent,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return AdaptiveContainer(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ...leftContent,
                ...rightContent,
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int count, {
    Color? color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color ?? Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineSection() {
    return FutureBuilder<List<TimelineEvent>>(
      future: _timelineFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            ),
          );
        } else if (snapshot.hasError || !snapshot.hasData) {
          return const Text(
            '타임라인을 불러올 수 없습니다.',
            style: TextStyle(color: Colors.red),
          );
        }

        final timeline = snapshot.data!;
        if (timeline.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              '타임라인 기록이 없습니다.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: timeline.length,
          itemBuilder: (context, index) {
            final event = timeline[index];
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                event.eventType.contains('issue')
                    ? Icons.warning_amber_rounded
                    : event.eventType.contains('log')
                    ? Icons.science
                    : Icons.commit,
                color: Colors.blueGrey,
              ),
              title: Text(event.title),
              subtitle: Text(
                '${event.occurredAt.toLocal().toString().split('.')[0]}\n${event.description}',
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }
}
