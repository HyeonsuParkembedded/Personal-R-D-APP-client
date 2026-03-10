import 'enums.dart';
import 'experiment_log.dart';
import 'hardware_issue.dart';

class ProjectListItem {
  final int id;
  final String name;
  final String description;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectListItem({
    required this.id,
    required this.name,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectListItem.fromJson(Map<String, dynamic> json) {
    return ProjectListItem(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      status: parseProjectStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}

class ProjectRepositorySummary {
  final int id;
  final String name;
  final String owner;
  final RepositoryPlatform platform;
  final String url;
  final DateTime? lastSyncedAt;

  ProjectRepositorySummary({
    required this.id,
    required this.name,
    required this.owner,
    required this.platform,
    required this.url,
    this.lastSyncedAt,
  });

  factory ProjectRepositorySummary.fromJson(Map<String, dynamic> json) {
    return ProjectRepositorySummary(
      id: json['id'] as int,
      name: json['name'] as String,
      owner: json['owner'] as String,
      platform: parseRepositoryPlatform(json['platform'] as String),
      url: json['url'] as String,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
    );
  }
}

class ProjectDetail extends ProjectListItem {
  final List<ProjectRepositorySummary> repositories;

  ProjectDetail({
    required super.id,
    required super.name,
    required super.description,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    required this.repositories,
  });

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    return ProjectDetail(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      status: parseProjectStatus(json['status'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      repositories: (json['repositories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectRepositorySummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TimelineEvent {
  final String eventType;
  final DateTime occurredAt;
  final String title;
  final String description;
  final int projectId;
  final int sourceId;

  TimelineEvent({
    required this.eventType,
    required this.occurredAt,
    required this.title,
    required this.description,
    required this.projectId,
    required this.sourceId,
  });

  factory TimelineEvent.fromJson(Map<String, dynamic> json) {
    return TimelineEvent(
      eventType: json['event_type'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      title: json['title'] as String,
      description: json['description'] as String,
      projectId: json['project_id'] as int,
      sourceId: json['source_id'] as int,
    );
  }
}

class ProjectActivitySummary {
  final ProjectDetail project;
  final List<ProjectRepositorySummary> repositories;
  final List<ExperimentLogRead> latestExperimentLogs;
  final List<HardwareIssueRead> openHardwareIssues;
  final int repositoryCount;
  final int experimentLogCount;
  final int hardwareIssueCount;

  ProjectActivitySummary({
    required this.project,
    required this.repositories,
    required this.latestExperimentLogs,
    required this.openHardwareIssues,
    required this.repositoryCount,
    required this.experimentLogCount,
    required this.hardwareIssueCount,
  });

  factory ProjectActivitySummary.fromJson(Map<String, dynamic> json) {
    return ProjectActivitySummary(
      project: ProjectDetail.fromJson(json['project'] as Map<String, dynamic>),
      repositories: (json['repositories'] as List<dynamic>?)
              ?.map((e) =>
                  ProjectRepositorySummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      latestExperimentLogs: (json['latest_experiment_logs'] as List<dynamic>?)
              ?.map((e) => ExperimentLogRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      openHardwareIssues: (json['open_hardware_issues'] as List<dynamic>?)
              ?.map((e) => HardwareIssueRead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      repositoryCount: json['repository_count'] as int,
      experimentLogCount: json['experiment_log_count'] as int,
      hardwareIssueCount: json['hardware_issue_count'] as int,
    );
  }
}
