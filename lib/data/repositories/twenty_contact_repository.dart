import 'package:gql/language.dart' show parseString;
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/data/country_codes.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/shared/widgets/phone_input_field.dart';
import 'package:pocketcrm/data/graphql/crm_queries.dart';

class TwentyContactRepository {
  final BaseGraphQLConnector _base;

  TwentyContactRepository(this._base);

  Future<({List<Contact> contacts, String? endCursor, bool hasNextPage})>
  getContacts({String? search, int pageSize = 20, String? after}) async {
    final String query = getContactsQuery(_base.customFields['person']?.join('\n              ') ?? '');

    Map<String, dynamic>? filter;
    if (search != null && search.isNotEmpty) {
      filter = {
        'or': [
          {
            'name': {
              'firstName': {'ilike': '%$search%'},
            },
          },
          {
            'name': {
              'lastName': {'ilike': '%$search%'},
            },
          },
        ],
      };
    }

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {
        'first': pageSize,
        'filter': ?filter,
        'after': ?after,
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final data = result.data?['people'];
    final edges = data?['edges'] as List? ?? [];
    final pageInfo = data?['pageInfo'] as Map<String, dynamic>? ?? {};

    final contacts = edges
        .map((e) => Contact.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();

    return (
      contacts: contacts,
      endCursor: pageInfo['endCursor'] as String?,
      hasNextPage: pageInfo['hasNextPage'] as bool? ?? false,
    );
  }

  Future<Contact> getContactById(String id) async {
    final String query = getContactByIdQuery(_base.customFields['person']?.join('\n              ') ?? '');

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {'id': id},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['people']?['edges'] as List?;
    if (edges == null || edges.isEmpty) throw Exception('Contact not found');

    return Contact.fromTwenty(edges.first['node'] as Map<String, dynamic>);
  }

  Future<List<Contact>> getContactsByCompany(String companyId) async {
    final String query = getContactsByCompanyQuery(_base.customFields['person']?.join('\n              ') ?? '');

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {
        'filter': {
          'companyId': {'eq': companyId},
        },
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['people']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) => Contact.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }

  Future<List<Contact>> getContactsByTask(String taskId) async {
    const String query = getContactsByTaskQuery;

    final QueryOptions options = QueryOptions(
      document: parseString(query),
      variables: {
        'filter': {
          'taskId': {'eq': taskId},
        },
      },
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final QueryResult result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['taskTargets']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .where((e) => e['node']?['targetPerson'] != null)
        .map(
          (e) => Contact.fromTwenty(
            e['node']['targetPerson'] as Map<String, dynamic>,
          ),
        )
        .toList();
  }

  Future<Contact> createContact({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
  }) async {
    const String mutation = createContactMutation;

    String? phoneCountryCode;
    if (phone != null) {
      final parsed = PhoneInputField.parseE164(phone);
      final match = countryCodes.where((c) => c.dialCode == parsed.$1).toList();
      if (match.isNotEmpty) {
        phoneCountryCode = match.first.isoCode;
      }
    }

    final input = {
      'name': {'firstName': firstName, 'lastName': lastName},
      if (email != null) 'emails': {'primaryEmail': email},
      if (phone != null)
        'phones': {
          'primaryPhoneNumber': phone,
          'primaryPhoneCountryCode': ?phoneCountryCode,
        },
    };

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'input': input},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);

    return Contact.fromTwenty(
      result.data?['createPerson'] as Map<String, dynamic>,
    );
  }

  Future<Contact> updateContact(
    String id, {
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    String? companyId,
    bool clearCompany = false,
    Map<String, dynamic>? customFields,
  }) async {
    const String mutation = updateContactMutation;

    final input = <String, dynamic>{};
    if (firstName != null || lastName != null) {
      input['name'] = {
        'firstName': ?firstName,
        'lastName': ?lastName,
      };
    }
    if (email != null) {
      input['emails'] = {'primaryEmail': email};
    }
    if (phone != null) {
      String? phoneCountryCode;
      final parsed = PhoneInputField.parseE164(phone);
      final match = countryCodes.where((c) => c.dialCode == parsed.$1).toList();
      if (match.isNotEmpty) {
        phoneCountryCode = match.first.isoCode;
      }

      input['phones'] = {
        'primaryPhoneNumber': phone,
        'primaryPhoneCountryCode': ?phoneCountryCode,
      };
    }
    if (clearCompany) {
      input['companyId'] = null;
    } else if (companyId != null) {
      input['companyId'] = companyId;
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

    return Contact.fromTwenty(
      result.data?['updatePerson'] as Map<String, dynamic>,
    );
  }

  Future<void> deleteContact(String id) async {
    const String mutation = deleteContactMutation;

    final MutationOptions options = MutationOptions(
      document: parseString(mutation),
      variables: {'id': id},
    );

    final QueryResult result = await _base.mutateWithRefresh(options);
    _base.handleResultException(result);
  }

  Future<List<Contact>> getRecentContacts({int limit = 5}) async {
    const String query = getRecentContactsQuery;

    final options = QueryOptions(
      document: parseString(query),
      variables: {'first': limit},
      fetchPolicy: FetchPolicy.networkOnly,
    );

    final result = await _base.queryWithRefresh(options);
    _base.handleResultException(result);

    final edges = result.data?['people']?['edges'] as List?;
    if (edges == null) return [];

    return edges
        .map((e) => Contact.fromTwenty(e['node'] as Map<String, dynamic>))
        .toList();
  }
}
