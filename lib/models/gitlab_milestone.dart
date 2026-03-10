class GitLabMilestone {
  final int id;
  final int iid;
  final String title;
  final String state;
  final DateTime? dueDate;
  final int openIssuesCount;
  final int closedIssuesCount;
  final String webUrl;

  const GitLabMilestone({
    required this.id,
    required this.iid,
    required this.title,
    required this.state,
    this.dueDate,
    required this.openIssuesCount,
    required this.closedIssuesCount,
    required this.webUrl,
  });

  int get totalIssues => openIssuesCount + closedIssuesCount;

  factory GitLabMilestone.fromJson(Map<String, dynamic> json) {
    final stats = json['statistics'] as Map<String, dynamic>?;
    return GitLabMilestone(
      id: json['id'] as int,
      iid: json['iid'] as int,
      title: json['title'] as String,
      state: json['state'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String)
          : null,
      openIssuesCount: (stats?['open_issues_count'] as int?) ?? 0,
      closedIssuesCount: (stats?['closed_issues_count'] as int?) ?? 0,
      webUrl: json['web_url'] as String,
    );
  }
}
