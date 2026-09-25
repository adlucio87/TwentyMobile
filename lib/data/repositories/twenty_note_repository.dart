import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:gql/language.dart' show parseString;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/domain/models/note.dart';

import 'package:pocketcrm/data/graphql/crm_queries.dart';

class TwentyNoteRepository {
  final BaseGraphQLConnector _base;

  TwentyNoteRepository(this._base);

  Future<List<Note>> getNotesByCompany(String companyId) async {
    const String query = getNotesByCompanyQuery;

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {'companyId': companyId},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['noteTargets']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) {
          final node = e['node'];
          if (node == null || node['note'] == null) return null;
          return Note.fromTwenty(node['note'] as Map<String, dynamic>);
        })
        .where((e) => e != null)
        .cast<Note>()
        .toList();
  }

  Future<List<Note>> getNotesByContact(String contactId) async {
    const String query = getNotesByContactQuery;

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {'personId': contactId},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['noteTargets']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) {
          final node = e['node'];
          if (node == null || node['note'] == null) return null;
          return Note.fromTwenty(node['note'] as Map<String, dynamic>);
        })
        .where((e) => e != null)
        .cast<Note>()
        .toList();
  }

  Future<Note> createNote({
    required String contactId,
    required String body,
    DateTime? dueAt, // Kept in interface but ignored for GraphQL Note
  }) async {
    const String mutation = createNoteMutation;

    final blockNodeJson = jsonEncode([
      {
        "type": "paragraph",
        "content": [
          {"type": "text", "text": body, "styles": {}},
        ],
      },
    ]);

    final input = <String, dynamic>{
      'bodyV2': {'blocknote': blockNodeJson},
    };

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'input': input},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);

    final data = result.data?['createNote'];
    final note = Note.fromTwenty(data as Map<String, dynamic>);

    const String targetMutation = createNoteTargetMutation;
    final targetInput = {'noteId': note.id, 'targetPersonId': contactId};
    final MutationOptions targetOptions = MutationOptions(
      document: parseString(targetMutation),
      variables: {'input': targetInput},
    );
    final targetResult = await _base.mutateWithRefresh(targetOptions);
    if (targetResult.hasException) {
      debugPrint(
        'Warning: Failed to link note to contact: ${targetResult.exception}',
      );
    }

    return note;
  }

  Future<Note> updateNote(
    String id, {
    required String body,
    DateTime? dueAt, // Kept in interface but ignored for GraphQL Note
  }) async {
    const String mutation = updateNoteMutation;

    final blockNodeJson = jsonEncode([
      {
        "type": "paragraph",
        "content": [
          {"type": "text", "text": body, "styles": {}},
        ],
      },
    ]);

    final input = <String, dynamic>{
      'bodyV2': {'blocknote': blockNodeJson},
    };

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'id': id, 'input': input},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);

    return Note.fromTwenty(result.data?['updateNote'] as Map<String, dynamic>);
  }

  Future<void> deleteNote(String id) async {
    const String mutation = deleteNoteMutation;

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'id': id},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);
  }
}
