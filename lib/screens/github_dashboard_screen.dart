import 'package:flutter/material.dart';
import '../models/github_issue.dart';
import '../models/github_milestone.dart';
import '../models/github_commit.dart';
import '../models/github_member.dart';
import '../services/github_service.dart';
import '../services/settings_service.dart';

class GitHubDashboardScreen extends StatefulWidget {
  final String owner;
  final String repo;
  final String repoDisplayName;

  const GitHubDashboardScreen({
    super.key,
    required this.owner,
    required this.repo,
    required this.repoDisplayName,
  });

  @override
  State<GitHubDashboardScreen> createState() => _GitHubDashboardScreenState();
}

class _GitHubDashboardScreenState extends State<GitHubDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _githubService = GitHubService();
  final _settingsService = SettingsService();

  String? _token;

  // Issues state
  List<GitHubIssue> _issues = [];
  bool _issuesLoading = true;
  String? _issuesError;
  String _issueFilter = 'open'; // open | closed | all

  // Milestones state
  List<GitHubMilestone> _milestones = [];
  bool _milestonesLoading = true;
  String? _milestonesError;
  String _milestoneFilter = 'open'; // open | closed | all

  // Commits state
  List<GitHubCommit> _commits = [];
  bool _commitsLoading = true;
  String? _commitsError;
  List<String> _branches = [];
  String? _selectedBranch;

  // Members state
  List<GitHubMember> _members = [];
  bool _membersLoading = true;
  String? _membersError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) _loadCurrent();
    });
    _init();
  }

  Future<void> _init() async {
    _token = await _settingsService.getGithubToken();
    if (_token == null || _token!.isEmpty) {
      setState(() {
        _issuesError = _milestonesError = _commitsError =
            'GitHub 토큰이 없습니다. 설정에서 입력해주세요.';
        _issuesLoading = _milestonesLoading = _commitsLoading = false;
      });
      return;
    }
    try {
      final results = await Future.wait([
        _loadIssues(),
        _loadMilestones(),
        _loadCommits(),
        _loadMembers(),
        _githubService.getRepoBranches(widget.owner, widget.repo, _token!),
      ]);
      if (mounted) {
        setState(() {
          _branches = results[3] as List<String>;
          if (_branches.isNotEmpty && _selectedBranch == null) {
            // Try to default to 'main' or 'master' if available
            if (_branches.contains('main')) {
              _selectedBranch = 'main';
            } else if (_branches.contains('master')) {
              _selectedBranch = 'master';
            } else {
              _selectedBranch = _branches.first;
            }
          }
        });
      }
    } catch (e) {
      print('GitHub init error: $e');
    }
  }

  Future<void> _loadCurrent() async {
    if (_tabController.index == 0) {
      await _loadIssues();
    } else if (_tabController.index == 1) {
      await _loadMilestones();
    } else if (_tabController.index == 2) {
      await _loadCommits();
    } else {
      await _loadMembers();
    }
  }

  Future<void> _loadIssues() async {
    if (_token == null) return;
    setState(() {
      _issuesLoading = true;
      _issuesError = null;
    });
    try {
      final list = await _githubService.getRepoIssues(
        widget.owner,
        widget.repo,
        _token!,
        state: _issueFilter,
      );
      setState(() {
        _issues = list;
        _issuesLoading = false;
      });
    } catch (e) {
      setState(() {
        _issuesError = e.toString();
        _issuesLoading = false;
      });
    }
  }

  Future<void> _loadMilestones() async {
    if (_token == null) return;
    setState(() {
      _milestonesLoading = true;
      _milestonesError = null;
    });
    try {
      final list = await _githubService.getRepoMilestones(
        widget.owner,
        widget.repo,
        _token!,
        state: _milestoneFilter,
      );
      setState(() {
        _milestones = list;
        _milestonesLoading = false;
      });
    } catch (e) {
      setState(() {
        _milestonesError = e.toString();
        _milestonesLoading = false;
      });
    }
  }

  Future<void> _loadCommits() async {
    if (_token == null) return;
    setState(() {
      _commitsLoading = true;
      _commitsError = null;
    });
    print('GitHub: Loading commits for ${widget.owner}/${widget.repo}');
    try {
      final list = await _githubService.getRepoCommits(
        widget.owner,
        widget.repo,
        _token!,
        sha: _selectedBranch,
      );
      print('GitHub: Fetched ${list.length} commits');
      setState(() {
        _commits = list;
        _commitsLoading = false;
      });
    } catch (e) {
      print('GitHub: Commit fetch error: $e');
      setState(() {
        _commitsError = e.toString();
        _commitsLoading = false;
      });
    }
  }

  Future<void> _loadMembers() async {
    if (_token == null) return;
    setState(() {
      _membersLoading = true;
      _membersError = null;
    });
    try {
      final list = await _githubService.getRepoContributors(
        widget.owner,
        widget.repo,
        _token!,
      );
      setState(() {
        _members = list;
        _membersLoading = false;
      });
    } catch (e) {
      setState(() {
        _membersError = e.toString();
        _membersLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onFab() {
    if (_tabController.index == 0) {
      _showIssueForm();
    } else if (_tabController.index == 1) {
      _showMilestoneForm();
    }
  }

  // ─── Issue forms ─────────────────────────────────────────────────────────────

  Future<void> _showIssueForm({GitHubIssue? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final bodyCtrl = TextEditingController(text: existing?.body ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

    GitHubMilestone? selectedMilestone = existing?.milestoneNumber != null
        ? _milestones
              .where((m) => m.number == existing!.milestoneNumber)
              .firstOrNull
        : null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? '이슈 수정' : '새 이슈',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '제목을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: bodyCtrl,
                    decoration: const InputDecoration(
                      labelText: '설명',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<GitHubMilestone?>(
                    initialValue: selectedMilestone,
                    decoration: const InputDecoration(
                      labelText: '마일스톤',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('없음')),
                      ..._milestones
                          .where((m) => m.state == 'open')
                          .map(
                            (m) => DropdownMenuItem(
                              value: m,
                              child: Text(m.title),
                            ),
                          ),
                    ],
                    onChanged: (v) =>
                        setModalState(() => selectedMilestone = v),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (isEdit) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: existing.state == 'open'
                                ? Colors.red
                                : Colors.green,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _toggleIssueState(existing);
                          },
                          icon: Icon(
                            existing.state == 'open'
                                ? Icons.close
                                : Icons.check_circle_outline,
                          ),
                          label: Text(
                            existing.state == 'open' ? '닫기' : '다시 열기',
                          ),
                        ),
                      ],
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          await _saveIssue(
                            existing: existing,
                            title: titleCtrl.text.trim(),
                            body: bodyCtrl.text.trim(),
                            milestoneNumber: selectedMilestone?.number,
                          );
                        },
                        child: Text(isEdit ? '저장' : '생성'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _saveIssue({
    GitHubIssue? existing,
    required String title,
    required String body,
    int? milestoneNumber,
  }) async {
    try {
      if (existing == null) {
        await _githubService.createIssue(
          widget.owner,
          widget.repo,
          _token!,
          title: title,
          body: body,
          milestone: milestoneNumber,
        );
      } else {
        await _githubService.updateIssue(
          widget.owner,
          widget.repo,
          _token!,
          existing.number,
          title: title,
          body: body,
          milestone: milestoneNumber,
        );
      }
      await _loadIssues();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null ? '✅ 이슈가 생성되었습니다.' : '✅ 이슈가 수정되었습니다.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('실패: $e')));
      }
    }
  }

  Future<void> _toggleIssueState(GitHubIssue issue) async {
    try {
      await _githubService.updateIssue(
        widget.owner,
        widget.repo,
        _token!,
        issue.number,
        state: issue.state == 'open' ? 'closed' : 'open',
      );
      await _loadIssues();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('상태 변경 실패: $e')));
      }
    }
  }

  // ─── Milestone forms ──────────────────────────────────────────────────────────

  Future<void> _showMilestoneForm({GitHubMilestone? existing}) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    DateTime? dueDate = existing?.dueDate;
    final formKey = GlobalKey<FormState>();
    final isEdit = existing != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: StatefulBuilder(
          builder: (ctx, setModalState) {
            return Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEdit ? '마일스톤 수정' : '새 마일스톤',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: '제목',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '제목을 입력해주세요.' : null,
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: dueDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setModalState(() => dueDate = picked);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: '마감일',
                        border: OutlineInputBorder(),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(
                            dueDate != null
                                ? dueDate!.toIso8601String().split('T').first
                                : '날짜 선택',
                          ),
                          const Spacer(),
                          if (dueDate != null)
                            GestureDetector(
                              onTap: () => setModalState(() => dueDate = null),
                              child: const Icon(Icons.clear, size: 16),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      if (isEdit) ...[
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: existing.state == 'open'
                                ? Colors.red
                                : Colors.green,
                          ),
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await _toggleMilestoneState(existing);
                          },
                          icon: Icon(
                            existing.state == 'open'
                                ? Icons.close
                                : Icons.check_circle_outline,
                          ),
                          label: Text(existing.state == 'open' ? '닫기' : '활성화'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () async {
                            final ok = await _confirmDelete(ctx, '마일스톤');
                            if (ok) {
                              Navigator.pop(ctx);
                              await _deleteMilestone(existing);
                            }
                          },
                        ),
                      ],
                      const Spacer(),
                      FilledButton(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          Navigator.pop(ctx);
                          await _saveMilestone(
                            existing: existing,
                            title: titleCtrl.text.trim(),
                            dueDate: dueDate,
                          );
                        },
                        child: Text(isEdit ? '저장' : '생성'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // Reuse logic from GitLabDashboardScreen with minor tweaks for GitHub fields
  Future<void> _saveMilestone({
    GitHubMilestone? existing,
    required String title,
    DateTime? dueDate,
  }) async {
    try {
      if (existing == null) {
        await _githubService.createMilestone(
          widget.owner,
          widget.repo,
          _token!,
          title: title,
          dueDate: dueDate,
        );
      } else {
        await _githubService.updateMilestone(
          widget.owner,
          widget.repo,
          _token!,
          existing.number,
          title: title,
          dueDate: dueDate,
        );
      }
      await _loadMilestones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null ? '✅ 마일스톤이 생성되었습니다.' : '✅ 마일스톤이 수정되었습니다.',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('실패: $e')));
      }
    }
  }

  Future<void> _toggleMilestoneState(GitHubMilestone ms) async {
    try {
      await _githubService.updateMilestone(
        widget.owner,
        widget.repo,
        _token!,
        ms.number,
        state: ms.state == 'open' ? 'closed' : 'open',
      );
      await _loadMilestones();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('상태 변경 실패: $e')));
      }
    }
  }

  Future<bool> _confirmDelete(BuildContext ctx, String type) async {
    return await showDialog<bool>(
          context: ctx,
          builder: (d) => AlertDialog(
            title: Text('$type 삭제'),
            content: Text('정말로 삭제하시겠습니까? 이 작업은 되돌릴 수 없습니다.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(d, false),
                child: const Text('취소'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(d, true),
                child: const Text('삭제'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _deleteMilestone(GitHubMilestone ms) async {
    try {
      await _githubService.deleteMilestone(
        widget.owner,
        widget.repo,
        _token!,
        ms.number,
      );
      await _loadMilestones();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🗑️ 마일스톤이 삭제되었습니다.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('삭제 실패: $e')));
      }
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.repoDisplayName, overflow: TextOverflow.ellipsis),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bug_report), text: '이슈'),
            Tab(icon: Icon(Icons.flag), text: '마일스톤'),
            Tab(icon: Icon(Icons.timeline), text: '활동'),
            Tab(icon: Icon(Icons.group), text: '팀원'),
          ],
        ),
      ),
      floatingActionButton: _tabController.index < 2
          ? FloatingActionButton.extended(
              onPressed: _onFab,
              icon: const Icon(Icons.add),
              label: Text(_tabController.index == 0 ? '새 이슈' : '새 마일스톤'),
            )
          : null,
      body: TabBarView(
        controller: _tabController,
        children: [
          _issuesTab(),
          _milestonesTab(),
          _commitsTab(),
          _membersTab(),
        ],
      ),
    );
  }

  Widget _membersTab() {
    return _listBody(
      loading: _membersLoading,
      error: _membersError,
      onRefresh: _loadMembers,
      emptyText: '공헌자가 없습니다.',
      itemCount: _members.length,
      itemBuilder: (i) {
        final member = _members[i];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(member.avatarUrl),
          ),
          title: Text(member.login,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Contributions: ${member.contributions}'),
          trailing: const Icon(Icons.chevron_right, size: 16),
          onTap: () {
            // Optional: open profile URL
          },
        );
      },
    );
  }

  Widget _issuesTab() {
    return Column(
      children: [
        _filterRow(
          selected: _issueFilter,
          options: const {'open': '🟢 열림', 'closed': '🔴 닫힘', 'all': '전체'},
          onChanged: (v) {
            setState(() => _issueFilter = v);
            _loadIssues();
          },
        ),
        Expanded(
          child: _listBody(
            loading: _issuesLoading,
            error: _issuesError,
            onRefresh: _loadIssues,
            emptyText: '이슈가 없습니다.',
            itemCount: _issues.length,
            itemBuilder: (i) {
              final issue = _issues[i];
              return ListTile(
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: issue.state == 'open'
                      ? Colors.green.shade100
                      : Colors.red.shade100,
                  child: Icon(
                    issue.state == 'open' ? Icons.circle : Icons.check_circle,
                    size: 14,
                    color: issue.state == 'open' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text('#${issue.number}  ${issue.title}'),
                subtitle: issue.milestone != null
                    ? Text(
                        '🏁 ${issue.milestone}',
                        style: const TextStyle(fontSize: 12),
                      )
                    : null,
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => _showIssueForm(existing: issue),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _milestonesTab() {
    return Column(
      children: [
        _filterRow(
          selected: _milestoneFilter,
          options: const {'open': '🟢 활성', 'closed': '🔴 닫힘', 'all': '전체'},
          onChanged: (v) {
            setState(() => _milestoneFilter = v);
            _loadMilestones();
          },
        ),
        Expanded(
          child: _listBody(
            loading: _milestonesLoading,
            error: _milestonesError,
            onRefresh: _loadMilestones,
            emptyText: '마일스톤이 없습니다.',
            itemCount: _milestones.length,
            itemBuilder: (i) {
              final ms = _milestones[i];
              final total = ms.totalIssues;
              final progress = total > 0 ? ms.closedIssues / total : 0.0;
              return ListTile(
                leading: Icon(
                  ms.state == 'open' ? Icons.flag : Icons.flag_outlined,
                  color: ms.state == 'open' ? Colors.deepPurple : Colors.grey,
                ),
                title: Text(ms.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ms.dueDate != null)
                      Text(
                        '마감: ${ms.dueDate!.toIso8601String().split('T').first}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey.shade200,
                      color: Colors.green,
                    ),
                    Text(
                      '${ms.closedIssues} / $total 이슈 완료',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right, size: 18),
                onTap: () => _showMilestoneForm(existing: ms),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _commitsTab() {
    return Column(
      children: [
        if (_branches.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(
                  Icons.account_tree_outlined,
                  size: 18,
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                const Text(
                  '브랜치:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBranch,
                      isDense: true,
                      isExpanded: true,
                      items: _branches
                          .map(
                            (b) => DropdownMenuItem(
                              value: b,
                              child: Text(
                                b,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedBranch = val);
                          _loadCommits();
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: _listBody(
            loading: _commitsLoading,
            error: _commitsError,
            onRefresh: _loadCommits,
            emptyText: '최근 활동이 없습니다.',
            itemCount: _commits.length,
            itemBuilder: (i) {
              final commit = _commits[i];
              final isFirst = i == 0;
              final isLast = i == _commits.length - 1;

              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(width: 16),
                    SizedBox(
                      width: 30,
                      child: CustomPaint(
                        painter: _CommitGraphPainter(
                          isFirst: isFirst,
                          isLast: isLast,
                          color: Colors.blue.shade300,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              commit.message.split('\n').first,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  commit.authorName,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${commit.createdAt.month}/${commit.createdAt.day} ${commit.createdAt.hour}:${commit.createdAt.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              commit.shortSha,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                backgroundColor: Colors.blue.shade50,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterRow({
    required String selected,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: options.entries.map((e) {
          final isSelected = e.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(e.value),
              selected: isSelected,
              onSelected: (_) => onChanged(e.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _listBody({
    required bool loading,
    required String? error,
    required VoidCallback onRefresh,
    required String emptyText,
    required int itemCount,
    required Widget Function(int) itemBuilder,
  }) {
    if (loading) return const Center(child: CircularProgressIndicator());
    if (error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      );
    }
    if (itemCount == 0) return Center(child: Text(emptyText));
    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.separated(
        itemCount: itemCount,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (_, i) => itemBuilder(i),
      ),
    );
  }
}

class _CommitGraphPainter extends CustomPainter {
  final bool isFirst;
  final bool isLast;
  final Color color;

  _CommitGraphPainter({
    required this.isFirst,
    required this.isLast,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    const centerY = 24.0;

    if (!isFirst)
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, centerY), paint);
    if (!isLast)
      canvas.drawLine(
        Offset(centerX, centerY),
        Offset(centerX, size.height),
        paint,
      );

    canvas.drawCircle(Offset(centerX, centerY), 5, dotPaint);
    canvas.drawCircle(Offset(centerX, centerY), 8, paint..strokeWidth = 1);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
