import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/auth/oauth_client_store.dart';

import 'auth_service_test.mocks.dart';

void main() {
  late MockStorageService storage;
  late OAuthClientStore store;

  setUp(() {
    storage = MockStorageService();
    store = OAuthClientStore(storage);
  });

  group('storage keys', () {
    test('are derived from the instance host', () {
      expect(
        OAuthClientStore.clientIdKey('https://twentycrm.luciosoft.it'),
        'oauth_client_id_twentycrm_luciosoft_it',
      );
      expect(
        OAuthClientStore.clientSecretKey('https://twentycrm.luciosoft.it/'),
        'oauth_client_secret_twentycrm_luciosoft_it',
      );
    });

    test('fall back to a slug when the value is not a parsable URL', () {
      expect(
        OAuthClientStore.clientIdKey('crm local'),
        'oauth_client_id_crm_local',
      );
    });

    test('are distinct per instance', () {
      expect(
        OAuthClientStore.clientIdKey('https://a.example.com'),
        isNot(OAuthClientStore.clientIdKey('https://b.example.com')),
      );
    });
  });

  group('readClientId', () {
    test('returns the stored per-instance value', () async {
      when(storage.read(key: 'oauth_client_id_crm_example_com'))
          .thenAnswer((_) async => 'per-instance-id');

      expect(await store.readClientId('https://crm.example.com'), 'per-instance-id');
      verifyNever(storage.read(key: OAuthClientStore.legacyClientIdKey));
    });

    test('migrates the legacy global key', () async {
      when(storage.read(key: 'oauth_client_id_crm_example_com'))
          .thenAnswer((_) async => null);
      when(storage.read(key: OAuthClientStore.legacyClientIdKey))
          .thenAnswer((_) async => 'legacy-id');

      expect(await store.readClientId('https://crm.example.com'), 'legacy-id');

      verify(storage.write(key: 'oauth_client_id_crm_example_com', value: 'legacy-id'))
          .called(1);
      verify(storage.delete(key: OAuthClientStore.legacyClientIdKey)).called(1);
    });

    test('returns null when neither slot is populated', () async {
      when(storage.read(key: anyNamed('key'))).thenAnswer((_) async => null);

      expect(await store.readClientId('https://crm.example.com'), isNull);
    });
  });

  group('saveClient', () {
    test('stores the client id and omits the secret when absent', () async {
      await store.saveClient('https://crm.example.com', clientId: '  spaced-id  ');

      verify(storage.write(key: 'oauth_client_id_crm_example_com', value: 'spaced-id'))
          .called(1);
      verifyNever(storage.write(
        key: 'oauth_client_secret_crm_example_com',
        value: anyNamed('value'),
      ));
    });

    test('stores the secret when the instance issued one', () async {
      await store.saveClient(
        'https://crm.example.com',
        clientId: 'id',
        clientSecret: 'secret',
      );

      verify(storage.write(key: 'oauth_client_secret_crm_example_com', value: 'secret'))
          .called(1);
    });
  });

  group('readClientSecret', () {
    test('returns the stored secret', () async {
      when(storage.read(key: 'oauth_client_secret_crm_example_com'))
          .thenAnswer((_) async => 'secret');

      expect(await store.readClientSecret('https://crm.example.com'), 'secret');
    });

    test('treats an empty value as absent', () async {
      when(storage.read(key: anyNamed('key'))).thenAnswer((_) async => '');

      expect(await store.readClientSecret('https://crm.example.com'), isNull);
    });
  });

  test('clearLegacyClientId removes the global key written by older versions',
      () async {
    await store.clearLegacyClientId();

    verify(storage.delete(key: OAuthClientStore.legacyClientIdKey)).called(1);
  });

  group('shared registry markers', () {
    test('keys are derived from the instance host', () {
      expect(
        OAuthClientStore.publishedClientIdKey('https://crm.example.com'),
        'oauth_client_shared_crm_example_com',
      );
      expect(
        OAuthClientStore.rejectedClientIdKey('https://crm.example.com/'),
        'oauth_client_rejected_crm_example_com',
      );
    });

    test('round-trips the published and rejected client ids', () async {
      when(storage.read(key: 'oauth_client_shared_crm_example_com'))
          .thenAnswer((_) async => 'published-id');
      when(storage.read(key: 'oauth_client_rejected_crm_example_com'))
          .thenAnswer((_) async => 'rejected-id');

      expect(
        await store.readPublishedClientId('https://crm.example.com'),
        'published-id',
      );
      expect(
        await store.readRejectedClientId('https://crm.example.com'),
        'rejected-id',
      );

      await store.savePublishedClientId(
        'https://crm.example.com',
        '  published-id  ',
      );
      verify(storage.write(
        key: 'oauth_client_shared_crm_example_com',
        value: 'published-id',
      )).called(1);

      await store.saveRejectedClientId(
        'https://crm.example.com',
        'rejected-id',
      );
      verify(storage.write(
        key: 'oauth_client_rejected_crm_example_com',
        value: 'rejected-id',
      )).called(1);

      await store.clearRejectedClientId('https://crm.example.com');
      verify(storage.delete(key: 'oauth_client_rejected_crm_example_com'))
          .called(1);
    });

    test('treats empty values as absent', () async {
      when(storage.read(key: anyNamed('key'))).thenAnswer((_) async => '');

      expect(
        await store.readPublishedClientId('https://crm.example.com'),
        isNull,
      );
      expect(
        await store.readRejectedClientId('https://crm.example.com'),
        isNull,
      );
    });
  });

  test('clearClient drops the credentials and both registry markers', () async {
    await store.clearClient('https://crm.example.com');

    verify(storage.delete(key: 'oauth_client_id_crm_example_com')).called(1);
    verify(storage.delete(key: 'oauth_client_secret_crm_example_com')).called(1);
    verify(storage.delete(key: 'oauth_client_shared_crm_example_com')).called(1);
    verify(storage.delete(key: 'oauth_client_rejected_crm_example_com'))
        .called(1);
  });
}
