import 'package:flutter/material.dart';

// ignore_for_file: constant_identifier_names

enum ProjectStatus { idea, design, assembly, bring_up, integration, test, done }

extension ProjectStatusExtension on ProjectStatus {
  String get label {
    switch (this) {
      case ProjectStatus.idea:
        return '아이디어';
      case ProjectStatus.design:
        return '디자인';
      case ProjectStatus.assembly:
        return '조립';
      case ProjectStatus.bring_up:
        return '브링업';
      case ProjectStatus.integration:
        return '통합';
      case ProjectStatus.test:
        return '테스트';
      case ProjectStatus.done:
        return '완료';
    }
  }

  Color get color {
    switch (this) {
      case ProjectStatus.idea:
        return Colors.amber;
      case ProjectStatus.design:
        return Colors.blue;
      case ProjectStatus.assembly:
        return Colors.orange;
      case ProjectStatus.bring_up:
        return Colors.purple;
      case ProjectStatus.integration:
        return Colors.indigo;
      case ProjectStatus.test:
        return Colors.lightGreen;
      case ProjectStatus.done:
        return Colors.green;
    }
  }
}

enum RepositoryPlatform { github, gitlab }

enum HardwareIssueCategory {
  power,
  mcu_board,
  sensor,
  communication,
  storage,
  mechanical_wiring,
  environment_temperature,
  other
}

enum HardwareIssueSeverity { low, medium, high, critical }

enum HardwareIssueStatus { open, investigating, fixed, deferred }

// Helpers to parse from string
ProjectStatus parseProjectStatus(String status) {
  return ProjectStatus.values.firstWhere((e) => e.name == status,
      orElse: () => ProjectStatus.idea);
}

RepositoryPlatform parseRepositoryPlatform(String platform) {
  return RepositoryPlatform.values.firstWhere((e) => e.name == platform,
      orElse: () => RepositoryPlatform.github);
}

HardwareIssueCategory parseHardwareIssueCategory(String category) {
  return HardwareIssueCategory.values.firstWhere((e) => e.name == category,
      orElse: () => HardwareIssueCategory.other);
}

HardwareIssueSeverity parseHardwareIssueSeverity(String severity) {
  return HardwareIssueSeverity.values.firstWhere((e) => e.name == severity,
      orElse: () => HardwareIssueSeverity.low);
}

HardwareIssueStatus parseHardwareIssueStatus(String status) {
  return HardwareIssueStatus.values.firstWhere((e) => e.name == status,
      orElse: () => HardwareIssueStatus.open);
}
