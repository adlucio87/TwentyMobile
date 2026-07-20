import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';

class MetadataConnector {
  final GraphQLClient client;
  final AuthService? authService;

  MetadataConnector({required this.client, this.authService});

  Future<List<ObjectMetadata>> getWorkspaceMetadata() async {
    const String query = r'''
      query GetWorkspaceMetadata {
        objects(first: 100) {
          edges {
            node {
              id
              nameSingular
              namePlural
              icon
              labelSingular
              labelPlural
              fields(first: 100) {
                edges {
                  node {
                    id
                    name
                    type
                    label
                    isActive
                  }
                }
              }
            }
          }
        }
      }
    ''';

    final options = QueryOptions(
      document: gql(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await client.query(options);

    if (result.hasException) {
      throw Exception(result.exception.toString());
    }

    final data = result.data;
    if (data == null) {
      return [];
    }

    final edges = data['objects']?['edges'] as List?;
    if (edges == null) {
      return [];
    }

    final objects = edges.map((e) {
      final node = e['node'] as Map<String, dynamic>;

      // Map fields edges
      final fieldsEdges = node['fields']?['edges'] as List? ?? [];
      final fieldsList = fieldsEdges.map((fe) => fe['node'] as Map<String, dynamic>).toList();

      final mappedNode = Map<String, dynamic>.from(node);
      mappedNode['fields'] = fieldsList;

      return ObjectMetadata.fromJson(mappedNode);
    }).toList();

    return objects;
  }
}
