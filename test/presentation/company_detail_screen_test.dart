import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/companies/company_detail_screen.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';

import '../core/di/providers_test.mocks.dart';
import '../data/connectors/twenty_connector_test.mocks.dart';

void main() {
  group('CompanyDetailScreen Tests', () {
    late MockCRMRepository mockCRMRepository;

    setUp(() {
      mockCRMRepository = MockCRMRepository();
    });

    Widget createWidgetUnderTest(String companyId) {
      return ProviderScope(
        overrides: [
          crmRepositoryProvider.overrideWith((ref) => Future.value(mockCRMRepository)),
          // The custom-field section reads the stored field choice (see edit_fields_sheet.dart).
          storageServiceProvider.overrideWithValue(MockStorageService()),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'),
            Locale('it'),
          ],
          locale: const Locale('en'),
          home: CompanyDetailScreen(id: companyId),
        ),
      );
    }

    testWidgets('Renders skeleton loading while fetching company detail', (WidgetTester tester) async {
      when(mockCRMRepository.getCompanyById('comp-1')).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return Company(id: 'comp-1', name: 'Acme Corp');
      });

      await tester.pumpWidget(createWidgetUnderTest('comp-1'));

      expect(find.byType(DetailSkeleton), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders company information when loaded', (WidgetTester tester) async {
      final company = Company(
        id: 'comp-1',
        name: 'Acme Corp',
        domainName: 'acme.com',
        industry: 'Software',
        employeesCount: 42,
      );

      when(mockCRMRepository.getCompanyById('comp-1')).thenAnswer((_) async => company);
      when(mockCRMRepository.getNotesByCompany('comp-1')).thenAnswer((_) async => []);
      when(mockCRMRepository.getContactsByCompany('comp-1')).thenAnswer((_) async => []);
      when(mockCRMRepository.getManualWorkflows(objectType: 'company')).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest('comp-1'));
      await tester.pumpAndSettle();

      expect(find.text('Acme Corp'), findsWidgets);
      expect(find.text('acme.com'), findsOneWidget);
      expect(find.text('Software'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Industry'), findsOneWidget);
      expect(find.text('Employees'), findsOneWidget);
    });

    testWidgets('Renders error state when company fetch fails', (WidgetTester tester) async {
      when(mockCRMRepository.getCompanyById('comp-1')).thenThrow(Exception('Company not found'));

      await tester.pumpWidget(createWidgetUnderTest('comp-1'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
    });
  });
}
