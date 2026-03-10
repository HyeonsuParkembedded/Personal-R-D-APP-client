class GitHubMilestone {
  final int id;
  final int number;
  final String title;
  final String state;
  final DateTime? dueDate;
  final int openIssues;
  final int closedIssues;
  final String htmlUrl;

  const GitHubMilestone({
    required this.id,
    required this.number,
    required this.title,
    required this.state,
    this.dueDate,
    required this.openIssues,
    required this.closedIssues,
    required this.htmlUrl,
  });

  int get totalIssues => openIssues + closedIssues;

  factory GitHubMilestone.fromJson(Map<String, dynamic> json) {
    return GitHubMilestone(
      id: json['id'] as int,
      number: json['number'] as int,
      title: json['title'] as String,
      state: json['state'] as String,
      dueDate: json['due_on'] != null
          ? DateTime.tryParse(json['due_on'] as String)
          : null,
      openIssues: json['open_issues'] as int,
      closedIssues: json['closed_issues'] as int,
      htmlUrl: json['html_url'] as String,
    );
  }
}
