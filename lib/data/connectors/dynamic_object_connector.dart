import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:gql/language.dart' show parseString;
import 'package:pocketcrm/domain/models/dynamic_record.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/data/graphql/dynamic_query_builder.dart';

class DynamicObjectConnector {
  final GraphQLClient client;

  DynamicObjectConnector({required this.client});

  Future<({List<DynamicRecord> records, String? endCursor, bool hasNextPage})>
  getRecords(
    ObjectMetadata metadata, {
    String? search,
    int pageSize = 20,
    String? after,
  }) async {
    final query = DynamicQueryBuilder.buildListQuery(metadata);
    
    // Build a simple search filter on the 'name' field if present
    Map<String, dynamic>? filter;
    if (search != null && search.isNotEmpty) {
      // Try to search on 'name' field if it exists, otherwise on first TEXT field
      final nameField = metadata.fields.where((f) => f.name == 'name').firstOrNull;
      final firstTextField = metadata.fields.where((f) => f.type.toUpperCase() == 'TEXT' && f.isActive).firstOrNull;
      final searchField = nameField ?? firstTextField;
      
      if (searchField != null) {
        if (searchField.type.toUpperCase() == 'FULL_NAME') {
          filter = {
            'or': [
              { 'name': { 'firstName': { 'ilike': '%$search%' } } },
              { 'name': { 'lastName': { 'ilike': '%$search%' } } },
            ],
          };
        } else {
          filter = { searchField.name: { 'ilike': '%$search%' } };
        }
      }
    }

    final options = QueryOptions(
      document: parseString(query),
      variables: {
        'first': pageSize,
        if (filter != null) 'filter': filter,
        if (after != null) 'after': after,
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client.query(options);
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data?[metadata.namePlural];
    final edges = data?['edges'] as List? ?? [];
    final pageInfo = data?['pageInfo'] as Map<String, dynamic>? ?? {};

    final records = edges
        .map((e) => DynamicRecord.fromTwenty(
              metadata.nameSingular,
              e['node'] as Map<String, dynamic>,
            ))
        .toList();

    return (
      records: records,
      endCursor: pageInfo['endCursor'] as String?,
      hasNextPage: pageInfo['hasNextPage'] as bool? ?? false,
    );
  }

  Future<DynamicRecord> getRecordById(ObjectMetadata metadata, String id) async {
    final query = DynamicQueryBuilder.buildDetailQuery(metadata);
    
    final options = QueryOptions(
      document: parseString(query),
      variables: { 'id': id },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client.query(options);
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final edges = result.data?[metadata.namePlural]?['edges'] as List? ?? [];
    if (edges.isEmpty) throw Exception('Record not found');

    return DynamicRecord.fromTwenty(
      metadata.nameSingular,
      edges.first['node'] as Map<String, dynamic>,
    );
  }

  Future<String> createRecord(ObjectMetadata metadata, Map<String, dynamic> data) async {
    final query = DynamicQueryBuilder.buildCreateMutation(metadata);
    final singularCapitalized = metadata.nameSingular[0].toUpperCase() + metadata.nameSingular.substring(1);
    
    final options = MutationOptions(
      document: parseString(query),
      variables: { 'input': data },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client.mutate(options);
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final mutationName = 'create$singularCapitalized';
    return result.data?[mutationName]?['id'] as String;
  }

  Future<String> updateRecord(ObjectMetadata metadata, String id, Map<String, dynamic> data) async {
    final query = DynamicQueryBuilder.buildUpdateMutation(metadata);
    final singularCapitalized = metadata.nameSingular[0].toUpperCase() + metadata.nameSingular.substring(1);
    
    final options = MutationOptions(
      document: parseString(query),
      variables: { 'id': id, 'input': data },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client.mutate(options);
    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final mutationName = 'update$singularCapitalized';
    return result.data?[mutationName]?['id'] as String;
  }
}
