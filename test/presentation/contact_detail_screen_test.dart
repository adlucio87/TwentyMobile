import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/contact_detail/contact_detail_screen.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';

import '../core/di/providers_test.mocks.dart';

void main() {
  group('ContactDetailScreen Tests', () {
    late MockCRMRepository mockCRMRepository;

    setUp(() {
      mockCRMRepository = MockCRMRepository();
    });

    Widget createWidgetUnderTest(String contactId) {
      return ProviderScope(
        overrides: [
          crmRepositoryProvider.overrideWith((ref) => Future.value(mockCRMRepository)),
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
          home: ContactDetailScreen(id: contactId),
        ),
      );
    }

    testWidgets('Renders skeleton loading while fetching contact detail', (WidgetTester tester) async {
      when(mockCRMRepository.getContactById('c-1')).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return Contact(id: 'c-1', firstName: 'John', lastName: 'Doe');
      });

      await tester.pumpWidget(createWidgetUnderTest('c-1'));

      expect(find.byType(DetailSkeleton), findsOneWidget);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders contact information when loaded', (WidgetTester tester) async {
      final contact = Contact(
        id: 'c-1',
        firstName: 'Marco',
        lastName: 'Rossi',
        email: 'marco.rossi@example.com',
        phone: '+39 02 1234567',
        companyName: 'Acme Corp',
      );

      when(mockCRMRepository.getContactById('c-1')).thenAnswer((_) async => contact);
      when(mockCRMRepository.getNotesByContact('c-1')).thenAnswer((_) async => []);
      when(mockCRMRepository.getManualWorkflows(objectType: 'person')).thenAnswer((_) async => []);

      await tester.pumpWidget(createWidgetUnderTest('c-1'));
      await tester.pumpAndSettle();

      expect(find.text('Marco Rossi'), findsOneWidget);
      expect(find.text('Acme Corp'), findsOneWidget);
      expect(find.text('marco.rossi@example.com'), findsOneWidget);
      expect(find.text('+39 02 1234567'), findsOneWidget);
    });

    testWidgets('Renders error state when contact fetch fails', (WidgetTester tester) async {
      when(mockCRMRepository.getContactById('c-1')).thenThrow(Exception('Contact not found'));

      await tester.pumpWidget(createWidgetUnderTest('c-1'));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorStateWidget), findsOneWidget);
    });
  });
}
