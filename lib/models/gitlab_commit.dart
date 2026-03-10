class GitLabCommit {
  final String id;
  final String shortId;
  final String title;
  final String authorName;
  final DateTime createdAt;
  final String message;
  final String webUrl;

  GitLabCommit({
    required this.id,
    required this.shortId,
    required this.title,
    required this.authorName,
    required this.createdAt,
    required this.message,
    required this.webUrl,
  });

  factory GitLabCommit.fromJson(Map<String, dynamic> json) {
    return GitLabCommit(
      id: json['id'],
      shortId: json['short_id'],
      title: json['title'],
      authorName: json['author_name'],
      createdAt: DateTime.parse(json['created_at']),
      message: json['message'] ?? '',
      webUrl: json['web_url'] ?? '',
    );
  }
}
