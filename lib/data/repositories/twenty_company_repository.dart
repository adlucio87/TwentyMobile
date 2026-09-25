import 'package:gql/language.dart' show parseString;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/domain/models/workspace_member.dart';

import 'package:pocketcrm/data/graphql/crm_queries.dart';

class TwentyCompanyRepository {
  final BaseGraphQLConnector _base;

  TwentyCompanyRepository(this._base);

  Future<List<WorkspaceMember>> getWorkspaceMembers() async {
    const String query = getWorkspaceMembersQuery;
    final options = QueryOptions(
      document: parseString(query),
      fetchPolicy: FetchPolicy.networkOnly,
    );
    final result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);
    final edges = result.data?['workspaceMembers']?['edges'] as List?;
    if (edges == null) return [];
    return edges
        .map((e) => WorkspaceMember.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<String> getCurrentUserName() async {
    const String query = getCurrentUserNameQuery;

    final QueryOptions options = QueryOptions(document: parseString(query));
    final QueryResult result = await _base.queryWithRefresh(options);

    final edges = result.data?['workspaceMembers']?['edges'] as List?;
    if (edges == null || edges.isEmpty) return '';

    final name = edges.first['node']?['name'];
    if (name == null) return '';
    return '${name['firstName']} ${name['lastName']}'.trim();
  }

  Future<Company> createCompany({
    required String name,
    String? domainName,
  }) async {
    const String mutation = createCompanyMutation;

    final input = <String, dynamic>{'name': name};
    if (domainName != null && domainName.isNotEmpty) {
      input['domainName'] = {'primaryLinkUrl': domainName};
    }

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'input': input},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);

    final data = result.data?['createCompany'];
    if (data == null) throw Exception('Failed to create company');

    return Company.fromTwenty(data as Map<String, dynamic>);
  }

  Future<Company> updateCompany(
    String id, {
    String? name,
    String? domainName,
    Map<String, dynamic>? customFields,
  }) async {
    const String mutation = updateCompanyMutation;

    final input = <String, dynamic>{};
    if (name != null) input['name'] = name;
    if (domainName != null) {
      // Support clearing domain by providing empty string
      input['domainName'] = domainName.isEmpty
          ? null
          : {'primaryLinkUrl': domainName};
    }

    if (customFields != null && customFields.isNotEmpty) {
      input.addAll(customFields);
    }

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'id': id, 'input': input},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);

    return Company.fromTwenty(
      result.data?['updateCompany'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteCompany(String id) async {
    const String mutation = deleteCompanyMutation;

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'id': id},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);
  }

  Future<List<Company>> getCompanies({String? search, int page = 1}) async {
    final String query = getCompaniesQuery(_base.customFields['company']?.join('\n              ') ?? '');

    Map<String, dynamic>? filter;
    if (search != null && search.isNotEmpty) {
      filter = {
        'or': [
          {
            'name': {'like': '%$search%'},
          },
          {
            'domainName': {
              'primaryLinkUrl': {'like': '%$search%'},
            },
          },
        ],
      };
    }

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {'first': 20, if (filter != null) 'filter': filter},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['companies']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) => Company.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<Company> getCompanyById(String id) async {
    final String query = getCompanyByIdQuery(_base.customFields['company']?.join('\n              ') ?? '');

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {'id': id},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['companies']?['edges'] as List?;
    if (edges == null || edges.isEmpty) throw Exception('Company not found');

    return Company.fromTwenty(edges.first['node'] as Map<String, dynamic>);
  }
}
