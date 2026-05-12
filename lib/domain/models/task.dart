import 'package:freezed_annotation/freezed_annotation.dart';

part 'task.freezed.dart';
part 'task.g.dart';

@freezed
class Task with _$Task {
  factory Task({
    required String id,
    required String title,
    String? body,
    bool? completed,
    DateTime? dueAt,
    String? contactId,
    String? contactName,
    String? targetType,
    String? assigneeId,
    DateTime? createdAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  factory Task.fromTwenty(Map<String, dynamic> json) {
    String? bodyText;
    final bodyV2 = json['bodyV2'];
    if (bodyV2 is Map) {
      final blocknote = bodyV2['blocknote'];
      final blockEditor = bodyV2['blockEditor'];
      if (blocknote is String) {
        bodyText = blocknote;
      } else if (blocknote is Map && blocknote['text'] != null) {
        bodyText = blocknote['text'];
      } else if (blockEditor is Map && blockEditor['text'] != null) {
        bodyText = blockEditor['text'];
      } else if (bodyV2['text'] != null) {
        bodyText = bodyV2['text'];
      }
    }

    String? contactId;
    String? contactName;
    String? targetType;

    final taskTargets = json['taskTargets'];
    if (taskTargets != null && taskTargets['edges'] != null) {
      final edges = taskTargets['edges'] as List;
      if (edges.isNotEmpty) {
        final node = edges.first['node'];
        if (node != null) {
          if (node['targetPerson'] != null) {
            targetType = 'person';
            contactId = node['targetPersonId'] ?? node['targetPerson']['id'];
            final person = node['targetPerson'];
            if (person['name'] != null) {
              final name = person['name'];
              final firstName = name['firstName'] ?? '';
              final lastName = name['lastName'] ?? '';
              if (firstName.isNotEmpty || lastName.isNotEmpty) {
                contactName = '$firstName $lastName'.trim();
              }
            }
          } else if (node['targetCompany'] != null) {
            targetType = 'company';
            contactId = node['targetCompanyId'] ?? node['targetCompany']['id'];
            contactName = node['targetCompany']['name'];
          } else if (node['targetOpportunity'] != null) {
            targetType = 'opportunity';
            contactId = node['targetOpportunityId'] ?? node['targetOpportunity']['id'];
            contactName = node['targetOpportunity']['name'];
          } else if (node['person'] != null) {
            targetType = 'person';
            // Fallback for older queries
            contactId = node['personId'] ?? node['person']['id'];
            final person = node['person'];
            if (person['name'] != null) {
              final name = person['name'];
              final firstName = name['firstName'] ?? '';
              final lastName = name['lastName'] ?? '';
              if (firstName.isNotEmpty || lastName.isNotEmpty) {
                contactName = '$firstName $lastName'.trim();
              }
            }
          }
        }
      }
    }

    return Task(
      id: json['id'],
      title: json['title'] ?? '',
      body: bodyText,
      completed: json['status'] == 'DONE',
      dueAt: json['dueAt'] != null ? DateTime.parse(json['dueAt']) : null,
      contactId: contactId,
      contactName: contactName,
      targetType: targetType,
      assigneeId: json['assigneeId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
    );
  }
}
