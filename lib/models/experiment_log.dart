import 'attachment.dart';

class ExperimentLogRead {
  final int id;
  final int projectId;
  final String title;
  final DateTime recordedAt;
  final String objective;
  final String boardFirmwareVersion;
  final String conditions;
  final String result;
  final String issues;
  final String nextAction;
  final String? relatedGitReference;
  final List<AttachmentRead> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExperimentLogRead({
    required this.id,
    required this.projectId,
    required this.title,
    required this.recordedAt,
    required this.objective,
    required this.boardFirmwareVersion,
    required this.conditions,
    required this.result,
    required this.issues,
    required this.nextAction,
    this.relatedGitReference,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ExperimentLogRead.fromJson(Map<String, dynamic> json) {
    return ExperimentLogRead(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      title: json['title'] as String,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      objective: json['objective'] as String,
      boardFirmwareVersion: json['board_firmware_version'] as String,
      conditions: json['conditions'] as String,
      result: json['result'] as String,
      issues: json['issues'] as String,
      nextAction: json['next_action'] as String,
      relatedGitReference: json['related_git_reference'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
