import 'package:flutter/foundation.dart';
import 'package:gql/language.dart' show parseString;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/domain/models/workflow.dart';
import 'package:pocketcrm/domain/models/workflow_run.dart';

import 'package:pocketcrm/data/graphql/crm_queries.dart';

class TwentyWorkflowRepository {
  final BaseGraphQLConnector _base;

  TwentyWorkflowRepository(this._base);

  Future<List<Workflow>> getManualWorkflows({required String objectType}) async {
    const String query = getManualWorkflowsQuery;

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);

    // Workflows may require admin permissions — return empty list gracefully
    if (result.hasException) {
      final errorMsg = result.exception?.graphqlErrors.firstOrNull?.message ?? '';
      if (errorMsg.toLowerCase().contains('permission')) {
        debugPrint('Warning: No permission to access workflows. Returning empty list.');
        return [];
      }
      _base.handleResultException(result);
    }

    final rawWorkflows = result.data?['workflows'];
    debugPrint('[Workflow Debug] raw workflows type: ${rawWorkflows.runtimeType}');
    debugPrint('[Workflow Debug] raw workflows: $rawWorkflows');

    List? edges;
    if (rawWorkflows is Map<String, dynamic>) {
      final rawEdges = rawWorkflows['edges'];
      if (rawEdges is List) {
        edges = rawEdges;
      }
    } else if (rawWorkflows is List) {
      edges = rawWorkflows;
    }

    if (edges == null) return [];
    final workflows = <Workflow>[];

    for (final edge in edges) {
      try {
        Map<String, dynamic>? node;
        if (edge is Map<String, dynamic> && edge.containsKey('node')) {
          node = edge['node'] as Map<String, dynamic>?;
        } else if (edge is Map<String, dynamic>) {
          node = edge;
        }
        if (node == null) {
          debugPrint('[Workflow Debug] Skipped: node is null');
          continue;
        }

        debugPrint('[Workflow Debug] Processing workflow: ${node['name']} (${node['id']})');

        // Check if this workflow has an active version with a MANUAL trigger
        final versionsRaw = node['versions'];
        debugPrint('[Workflow Debug] versions type: ${versionsRaw.runtimeType}, value: $versionsRaw');
        List? versions;
        if (versionsRaw is Map<String, dynamic>) {
          final edgesRaw = versionsRaw['edges'];
          if (edgesRaw is List) {
            versions = edgesRaw;
          }
        } else if (versionsRaw is List) {
          versions = versionsRaw;
        }
        if (versions == null || versions.isEmpty) {
          debugPrint('[Workflow Debug] Skipped: no versions found');
          continue;
        }

        final firstVersion = versions.first;
        debugPrint('[Workflow Debug] firstVersion type: ${firstVersion.runtimeType}');
        final Map<String, dynamic>? versionNode;
        if (firstVersion is Map<String, dynamic> && firstVersion.containsKey('node')) {
          versionNode = firstVersion['node'] as Map<String, dynamic>?;
        } else if (firstVersion is Map<String, dynamic>) {
          versionNode = firstVersion;
        } else {
          debugPrint('[Workflow Debug] Skipped: firstVersion not a Map');
          continue;
        }
        if (versionNode == null) {
          debugPrint('[Workflow Debug] Skipped: versionNode is null');
          continue;
        }

        // trigger can be a Map or a JSON string
        dynamic triggerRaw = versionNode['trigger'];
        debugPrint('[Workflow Debug] trigger type: ${triggerRaw.runtimeType}, value: $triggerRaw');
        Map<String, dynamic>? trigger;
        if (triggerRaw is Map<String, dynamic>) {
          trigger = triggerRaw;
        }
        if (trigger == null) {
          debugPrint('[Workflow Debug] Skipped: trigger is not a Map');
          continue;
        }

        // Only include workflows with MANUAL trigger type
        final triggerType = (trigger['type'] as String? ?? '').toUpperCase();
        debugPrint('[Workflow Debug] triggerType: $triggerType');
        if (triggerType != 'MANUAL') {
          debugPrint('[Workflow Debug] Skipped: triggerType is not MANUAL');
          continue;
        }

        // Check if the trigger's objectType matches the requested one
        final settings = trigger['settings'] as Map<String, dynamic>?;
        debugPrint('[Workflow Debug] settings: $settings');
        var triggerObjectType = '';
        if (settings != null) {
          final availability = settings['availability'] as Map<String, dynamic>?;
          triggerObjectType = settings['objectType'] as String? ?? '';
          if (triggerObjectType.isEmpty && availability != null) {
            triggerObjectType = availability['objectNameSingular'] as String? ?? '';
          }
        }

        debugPrint('[Workflow Debug] triggerObjectType: "$triggerObjectType" vs requested: "$objectType"');

        final normTrigger = triggerObjectType.toLowerCase();
        final normRequested = objectType.toLowerCase();
        bool isMatch = normTrigger == normRequested;

        // Treat 'person' and 'contact' as interchangeable
        if ((normTrigger == 'person' || normTrigger == 'contact') &&
            (normRequested == 'person' || normRequested == 'contact')) {
          isMatch = true;
        }

        if (!isMatch) {
          debugPrint('[Workflow Debug] Skipped: objectType mismatch ("$triggerObjectType" vs "$objectType")');
          continue;
        }

        debugPrint('[Workflow Debug] ✅ Workflow passed all filters, adding: ${node['name']}');
        workflows.add(Workflow.fromTwenty(node));
      } catch (e, stack) {
        debugPrint('[Workflow Debug] Error parsing workflow edge: $e');
        debugPrint('[Workflow Debug] Edge data: $edge');
        debugPrint('[Workflow Debug] Stack: $stack');
        continue;
      }
    }

