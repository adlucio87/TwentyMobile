import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/domain/repositories/crm_repository.dart';

@GenerateNiceMocks([MockSpec<CRMRepository>()])
import 'providers_test.mocks.dart';

void main() {
  group('Contacts Provider', () {
    late MockCRMRepository mockCRMRepository;
    late ProviderContainer container;

    setUp(() {
      mockCRMRepository = MockCRMRepository();
      container = ProviderContainer(
        overrides: [
          crmRepositoryProvider.overrideWith((ref) => mockCRMRepository),
          isDemoModeProvider.overrideWith((ref) => Future.value(false)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('addContact adds contact and updates state', () async {
      // 1. Setup mock data
      final initialContacts = [
        Contact(id: '1', firstName: 'John', lastName: 'Doe', email: null, phone: null),
      ];
      final newContact = Contact(
        id: '2',
        firstName: 'Jane',
        lastName: 'Smith',
        email: null,
        phone: null,
      );
      final updatedContacts = [newContact, ...initialContacts]; // Note: order is newest first

      // 2. Mock repository behavior
      when(mockCRMRepository.getContacts()).thenAnswer((_) async => 
          (contacts: initialContacts, endCursor: null, hasNextPage: false));

      when(mockCRMRepository.createContact(
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '1234567890',
      )).thenAnswer((_) async => newContact);

      // 3. Call addContact
      final contactsNotifier = container.read(contactsProvider.notifier);

      // wait for build to finish
      await container.read(contactsProvider.future);

      await contactsNotifier.addContact(
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '1234567890',
      );

      // 4. Verify the state has been updated
      expect(container.read(contactsProvider).value, updatedContacts);

      // 5. Verify repository methods were called
      verify(mockCRMRepository.getContacts()).called(1); // Once on build
      verify(mockCRMRepository.createContact(
        firstName: 'Jane',
        lastName: 'Smith',
        email: 'jane@example.com',
        phone: '1234567890',
      )).called(1);
    });

    test('addContact handles errors and does not update state on error', () async {
      final initialContacts = [
        Contact(id: '1', firstName: 'John', lastName: 'Doe', email: null, phone: null),
      ];

      when(mockCRMRepository.getContacts()).thenAnswer((_) async =>
          (contacts: initialContacts, endCursor: null, hasNextPage: false));

      when(mockCRMRepository.createContact(
        firstName: 'Error',
        lastName: 'User',
        email: null,
        phone: null,
      )).thenThrow(Exception('Failed to create contact'));

      final contactsNotifier = container.read(contactsProvider.notifier);
      await container.read(contactsProvider.future);

      try {
        await contactsNotifier.addContact(
          firstName: 'Error',
          lastName: 'User',
        );
        fail('Should have thrown');
      } catch (e) {
        expect(e, isException);
      }

      // State should remain unchanged
      expect(container.read(contactsProvider).value, initialContacts);
    });
  });

  group('Companies Provider paging', () {
    late MockCRMRepository mockCRMRepository;
    late ProviderContainer container;

    setUp(() {
      mockCRMRepository = MockCRMRepository();
      container = ProviderContainer(
        overrides: [
          crmRepositoryProvider.overrideWith((ref) => mockCRMRepository),
          isDemoModeProvider.overrideWith((ref) => Future.value(false)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('loadMore appends the next page using the end cursor', () async {
      final firstPage = List.generate(20, (i) => Company(id: 'c$i', name: 'Company $i'));
      when(mockCRMRepository.getCompanies())
          .thenAnswer((_) async => (companies: firstPage, endCursor: 'cur_20', hasNextPage: true));
      when(mockCRMRepository.getCompanies(search: null, after: 'cur_20')).thenAnswer(
          (_) async => (companies: [Company(id: 'c20', name: 'Company 20')], endCursor: 'cur_21', hasNextPage: false));

      final first = await container.read(companiesProvider.future);
      expect(first.length, 20);
      expect(container.read(companiesProvider.notifier).hasNextPage, isTrue);

      await container.read(companiesProvider.notifier).loadMore();

      expect(container.read(companiesProvider).value!.length, 21);
      expect(container.read(companiesProvider.notifier).hasNextPage, isFalse);

      // No further request once the last page is reached.
      await container.read(companiesProvider.notifier).loadMore();
      verify(mockCRMRepository.getCompanies(search: null, after: 'cur_20')).called(1);
    });
  });
}
