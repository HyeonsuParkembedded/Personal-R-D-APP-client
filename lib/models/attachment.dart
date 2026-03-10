class AttachmentRead {
  final int id;
  final String fileName;
  final String contentType;
  final String storagePath;
  final int? experimentLogId;
  final int? hardwareIssueId;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttachmentRead({
    required this.id,
    required this.fileName,
    required this.contentType,
    required this.storagePath,
    this.experimentLogId,
    this.hardwareIssueId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttachmentRead.fromJson(Map<String, dynamic> json) {
    return AttachmentRead(
      id: json['id'] as int,
      fileName: json['file_name'] as String,
      contentType: json['content_type'] as String,
      storagePath: json['storage_path'] as String,
      experimentLogId: json['experiment_log_id'] as int?,
      hardwareIssueId: json['hardware_issue_id'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
