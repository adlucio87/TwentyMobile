import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/presentation/companies/companies_screen.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:pocketcrm/presentation/shared/empty_state_widget.dart';

import '../core/di/providers_test.mocks.dart';

void main() {
  group('CompaniesScreen Tests', () {
    late MockCRMRepository mockCRMRepository;

    setUp(() {
      mockCRMRepository = MockCRMRepository();
    });

    Widget createWidgetUnderTest() {
      return ProviderScope(
        overrides: [
          crmRepositoryProvider.overrideWith((ref) => Future.value(mockCRMRepository)),
        ],
        child: const MaterialApp(
          home: CompaniesScreen(),
        ),
      );
    }

    testWidgets('Renders a loading shimmer while data is loading', (WidgetTester tester) async {
      // Return a future that never completes to keep the UI in a loading state
      when(mockCRMRepository.getCompanies()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return (companies: <Company>[], endCursor: null, hasNextPage: false);
      });

      await tester.pumpWidget(createWidgetUnderTest());

      // The ListSkeleton should be present while loading
      expect(find.byType(ListSkeleton), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders a list of company cards when companies are loaded', (WidgetTester tester) async {
      final companies = [
        Company(id: '1', name: 'Acme Corp', domainName: 'acme.com'),
        Company(id: '2', name: 'Globex', domainName: 'globex.com'),
      ];

      when(mockCRMRepository.getCompanies())
          .thenAnswer((_) async => (companies: companies, endCursor: null, hasNextPage: false));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('Globex'), findsOneWidget);
    });

    testWidgets('Shows empty state when no companies exist', (WidgetTester tester) async {
      when(mockCRMRepository.getCompanies())
          .thenAnswer((_) async => (companies: <Company>[], endCursor: null, hasNextPage: false));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(EmptyStateWidget), findsOneWidget);
      expect(find.text('No companies'), findsOneWidget);
    });

    testWidgets('Search field is visible', (WidgetTester tester) async {
      when(mockCRMRepository.getCompanies())
          .thenAnswer((_) async => (companies: <Company>[], endCursor: null, hasNextPage: false));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search companies...'), findsOneWidget);
    });

    testWidgets('Pull to refresh calls refresh on the provider', (WidgetTester tester) async {
      final initialCompanies = [
        Company(id: '1', name: 'Acme Corp', domainName: 'acme.com'),
      ];
      final refreshedCompanies = [
        Company(id: '1', name: 'Acme Corp', domainName: 'acme.com'),
        Company(id: '2', name: 'Globex', domainName: 'globex.com'),
      ];

      when(mockCRMRepository.getCompanies())
          .thenAnswer((_) async => (companies: initialCompanies, endCursor: null, hasNextPage: false));

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('Globex'), findsNothing);

      // Change getCompanies to return refreshed data
      when(mockCRMRepository.getCompanies())
          .thenAnswer((_) async => (companies: refreshedCompanies, endCursor: null, hasNextPage: false));

      // Perform pull to refresh
      await tester.drag(find.byType(ListView), const Offset(0, 300));
      await tester.pumpAndSettle();

      // Verify UI shows the new company
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('Globex'), findsOneWidget);

      // Verify repository method was called twice (initial + refresh)
      verify(mockCRMRepository.getCompanies()).called(2);
    });
  });
}
