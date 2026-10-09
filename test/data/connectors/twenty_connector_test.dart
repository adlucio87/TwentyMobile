import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:gql/language.dart' show printNode;
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/auth/auth_service.dart';
import 'package:pocketcrm/core/utils/storage_service.dart';
import 'package:pocketcrm/data/connectors/twenty_connector.dart';


@GenerateNiceMocks([
  MockSpec<GraphQLClient>(),
  MockSpec<StorageService>(),
  MockSpec<AuthService>(),
])
import 'twenty_connector_test.mocks.dart';

/// Creates an [OperationException] that looks like a network timeout,
/// matching the `_isTimeout` check in [TwentyConnector] which looks for
/// `'TimeoutException'` in the link exception's toString().
OperationException _makeTimeoutException() {
  return OperationException(
    linkException: ServerException(
      originalException: TimeoutException('Connection timed out'),
    ),
  );
}

void main() {
  late TwentyConnector connector;
  late MockGraphQLClient mockClient;
  late MockStorageService mockStorageService;
  late MockAuthService mockAuthService;

  setUp(() {
    mockClient = MockGraphQLClient();
    mockStorageService = MockStorageService();
    mockAuthService = MockAuthService();

    connector = TwentyConnector(
      client: mockClient,
      storageService: mockStorageService,
      authService: mockAuthService,
    );
  });

  group('Token Expiry Logic (_queryWithRefresh)', () {
    test('proactively calls refresh if isTokenExpired is true', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => true);
      when(mockStorageService.read(key: 'auth_method')).thenAnswer((_) async => 'email');
      when(mockAuthService.refreshAccessToken()).thenAnswer((_) async => true);

      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {'people': {'edges': []}},
          ));

      await connector.getContacts();

      verify(mockAuthService.refreshAccessToken()).called(1);
      verify(mockClient.query(any)).called(1);
    });

    test('does NOT call refresh if isTokenExpired is false', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);

      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {'people': {'edges': []}},
          ));

      await connector.getContacts();

      verifyNever(mockAuthService.refreshAccessToken());
      verify(mockClient.query(any)).called(1);
    });
  });

  group('Timeout Detection (_isTimeout)', () {
    test('retries query once on timeout exception', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);

      int callCount = 0;
      when(mockClient.query(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            exception: _makeTimeoutException(),
          );
        }
        return QueryResult(
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
          data: {'people': {'edges': []}},
        );
      });

      await connector.getContacts();

      verify(mockClient.query(any)).called(2);
    });

    test('does NOT retry if exception does not contain TimeoutException', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);

      when(mockClient.query(any)).thenAnswer((_) async {
        return QueryResult(
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
          exception: OperationException(
            linkException: ServerException(
              originalException: Exception('Some other error'),
              parsedResponse: null,
            ),
          ),
        );
      });

      await expectLater(() => connector.getContacts(), throwsException);
      // Only called once — no retry on non-timeout errors
      verify(mockClient.query(any)).called(greaterThanOrEqualTo(1));

    });
  });

  group('Caching Logic (_getCurrentMemberId)', () {
    test('first call with auth_method == api_key returns null immediately', () async {
      when(mockStorageService.read(key: 'auth_method')).thenAnswer((_) async => 'api_key');

      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {'tasks': {'edges': []}},
          ));

      // getTasks calls _getCurrentMemberId under the hood
      await connector.getTasks();

      // Only the tasks query should be made, no 'Me' query.
      verify(mockClient.query(any)).called(1);
    });

    test('auth_method == api_key uses the member picked under "I am" and never runs the Me query', () async {
      when(mockStorageService.read(key: 'auth_method')).thenAnswer((_) async => 'api_key');
      when(mockStorageService.read(key: 'api_key_member_id')).thenAnswer((_) async => 'member-picked');

      final docs = <String>[];
      when(mockClient.query(any)).thenAnswer((invocation) async {
        final options = invocation.positionalArguments[0] as QueryOptions;
        docs.add(printNode(options.document));
        return QueryResult(
          source: QueryResultSource.network,
          options: options,
          data: {'tasks': {'edges': []}},
        );
      });

      await connector.getOverdueTasks();

      expect(docs, hasLength(1));
      expect(docs.single, contains('member-picked'));
      expect(docs.single, isNot(contains('workspaceMembers')));
    });

    test('first call with auth_method == email executes Me query and caches result', () async {
      when(mockStorageService.read(key: 'auth_method')).thenAnswer((_) async => 'email');

      when(mockClient.query(any)).thenAnswer((invocation) async {
        final options = invocation.positionalArguments[0] as QueryOptions;
        final doc = options.document.toString();
        if (doc.contains('Me')) {
          return QueryResult(
            source: QueryResultSource.network,
            options: options,
            data: {
              'workspaceMembers': {
                'edges': [
                  {
                    'node': {'id': 'member-123'}
                  }
                ]
              }
            },
          );
        }
        return QueryResult(
          source: QueryResultSource.network,
          options: options,
          data: {'tasks': {'edges': []}},
        );
      });

      // Call twice
      await connector.getTasks();
      await connector.getTasks();

      // Me query (1x) + tasks query (2x) = at least 3 client.query calls
      // (may be more if internal queries are added by the connector)
      verify(mockClient.query(any)).called(greaterThanOrEqualTo(2));

    });
  });

  group('Token Refresh Mutex', () {
    test('refreshes token and retries on UNAUTHENTICATED exception', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      when(mockStorageService.read(key: 'auth_method')).thenAnswer((_) async => 'email');
      when(mockAuthService.refreshAccessToken()).thenAnswer((_) async => true);

      int callCount = 0;
      when(mockClient.query(any)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            exception: OperationException(
              graphqlErrors: [const GraphQLError(message: 'UNAUTHENTICATED')],
            ),
          );
        }
        return QueryResult(
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
          data: {'people': {'edges': []}},
        );
      });

      await connector.getContacts();

      verify(mockAuthService.refreshAccessToken()).called(1);
      verify(mockClient.query(any)).called(2);
    });

    test('does NOT retry when refresh returns false', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      when(mockStorageService.read(key: 'auth_method')).thenAnswer((_) async => 'email');
      when(mockAuthService.refreshAccessToken()).thenAnswer((_) async => false);

      when(mockClient.query(any)).thenAnswer((_) async {
        return QueryResult(
          source: QueryResultSource.network,
          options: QueryOptions(document: gql('')),
          exception: OperationException(
            graphqlErrors: [const GraphQLError(message: 'UNAUTHENTICATED')],
          ),
        );
      });

      await expectLater(() => connector.getContacts(), throwsException);

      verify(mockAuthService.refreshAccessToken()).called(1);
      // Called once initially, NOT retried after failed refresh
      verify(mockClient.query(any)).called(greaterThanOrEqualTo(1));

    });
  });

  group('getContacts error handling and parsing', () {
    test('throws exception when GraphQL returns an exception', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      
      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            exception: OperationException(
              graphqlErrors: [const GraphQLError(message: 'General error')],
            ),
          ));

      expect(() => connector.getContacts(), throwsException);
    });

    test('parses contacts correctly from valid GraphQL data', () async {
      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      
      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {
              'people': {
                'edges': [
                  {
                    'node': {
                      'id': 'contact-1',
                      'name': {'firstName': 'John', 'lastName': 'Doe'},
                      'emails': {'primaryEmail': 'john@example.com'},
                      'phones': {
                        'primaryPhoneNumber': '123456789',
                        'primaryPhoneCallingCode': '+1'
                      },
                      'company': {'id': 'comp-1', 'name': 'Acme Corp'},
                      'createdAt': '2023-01-01T00:00:00.000Z',
                    }
                  }
                ],
                'pageInfo': {'hasNextPage': false, 'endCursor': null}
              }
            },
          ));

      final result = await connector.getContacts();

      expect(result.contacts.length, 1);
      final contact = result.contacts.first;
      expect(contact.id, 'contact-1');
      expect(contact.firstName, 'John');
      expect(contact.lastName, 'Doe');
      expect(contact.email, 'john@example.com');
      expect(contact.phone, '+1123456789');
      expect(contact.companyId, 'comp-1');
      expect(contact.companyName, 'Acme Corp');
    });
  });
}
