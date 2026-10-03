import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/di/metadata_provider.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/company.dart';
import 'package:pocketcrm/domain/models/dynamic_field_prefs.dart';
import 'package:pocketcrm/domain/models/metadata/field_metadata.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/companies/company_detail_screen.dart';
import 'package:pocketcrm/presentation/shared/edit_fields_sheet.dart';

import '../core/di/providers_test.mocks.dart';
import '../data/connectors/twenty_connector_test.mocks.dart';

class _FakeMetadata extends WorkspaceMetadata {
  _FakeMetadata(this.objects);
  final List<ObjectMetadata> objects;

  @override
  Future<List<ObjectMetadata>> build() async => objects;
}

FieldMetadata _field(String name) => FieldMetadata(id: 'f-$name', name: name, type: 'TEXT', label: name);

void main() {
  group('applyFieldPrefs', () {
    final fields = [_field('a'), _field('b'), _field('c')];

    test('hides hidden fields and keeps the original order otherwise', () {
      final result = applyFieldPrefs(fields, DynamicFieldPrefs(hiddenFields: ['b']));
      expect(result.map((f) => f.name), ['a', 'c']);
    });

    test('puts ordered fields first, in the stored order', () {
      final result = applyFieldPrefs(fields, DynamicFieldPrefs(orderedFields: ['c', 'a']));
      expect(result.map((f) => f.name), ['c', 'a', 'b']);
    });

    test('ignores stored names that no longer exist', () {
      final result = applyFieldPrefs(fields, DynamicFieldPrefs(orderedFields: ['gone', 'b'], hiddenFields: ['gone']));
      expect(result.map((f) => f.name), ['b', 'a', 'c']);
    });
  });

  testWidgets('Company detail hides custom fields the person switched off', (tester) async {
    final repo = MockCRMRepository();
    final storage = MockStorageService();
    when(storage.read(key: 'custom_fields_prefs_company'))
        .thenAnswer((_) async => DynamicFieldPrefs(hiddenFields: ['secretField']).toJsonString());
    when(repo.getCompanyById('comp-1')).thenAnswer((_) async => Company(
          id: 'comp-1',
          name: 'Acme Corp',
          customFields: {'secretField': 'hidden-value', 'visibleField': 'shown-value'},
        ));
    when(repo.getNotesByCompany('comp-1')).thenAnswer((_) async => []);
    when(repo.getContactsByCompany('comp-1')).thenAnswer((_) async => []);
    when(repo.getManualWorkflows(objectType: 'company')).thenAnswer((_) async => []);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        crmRepositoryProvider.overrideWith((ref) => Future.value(repo)),
        storageServiceProvider.overrideWithValue(storage),
        workspaceMetadataProvider.overrideWith(() => _FakeMetadata([
              ObjectMetadata(
                id: 'o-company',
                nameSingular: 'company',
                namePlural: 'companies',
                fields: [_field('secretField'), _field('visibleField')],
              ),
            ])),
      ],
      child: const MaterialApp(
        localizationsDelegates: [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: [Locale('en')],
        locale: Locale('en'),
        home: CompanyDetailScreen(id: 'comp-1'),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('company_edit_fields')), findsOneWidget);
    expect(find.text('shown-value'), findsOneWidget);
    expect(find.text('hidden-value'), findsNothing);
  });
}