    return workflows;
  }

  Future<({bool success, String? workflowRunId, String? error})>
      triggerWorkflow({
    required String workflowId,
    required String recordId,
    Map<String, dynamic>? payload,
  }) async {
    const String mutation = runWorkflowVersionMutation;

    final input = <String, dynamic>{
      'workflowVersionId': workflowId,
      'payload': <String, dynamic>{
        'recordId': recordId,
        if (payload != null) ...payload,
      },
    };

    debugPrint('[Workflow Debug] triggerWorkflow input: $input');

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'input': input},
    );

    try {
      final QueryResult result = await _base.mutateWithRefresh(options);

      if (result.hasException) {
        debugPrint('[Workflow Debug] Exception: ${result.exception}');
        final errorMsg = result.exception?.graphqlErrors.isNotEmpty == true
            ? result.exception!.graphqlErrors.first.message
            : result.exception?.linkException?.toString() ??
                'Unknown error occurred';
        final userError = errorMsg.toLowerCase().contains('forbidden')
            ? 'Forbidden: Workflow execution may require email/password login instead of API key.'
            : errorMsg;
        return (success: false, workflowRunId: null, error: userError);
      }

      debugPrint('[Workflow Debug] Result data: ${result.data}');
      final data = result.data?['runWorkflowVersion'];
      final runId = data?['workflowRunId'] as String?;

      return (success: true, workflowRunId: runId, error: null);
    } catch (e) {
      return (
        success: false,
        workflowRunId: null,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  Future<List<WorkflowRun>> getWorkflowRuns() async {
    const String query = getWorkflowRunsQuery;

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    try {
      final QueryResult result = await _base.queryWithRefresh(options);

      if (result.hasException) {
        debugPrint('Error fetching workflow runs: ${result.exception}');
        return [];
      }

      final rawRuns = result.data?['workflowRuns'];
      List? edges;
      if (rawRuns is Map<String, dynamic>) {
        edges = rawRuns['edges'] as List?;
      } else if (rawRuns is List) {
        edges = rawRuns;
      }

      if (edges == null) return [];

      final runs = <WorkflowRun>[];
      for (final edge in edges) {
        try {
          Map<String, dynamic>? node;
          if (edge is Map<String, dynamic> && edge.containsKey('node')) {
            node = edge['node'] as Map<String, dynamic>?;
          } else if (edge is Map<String, dynamic>) {
            node = edge;
          }
          if (node != null) {
            runs.add(WorkflowRun.fromJson(node));
          }
        } catch (e) {
          debugPrint('Error parsing workflow run: $e');
        }
      }
      return runs;
    } catch (e) {
      debugPrint('Exception in getWorkflowRuns: $e');
      return [];
    }
  }
}
