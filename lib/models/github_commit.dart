class GitHubCommit {
  final String sha;
  final String message;
  final String authorName;
  final DateTime createdAt;
  final String htmlUrl;

  const GitHubCommit({
    required this.sha,
    required this.message,
    required this.authorName,
    required this.createdAt,
    required this.htmlUrl,
  });

  String get shortSha => sha.length > 7 ? sha.substring(0, 7) : sha;

  factory GitHubCommit.fromJson(Map<String, dynamic> json) {
    final commitObj = json['commit'] as Map<String, dynamic>;
    final authorObj = commitObj['author'] as Map<String, dynamic>;
    return GitHubCommit(
      sha: json['sha'] as String,
      message: commitObj['message'] as String,
      authorName: authorObj['name'] as String,
      createdAt: DateTime.parse(authorObj['date'] as String),
      htmlUrl: json['html_url'] as String,
    );
  }
}
