import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/experiment_log.dart';
import '../repositories/experiment_log_repository.dart';
import '../services/api_client.dart';
import '../utils/responsive_layout.dart';

class ExperimentLogListScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const ExperimentLogListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<ExperimentLogListScreen> createState() => _ExperimentLogListScreenState();
}

class _ExperimentLogListScreenState extends State<ExperimentLogListScreen> {
  final ExperimentLogRepository _repository = ExperimentLogRepository();
  late Future<List<ExperimentLogRead>> _logsFuture;

  @override
  void initState() {
    super.initState();
    _refreshLogs();
  }

  void _refreshLogs() {
    setState(() {
      _logsFuture = _repository.getProjectLogs(widget.projectId);
    });
  }

  Future<void> _showLogForm([ExperimentLogRead? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final objectiveController = TextEditingController(text: existing?.objective ?? '');
    final versionController = TextEditingController(text: existing?.boardFirmwareVersion ?? 'v1.0.0');
    final conditionsController = TextEditingController(text: existing?.conditions ?? '');
    final resultController = TextEditingController(text: existing?.result ?? '');
    final issuesController = TextEditingController(text: existing?.issues ?? '');
    final nextActionController = TextEditingController(text: existing?.nextAction ?? '');
    String? selectedImagePath;

    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                existing == null ? '새 실험 로그 작성' : '실험 로그 수정',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: '제목', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: objectiveController,
                decoration: const InputDecoration(labelText: '실험 목적', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: versionController,
                decoration: const InputDecoration(labelText: '보드/펌웨어 버전', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: conditionsController,
                decoration: const InputDecoration(labelText: '실험 조건', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: resultController,
                decoration: const InputDecoration(labelText: '실험 결과', border: OutlineInputBorder()),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: issuesController,
                decoration: const InputDecoration(labelText: '발생 이슈', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nextActionController,
                decoration: const InputDecoration(labelText: '향후 조치', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // ---- Attachments Section ----
              StatefulBuilder(
                builder: (context, setDialogState) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('첨부 이미지', style: TextStyle(fontWeight: FontWeight.bold)),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: () async {
                              final result = await FilePicker.platform.pickFiles(type: FileType.image);
                              if (result != null && result.files.single.path != null) {
                                setDialogState(() {
                                  selectedImagePath = result.files.single.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('이미지 추가'),
                          ),
                        ],
                      ),
                      if (existing != null && existing.attachments.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: existing.attachments.length,
                            itemBuilder: (ctx, idx) {
                              final att = existing.attachments[idx];
                              // Map storage_path (e.g. ./uploads/experiment_logs/1/uuid_file.png)
                              // to URL (e.g. http://127.0.0.1:8000/uploads/experiment_logs/1/uuid_file.png)
                              final imageUrl = att.storagePath.replaceFirst('./uploads', '${ApiClient().baseUrl.replaceAll('/api', '')}/uploads');
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    imageUrl,
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) =>
                                        Container(color: Colors.grey.shade200, width: 100, child: const Icon(Icons.error)),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      if (selectedImagePath != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(selectedImagePath!),
                                height: 60,
                                width: 60,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('새 이미지 준비됨', style: TextStyle(color: Colors.blue)),
                            const Spacer(),
                            IconButton(
                              onPressed: () => setDialogState(() => selectedImagePath = null),
                              icon: const Icon(Icons.close, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  if (existing != null)
                    TextButton.icon(
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: ctx,
                          builder: (d) => AlertDialog(
                            title: const Text('삭제하시겠습니까?'),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(d, false), child: const Text('취소')),
                              TextButton(onPressed: () => Navigator.pop(d, true), child: const Text('삭제', style: TextStyle(color: Colors.red))),
                            ],
                          ),
                        );
                        if (confirm == true) {
                          await _repository.deleteLog(existing.id);
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx, true);
                        }
                      },
                      icon: const Icon(Icons.delete, color: Colors.red),
                      label: const Text('삭제', style: TextStyle(color: Colors.red)),
                    ),
                  const Spacer(),
                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('취소')),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () async {
                      if (titleController.text.isEmpty) return;
                      final data = {
                        'project_id': widget.projectId,
                        'title': titleController.text,
                        'objective': objectiveController.text,
                        'board_firmware_version': versionController.text,
                        'conditions': conditionsController.text,
                        'result': resultController.text,
                        'issues': issuesController.text,
                        'next_action': nextActionController.text,
                        'recorded_at': existing?.recordedAt.toIso8601String() ?? DateTime.now().toIso8601String(),
                      };
                      if (existing == null) {
                        final log = await _repository.createLog(data);
                        if (selectedImagePath != null) {
                          await _repository.uploadAttachment(log.id, selectedImagePath!);
                        }
                      } else {
                        await _repository.updateLog(existing.id, data);
                        if (selectedImagePath != null) {
                          await _repository.uploadAttachment(existing.id, selectedImagePath!);
                        }
                      }
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx, true);
                    },
                    child: const Text('저장'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (saved == true) {
      _refreshLogs();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.projectName} 실험 로그'),
      ),
      body: AdaptiveContainer(
        child: RefreshIndicator(
          onRefresh: () async => _refreshLogs(),
        child: FutureBuilder<List<ExperimentLogRead>>(
          future: _logsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('오류 발생: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('작성된 실험 로그가 없습니다.'));
            }

            final logs = snapshot.data!;
            return ListView.builder(
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(log.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('날짜: ${log.recordedAt.toLocal().toString().split(' ')[0]}'),
                        Text('결과: ${log.result}', maxLines: 2, overflow: TextOverflow.ellipsis),
                        if (log.attachments.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 60,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: log.attachments.length,
                              itemBuilder: (context, idx) {
                                final att = log.attachments[idx];
                                final imageUrl = att.storagePath.replaceFirst('./uploads', '${ApiClient().baseUrl.replaceAll('/api', '')}/uploads');
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: Image.network(
                                      imageUrl,
                                      width: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder: (c, e, s) => Container(color: Colors.grey.shade300, width: 60),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showLogForm(log),
                  ),
                );
              },
            );
          },
        ),
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showLogForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
