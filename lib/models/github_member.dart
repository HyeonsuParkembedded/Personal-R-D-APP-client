class GitHubMember {
  final String login;
  final String avatarUrl;
  final String htmlUrl;
  final int contributions;

  GitHubMember({
    required this.login,
    required this.avatarUrl,
    required this.htmlUrl,
    required this.contributions,
  });

  factory GitHubMember.fromJson(Map<String, dynamic> json) {
    return GitHubMember(
      login: json['login'] as String,
      avatarUrl: json['avatar_url'] as String,
      htmlUrl: json['html_url'] as String,
      contributions: json['contributions'] as int? ?? 0,
    );
  }
}
