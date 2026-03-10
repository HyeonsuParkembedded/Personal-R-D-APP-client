class GitHubIssue {
  final int id;
  final int number;
  final String title;
  final String body;
  final String state;
  final String? milestone;
  final int? milestoneNumber;
  final String htmlUrl;
  final List<String> labels;
  final DateTime createdAt;

  const GitHubIssue({
    required this.id,
    required this.number,
    required this.title,
    this.body = '',
    required this.state,
    this.milestone,
    this.milestoneNumber,
    required this.htmlUrl,
    this.labels = const [],
    required this.createdAt,
  });

  factory GitHubIssue.fromJson(Map<String, dynamic> json) {
    final mObj = json['milestone'] as Map<String, dynamic>?;
    return GitHubIssue(
      id: json['id'] as int,
      number: json['number'] as int,
      title: json['title'] as String,
      body: (json['body'] as String?) ?? '',
      state: json['state'] as String,
      milestone: mObj?['title'] as String?,
      milestoneNumber: mObj?['number'] as int?,
      htmlUrl: json['html_url'] as String,
      labels: (json['labels'] as List<dynamic>?)
              ?.map((e) => (e as Map)['name'] as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
