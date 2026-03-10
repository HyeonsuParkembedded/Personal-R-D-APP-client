import 'package:flutter/material.dart';
import '../models/enums.dart';
import '../models/project.dart';
import '../repositories/project_repository.dart';
import '../services/settings_service.dart';
import 'project_detail_screen.dart';
import 'settings_screen.dart';

class ProjectListScreen extends StatefulWidget {
  const ProjectListScreen({super.key});

  @override
  State<ProjectListScreen> createState() => _ProjectListScreenState();
}

class _ProjectListScreenState extends State<ProjectListScreen> {
  final ProjectRepository _repository = ProjectRepository();
  final SettingsService _settingsService = SettingsService();
  late Future<List<ProjectListItem>> _projectsFuture;
  bool _hasToken = true; // assume true until checked

  @override
  void initState() {
    super.initState();
    _loadProjects();
    _checkTokens();
  }

  void _loadProjects() {
    setState(() {
      _projectsFuture = _repository.getProjects();
    });
  }

  Future<void> _checkTokens() async {
    final has = await _settingsService.hasAnyToken();
    if (mounted) setState(() => _hasToken = has);
  }

  void _createNewProject() async {
    try {
      await _repository.createProject(
          '새 프로젝트 ${DateTime.now().second}', '자동 생성된 테스트 프로젝트입니다.');
      _loadProjects();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create project: $e')),
        );
      }
    }
  }

  Future<void> _openSettings() async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const SettingsScreen()),
    );
    if (saved == true) _checkTokens();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LabPilot Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'API 토큰 설정',
            onPressed: _openSettings,
          ),
        ],
      ),
      body: Column(
        children: [
          // ---- Token warning banner ----
          if (!_hasToken)
            MaterialBanner(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              content: const Text(
                'GitHub/GitLab 토큰이 설정되지 않았습니다. 저장소 연동을 위해 설정해 주세요.',
                style: TextStyle(fontSize: 13),
              ),
              leading: const Icon(Icons.warning_amber_rounded, color: Colors.orange),
              backgroundColor: Colors.orange.shade50,
              actions: [
                TextButton(
                  onPressed: _openSettings,
                  child: const Text('설정하기'),
                ),
              ],
            ),
          // ---- Project list ----
          Expanded(
            child: FutureBuilder<List<ProjectListItem>>(
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Error loading projects:\n${snapshot.error}',
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('프로젝트가 없습니다. + 버튼을 눌러 추가하세요.'));
                }

                final projects = snapshot.data!;
                return ListView.builder(
                  itemCount: projects.length,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return Dismissible(
                      key: ValueKey(project.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.delete, color: Colors.white, size: 28),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('프로젝트 삭제'),
                            content: Text(
                                '"${project.name}" 프로젝트를 삭제하시겠습니까?\n이 작업은 되돌릴 수 없습니다.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('취소'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red),
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text('삭제'),
                              ),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        try {
                          await _repository.deleteProject(project.id);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${project.name}" 삭제 완료'),
                                backgroundColor: Colors.red.shade400,
                              ),
                            );
                          }
                          _loadProjects();
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('삭제 실패: $e')),
                            );
                          }
                          _loadProjects();
                        }
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            project.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(project.description.isEmpty
                                    ? '설명 없음'
                                    : project.description),
                                const SizedBox(height: 8),
                                Chip(
                                  label: Text(
                                    project.status.label,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  backgroundColor: project.status.color,
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProjectDetailScreen(projectId: project.id),
                              ),
                            );
                            _loadProjects();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewProject,
        child: const Icon(Icons.add),
      ),
    );
  }
}
