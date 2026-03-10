import 'attachment.dart';
import 'enums.dart';

class HardwareIssueRead {
  final int id;
  final int projectId;
  final String title;
  final HardwareIssueCategory category;
  final HardwareIssueSeverity severity;
  final String symptoms;
  final String reproductionConditions;
  final String suspectedCause;
  final String attemptedFixes;
  final HardwareIssueStatus status;
  final String? relatedGitIssue;
  final List<AttachmentRead> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  HardwareIssueRead({
    required this.id,
    required this.projectId,
    required this.title,
    required this.category,
    required this.severity,
    required this.symptoms,
    required this.reproductionConditions,
    required this.suspectedCause,
    required this.attemptedFixes,
    required this.status,
    this.relatedGitIssue,
    required this.attachments,
    required this.createdAt,
    required this.updatedAt,
  });

  factory HardwareIssueRead.fromJson(Map<String, dynamic> json) {
    return HardwareIssueRead(
      id: json['id'] as int,
      projectId: json['project_id'] as int,
      title: json['title'] as String,
      category: parseHardwareIssueCategory(json['category'] as String),
      severity: parseHardwareIssueSeverity(json['severity'] as String),
      symptoms: json['symptoms'] as String,
      reproductionConditions: json['reproduction_conditions'] as String,
      suspectedCause: json['suspected_cause'] as String,
      attemptedFixes: json['attempted_fixes'] as String,
      status: parseHardwareIssueStatus(json['status'] as String),
      relatedGitIssue: json['related_git_issue'] as String?,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => AttachmentRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
