import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/data/connectors/twenty_connector.dart';
import 'package:pocketcrm/data/repositories/twenty_contact_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_company_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_note_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_task_repository.dart';
import 'package:pocketcrm/data/repositories/twenty_workflow_repository.dart';

import '../connectors/twenty_connector_test.mocks.dart';

void main() {
  group('Domain Repositories Isolation Tests', () {
    late MockGraphQLClient mockClient;
    late MockStorageService mockStorageService;
    late MockAuthService mockAuthService;
    late BaseGraphQLConnector baseConnector;

    setUp(() {
      mockClient = MockGraphQLClient();
      mockStorageService = MockStorageService();
      mockAuthService = MockAuthService();

      baseConnector = BaseGraphQLConnector(
        client: mockClient,
        storageService: mockStorageService,
        authService: mockAuthService,
      );
    });

    test('TwentyContactRepository can be instantiated and used independently', () async {
      final contactRepo = TwentyContactRepository(baseConnector);

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
                      'name': {'firstName': 'Alice', 'lastName': 'Smith'},
                    }
                  }
                ],
                'pageInfo': {'hasNextPage': false, 'endCursor': 'cur_1'},
              }
            },
          ));

      final result = await contactRepo.getContacts();
      expect(result.contacts.length, 1);
      expect(result.contacts.first.firstName, 'Alice');
      expect(result.contacts.first.lastName, 'Smith');
      expect(result.hasNextPage, isFalse);
    });

    test('TwentyCompanyRepository can be instantiated and used independently', () async {
      final companyRepo = TwentyCompanyRepository(baseConnector);

      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {
              'companies': {
                'edges': [
                  {
                    'node': {
                      'id': 'company-1',
                      'name': 'Twenty Corp',
                      'domainName': {'primaryLinkUrl': 'twenty.com'},
                    }
                  }
                ],
              }
            },
          ));

      final result = await companyRepo.getCompanies();
      expect(result.companies.length, 1);
      expect(result.companies.first.name, 'Twenty Corp');
      expect(result.companies.first.domainName, 'twenty.com');
    });

    test('TwentyCompanyRepository pages with a cursor and searches case-insensitively', () async {
      final companyRepo = TwentyCompanyRepository(baseConnector);

      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {
              'companies': {
                'edges': [
                  {
                    'node': {'id': 'company-21', 'name': 'Acme'},
                  }
                ],
                'pageInfo': {'hasNextPage': true, 'endCursor': 'cur_21'},
              }
            },
          ));

      final result = await companyRepo.getCompanies(search: 'acme', after: 'cur_20');

      expect(result.companies.single.id, 'company-21');
      expect(result.hasNextPage, isTrue);
      expect(result.endCursor, 'cur_21');

      final options = verify(mockClient.query(captureAny)).captured.single as QueryOptions;
      expect(options.variables['first'], 20);
      expect(options.variables['after'], 'cur_20');
      final or = (options.variables['filter'] as Map)['or'] as List;
      expect(or[0], {'name': {'ilike': '%acme%'}});
      expect(or[1], {'domainName': {'primaryLinkUrl': {'ilike': '%acme%'}}});
    });

    test('TwentyTaskRepository can be instantiated and used independently', () async {
      final taskRepo = TwentyTaskRepository(baseConnector);

      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      when(mockStorageService.read(key: 'auth_method')).thenAnswer((_) async => 'api_key');
      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {
              'tasks': {
                'edges': [
                  {
                    'node': {
                      'id': 'task-1',
                      'title': 'Review architecture',
                      'status': 'TODO',
                    }
                  }
                ],
              }
            },
          ));

      final tasks = await taskRepo.getTasks();
      expect(tasks.length, 1);
      expect(tasks.first.title, 'Review architecture');
      expect(tasks.first.completed, isFalse);
    });

    test('TwentyNoteRepository can be instantiated and used independently', () async {
      final noteRepo = TwentyNoteRepository(baseConnector);

      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {
              'noteTargets': {
                'edges': [
                  {
                    'node': {
                      'note': {
                        'id': 'note-1',
                        'createdAt': '2026-09-25T10:00:00Z',
                      }
                    }
                  }
                ],
              }
            },
          ));

      final notes = await noteRepo.getNotesByContact('contact-1');
      expect(notes.length, 1);
      expect(notes.first.id, 'note-1');
    });

    test('TwentyWorkflowRepository can be instantiated and used independently', () async {
      final workflowRepo = TwentyWorkflowRepository(baseConnector);

      when(mockAuthService.isTokenExpired()).thenAnswer((_) async => false);
      when(mockClient.query(any)).thenAnswer((_) async => QueryResult(
            source: QueryResultSource.network,
            options: QueryOptions(document: gql('')),
            data: {
              'workflowRuns': {
                'edges': [
                  {
                    'node': {
                      'id': 'run-1',
                      'status': 'SUCCESS',
                      'createdAt': '2026-09-25T10:00:00Z',
                    }
                  }
                ],
              }
            },
          ));

      final runs = await workflowRepo.getWorkflowRuns();
      expect(runs.length, 1);
      expect(runs.first.id, 'run-1');
      expect(runs.first.status, 'SUCCESS');
    });

    test('TwentyConnector provides access to all sub-repositories and delegates cleanly', () {
      final connector = TwentyConnector(
        client: mockClient,
        storageService: mockStorageService,
        authService: mockAuthService,
      );

      expect(connector.baseConnector, isNotNull);
      expect(connector.contactRepository, isA<TwentyContactRepository>());
      expect(connector.companyRepository, isA<TwentyCompanyRepository>());
      expect(connector.noteRepository, isA<TwentyNoteRepository>());
      expect(connector.taskRepository, isA<TwentyTaskRepository>());
      expect(connector.workflowRepository, isA<TwentyWorkflowRepository>());
    });
  });
}
