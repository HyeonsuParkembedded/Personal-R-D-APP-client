import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../models/hardware_issue.dart';
import '../models/enums.dart';
import '../repositories/hardware_issue_repository.dart';
import '../services/api_client.dart';
import '../utils/responsive_layout.dart';

class HardwareIssueListScreen extends StatefulWidget {
  final int projectId;
  final String projectName;

  const HardwareIssueListScreen({
    super.key,
    required this.projectId,
    required this.projectName,
  });

  @override
  State<HardwareIssueListScreen> createState() =>
      _HardwareIssueListScreenState();
}

class _HardwareIssueListScreenState extends State<HardwareIssueListScreen> {
  final HardwareIssueRepository _repository = HardwareIssueRepository();
  late Future<List<HardwareIssueRead>> _issuesFuture;
  String _statusFilter = 'all'; // 'all', 'open', 'fixed'

  @override
  void initState() {
    super.initState();
    _refreshIssues();
  }

  void _refreshIssues() {
    setState(() {
      _issuesFuture = _repository.getProjectIssues(widget.projectId);
    });
  }

  Future<void> _showIssueForm([HardwareIssueRead? existing]) async {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final symptomsController = TextEditingController(
      text: existing?.symptoms ?? '',
    );
    final reproductionController = TextEditingController(
      text: existing?.reproductionConditions ?? '',
    );
    final causeController = TextEditingController(
      text: existing?.suspectedCause ?? '',
    );
    final fixesController = TextEditingController(
      text: existing?.attemptedFixes ?? '',
    );

    HardwareIssueCategory category =
        existing?.category ?? HardwareIssueCategory.mcu_board;
    HardwareIssueSeverity severity =
        existing?.severity ?? HardwareIssueSeverity.medium;
    HardwareIssueStatus status = existing?.status ?? HardwareIssueStatus.open;
    String? selectedImagePath;

    final bool? saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
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
                  existing == null ? '새 하드웨어 이슈 등록' : '이슈 정보 수정',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '이슈 제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<HardwareIssueCategory>(
                        initialValue: category,
                        decoration: const InputDecoration(
                          labelText: '카테고리',
                          border: OutlineInputBorder(),
                        ),
                        items: HardwareIssueCategory.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() => category = v!),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<HardwareIssueSeverity>(
                        initialValue: severity,
                        decoration: const InputDecoration(
                          labelText: '심각도',
                          border: OutlineInputBorder(),
                        ),
                        items: HardwareIssueSeverity.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.name),
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setModalState(() => severity = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: symptomsController,
                  decoration: const InputDecoration(
                    labelText: '증상',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reproductionController,
                  decoration: const InputDecoration(
                    labelText: '재현 조건',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: causeController,
                  decoration: const InputDecoration(
                    labelText: '의심 원인',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: fixesController,
                  decoration: const InputDecoration(
                    labelText: '시도한 해결책',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                if (existing != null) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<HardwareIssueStatus>(
                    initialValue: status,
                    decoration: const InputDecoration(
                      labelText: '상태',
                      border: OutlineInputBorder(),
                    ),
                    items: HardwareIssueStatus.values
                        .map(
                          (s) =>
                              DropdownMenuItem(value: s, child: Text(s.name)),
                        )
                        .toList(),
                    onChanged: (v) => setModalState(() => status = v!),
                  ),
                ],
                const SizedBox(height: 16),

                // ---- Attachments Section ----
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '첨부 이미지',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        TextButton.icon(
                          onPressed: () async {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.image,
                            );
                            if (result != null &&
                                result.files.single.path != null) {
                              setModalState(() {
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
                            final imageUrl = att.storagePath.replaceFirst(
                              './uploads',
                              '${ApiClient().baseUrl.replaceAll('/api', '')}/uploads',
                            );

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
                                      Container(
                                        color: Colors.grey.shade200,
                                        width: 100,
                                        child: const Icon(Icons.error),
                                      ),
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
                          const Text(
                            '새 이미지 준비됨',
                            style: TextStyle(color: Colors.blue),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () =>
                                setModalState(() => selectedImagePath = null),
                            icon: const Icon(Icons.close, color: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ],
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
                              title: const Text('이슈를 삭제하시겠습니까?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(d, false),
                                  child: const Text('취소'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(d, true),
                                  child: const Text(
                                    '삭제',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _repository.deleteIssue(existing.id);
                            Navigator.pop(ctx, true);
                          }
                        },
                        icon: const Icon(Icons.delete, color: Colors.red),
                        label: const Text(
                          '삭제',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('취소'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () async {
                        if (titleController.text.isEmpty) return;
                        final data = {
                          'project_id': widget.projectId,
                          'title': titleController.text,
                          'category': category.name.toLowerCase(),
                          'severity': severity.name.toLowerCase(),
                          'symptoms': symptomsController.text,
                          'reproduction_conditions':
                              reproductionController.text,
                          'suspected_cause': causeController.text,
                          'attempted_fixes': fixesController.text,
                          'status': status.name.toLowerCase(),
                        };
                        if (!mounted) return;
                        try {
                          if (existing == null) {
                            final issue = await _repository.createIssue(data);
                            if (selectedImagePath != null) {
                              await _repository.uploadAttachment(
                                issue.id,
                                selectedImagePath!,
                              );
                            }
                          } else {
                            await _repository.updateIssue(existing.id, data);
                            if (selectedImagePath != null) {
                              await _repository.uploadAttachment(
                                existing.id,
                                selectedImagePath!,
                              );
                            }
                          }
                          if (!mounted) return;
                          Navigator.pop(ctx, true);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('실패: $e')));
                        }
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
      ),
    );

    if (!mounted) return;
    if (saved == true) {
      _refreshIssues();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.projectName} 하드웨어 이슈')),
      body: AdaptiveContainer(
        child: Column(
          children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'all',
                  label: Text('전체'),
                  icon: Icon(Icons.list),
                ),
                ButtonSegment(
                  value: 'open',
                  label: Text('진행 중'),
                  icon: Icon(Icons.warning_amber),
                ),
                ButtonSegment(
                  value: 'fixed',
                  label: Text('해결됨'),
                  icon: Icon(Icons.check_circle),
                ),
              ],
              selected: {_statusFilter},
              onSelectionChanged: (val) {
                setState(() => _statusFilter = val.first);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => _refreshIssues(),
              child: FutureBuilder<List<HardwareIssueRead>>(
                future: _issuesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('오류 발생: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('등록된 이슈가 없습니다.'));
                  }

                  final allIssues = snapshot.data!;
                  final filteredIssues = allIssues.where((issue) {
                    if (_statusFilter == 'all') return true;
                    if (_statusFilter == 'open') {
                      return issue.status != HardwareIssueStatus.fixed;
                    }
                    return issue.status == HardwareIssueStatus.fixed;
                  }).toList();

                  if (filteredIssues.isEmpty) {
                    return const Center(child: Text('해당하는 이슈가 없습니다.'));
                  }

                  return ListView.builder(
                    itemCount: filteredIssues.length,
                    itemBuilder: (context, index) {
                      final issue = filteredIssues[index];
                      final isFixed = issue.status == HardwareIssueStatus.fixed;

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: ListTile(
                          leading: Icon(
                            isFixed
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: isFixed ? Colors.green : Colors.orange,
                          ),
                          title: Text(
                            issue.title,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              decoration: isFixed
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${issue.category.name} · ${issue.severity.name}\n${issue.symptoms}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (issue.attachments.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 60,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: issue.attachments.length,
                                    itemBuilder: (context, idx) {
                                      final att = issue.attachments[idx];
                                      final imageUrl = att.storagePath.replaceFirst(
                                        './uploads',
                                        '${ApiClient().baseUrl.replaceAll('/api', '')}/uploads',
                                      );
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          right: 8,
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                          child: Image.network(
                                            imageUrl,
                                            width: 60,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) =>
                                                Container(
                                                  color: Colors.grey.shade300,
                                                  width: 60,
                                                ),
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
                          onTap: () => _showIssueForm(issue),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showIssueForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
