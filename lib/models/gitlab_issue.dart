class GitLabIssue {
  final int iid;
  final String title;
  final String description;
  final String state;
  final String? milestone;
  final int? milestoneId;
  final DateTime? dueDate;
  final String webUrl;
  final List<String> labels;
  final DateTime createdAt;

  const GitLabIssue({
    required this.iid,
    required this.title,
    this.description = '',
    required this.state,
    this.milestone,
    this.milestoneId,
    this.dueDate,
    required this.webUrl,
    this.labels = const [],
    required this.createdAt,
  });

  factory GitLabIssue.fromJson(Map<String, dynamic> json) {
    final mObj = json['milestone'] as Map<String, dynamic>?;
    return GitLabIssue(
      iid: json['iid'] as int,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      state: json['state'] as String,
      milestone: mObj?['title'] as String?,
      milestoneId: mObj?['id'] as int?,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      webUrl: json['web_url'] as String,
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
