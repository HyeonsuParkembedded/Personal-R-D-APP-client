class GitLabMember {
  final int id;
  final String name;
  final String username;
  final String state;
  final String avatarUrl;
  final String webUrl;
  final int accessLevel;

  GitLabMember({
    required this.id,
    required this.name,
    required this.username,
    required this.state,
    required this.avatarUrl,
    required this.webUrl,
    required this.accessLevel,
  });

  factory GitLabMember.fromJson(Map<String, dynamic> json) {
    return GitLabMember(
      id: json['id'] as int,
      name: json['name'] as String,
      username: json['username'] as String,
      state: json['state'] as String,
      avatarUrl: json['avatar_url'] as String? ?? '',
      webUrl: json['web_url'] as String,
      accessLevel: json['access_level'] as int,
    );
  }

  String get accessLevelLabel {
    switch (accessLevel) {
      case 10: return 'Guest';
      case 20: return 'Reporter';
      case 30: return 'Developer';
      case 40: return 'Maintainer';
      case 50: return 'Owner';
      default: return 'Unknown';
    }
  }
}
