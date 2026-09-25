import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gql/language.dart' show parseString;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/domain/models/task.dart';

import 'package:pocketcrm/data/graphql/crm_queries.dart';

class TwentyTaskRepository {
  final BaseGraphQLConnector _base;

  TwentyTaskRepository(this._base);

  Future<List<Task>> getOverdueTasks() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final memberId = await _base.getCurrentMemberId();

    final conditions = [
      '{ dueAt: { lt: "${startOfToday.toIso8601String()}" } }',
      '{ status: { neq: DONE } }',
      if (memberId != null) '{ assigneeId: { eq: "$memberId" } }',
    ];

    final String query = getOverdueTasksQuery(conditions.join('\n              '));

    final options = QueryOptions(
      document: parseString(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await _base.queryWithRefresh(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final edges = result.data?['tasks']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) => Task.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Task>> getTodayTasks() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final memberId = await _base.getCurrentMemberId();

    final conditions = [
      '{ dueAt: { gte: "${startOfToday.toIso8601String()}" } }',
      '{ dueAt: { lt: "${endOfToday.toIso8601String()}" } }',
      '{ status: { neq: DONE } }',
      if (memberId != null) '{ assigneeId: { eq: "$memberId" } }',
    ];

    final String query = getTodayTasksQuery(conditions.join('\n              '));

    final options = QueryOptions(
      document: parseString(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await _base.queryWithRefresh(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final edges = result.data?['tasks']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) => Task.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Task>> getTomorrowTasks() async {
    final now = DateTime.now();
    final startOfTomorrow = DateTime(
      now.year,
      now.month,
      now.day,
    ).add(const Duration(days: 1));
    final endOfTomorrow = startOfTomorrow.add(const Duration(days: 1));
    final memberId = await _base.getCurrentMemberId();

    final conditions = [
      '{ dueAt: { gte: "${startOfTomorrow.toIso8601String()}" } }',
      '{ dueAt: { lt: "${endOfTomorrow.toIso8601String()}" } }',
      '{ status: { neq: DONE } }',
      if (memberId != null) '{ assigneeId: { eq: "$memberId" } }',
    ];

    final String query = getTomorrowTasksQuery(conditions.join('\n              '));

    final options = QueryOptions(
      document: parseString(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await _base.queryWithRefresh(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final edges = result.data?['tasks']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) => Task.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Task>> getTasks({bool? completed}) async {
    const String query = getTasksQuery;

    final memberId = await _base.getCurrentMemberId();

    final List<Map<String, dynamic>> conditions = [];
    if (completed != null) {
      conditions.add({'status': {'eq': completed ? 'DONE' : 'TODO'}});
    }
    if (memberId != null) {
      conditions.add({'assigneeId': {'eq': memberId}});
    }

    Map<String, dynamic>? filter;
    if (conditions.isNotEmpty) {
      filter = conditions.length == 1
          ? conditions.first
          : {'and': conditions};
    }

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {if (filter != null) 'filter': filter},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['tasks']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) => Task.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<Task> createTask({
    required String title,
    String? body,
    DateTime? dueAt,
    String? contactId,
    String? assigneeId,
  }) async {
    const String mutation = createTaskMutation;

    final input = <String, dynamic>{'title': title};
    
    // Assign automatically if not provided explicitly, but only for email auth (currentMemberId exists)
    final targetAssigneeId = assigneeId ?? await _base.getCurrentMemberId();
    if (targetAssigneeId != null) {
      input['assigneeId'] = targetAssigneeId;
    }
    if (body != null) {
      final blockNodeJson = jsonEncode([
        {
          "type": "paragraph",
          "content": [
            {"type": "text", "text": body, "styles": {}},
          ],
        },
      ]);
      input['bodyV2'] = {'blocknote': blockNodeJson};
    }
    if (dueAt != null) {
      final utcDueAt = dueAt.toUtc();
      input['dueAt'] = "${utcDueAt.toIso8601String().split('.')[0]}Z";
    }

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'input': input},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);

    if (contactId != null) {
      final taskId = result.data?['createTask']?['id'];
      if (taskId != null) {
        const String targetMutation = createTaskTargetMutation;
        final targetInput = {'taskId': taskId, 'targetPersonId': contactId};
        final MutationOptions targetOptions = MutationOptions(
          document: parseString(targetMutation),
          variables: {'input': targetInput},
        );
        final targetResult = await _base.mutateWithRefresh(targetOptions);
        if (targetResult.hasException) {
          debugPrint(
            'Warning: Failed to link task to contact: ${targetResult.exception}',
          );
        }
      }
    }
    final data = result.data?['createTask'];

    return Task.fromTwenty(data);
  }

  Future<Task> updateTask(
    String id, {
    String? title,
    String? body,
    DateTime? dueAt,
    bool clearDueDate = false,
    bool? completed,
    String? assigneeId,
  }) async {
    const String mutation = updateTaskMutation;

    final input = <String, dynamic>{};
    if (title != null) input['title'] = title;
    if (assigneeId != null) input['assigneeId'] = assigneeId;
    if (completed != null) {
      input['status'] = completed ? 'DONE' : 'TODO';
    }
    if (body != null) {
      final blockNodeJson = jsonEncode([
        {
          "type": "paragraph",
          "content": [
            {"type": "text", "text": body, "styles": {}},
          ],
        },
      ]);
      input['bodyV2'] = {'blocknote': blockNodeJson};
    }
    if (clearDueDate) {
      input['dueAt'] = null;
    } else if (dueAt != null) {
      final utcDueAt = dueAt.toUtc();
      input['dueAt'] = "${utcDueAt.toIso8601String().split('.')[0]}Z";
    }

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'id': id, 'input': input},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);

    final data = result.data?['updateTask'];

    return Task.fromTwenty(data);
  }

  Future<void> deleteTask(String id) async {
    const String mutation = deleteTaskMutation;

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'id': id},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    if (result.hasException) throw Exception(result.exception.toString());
  }
}
