import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:pocketcrm/core/auth/oauth_pkce_service.dart';
import 'package:pocketcrm/core/auth/oauth_token_client.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/presentation/onboarding/oauth_login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth_service_test.mocks.dart';
import '../../helpers/localized_app.dart';

class MockOAuthPkceService extends Mock implements OAuthPkceService {
  @override
  Future<String?> getSavedClientId(String? instanceUrl) =>
      (super.noSuchMethod(
        Invocation.method(#getSavedClientId, [instanceUrl]),
        returnValue: Future<String?>.value(null),
        returnValueForMissingStub: Future<String?>.value(null),
      ) as Future<String?>);

  @override
  Future<String?> getSavedClientSecret(String? instanceUrl) =>
      (super.noSuchMethod(
        Invocation.method(#getSavedClientSecret, [instanceUrl]),
        returnValue: Future<String?>.value(null),
        returnValueForMissingStub: Future<String?>.value(null),
      ) as Future<String?>);

  @override
  Future<OAuthServerMetadata?> fetchServerMetadata(
    String? instanceUrl, {
    bool? forceRefresh,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #fetchServerMetadata,
          [instanceUrl],
          {#forceRefresh: forceRefresh},
        ),
        returnValue: Future<OAuthServerMetadata?>.value(null),
        returnValueForMissingStub: Future<OAuthServerMetadata?>.value(null),
      ) as Future<OAuthServerMetadata?>);

  @override
  Future<OAuthRedirectMode> resolveRedirectMode(
    String? instanceUrl, {
    OAuthServerMetadata? metadata,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #resolveRedirectMode,
          [instanceUrl],
          {#metadata: metadata},
        ),
        returnValue:
            Future<OAuthRedirectMode>.value(OAuthRedirectMode.httpsBouncer),
        returnValueForMissingStub:
            Future<OAuthRedirectMode>.value(OAuthRedirectMode.httpsBouncer),
      ) as Future<OAuthRedirectMode>);

  @override
  Future<String> effectiveRedirectUri(
    String? instanceUrl, {
    OAuthRedirectMode? mode,
  }) =>
      (super.noSuchMethod(
        Invocation.method(#effectiveRedirectUri, [instanceUrl], {#mode: mode}),
        returnValue: Future<String>.value(OAuthPkceService.defaultRedirectUri),
        returnValueForMissingStub:
            Future<String>.value(OAuthPkceService.defaultRedirectUri),
      ) as Future<String>);

  @override
  Future<OAuthClientCredentials?> tryAutoRegisterClient(
    String? instanceUrl, {
    String? redirectUri,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #tryAutoRegisterClient,
          [instanceUrl],
          {#redirectUri: redirectUri},
        ),
        returnValue: Future<OAuthClientCredentials?>.value(null),
        returnValueForMissingStub: Future<OAuthClientCredentials?>.value(null),
      ) as Future<OAuthClientCredentials?>);

  @override
  Future<void> saveClientCredentials(
    String? instanceUrl, {
    required String? clientId,
    String? clientSecret,
  }) =>
      (super.noSuchMethod(
        Invocation.method(
          #saveClientCredentials,
          [instanceUrl],
          {#clientId: clientId, #clientSecret: clientSecret},
        ),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);

  @override
  Future<void> loginWithOAuth({
    required String? instanceUrl,
    required String? clientId,
    String? clientSecret,
    String? redirectUri,
    OAuthRedirectMode? mode,
  }) =>
      (super.noSuchMethod(
        Invocation.method(#loginWithOAuth, [], {
          #instanceUrl: instanceUrl,
          #clientId: clientId,
          #clientSecret: clientSecret,
          #redirectUri: redirectUri,
          #mode: mode,
        }),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);

  @override
  Future<String?> fetchSharedClientId(String? instanceUrl) =>
      (super.noSuchMethod(
        Invocation.method(#fetchSharedClientId, [instanceUrl]),
        returnValue: Future<String?>.value(null),
        returnValueForMissingStub: Future<String?>.value(null),
      ) as Future<String?>);

  @override
  Future<String?> rejectedSharedClientId(String? instanceUrl) =>
      (super.noSuchMethod(
        Invocation.method(#rejectedSharedClientId, [instanceUrl]),
        returnValue: Future<String?>.value(null),
        returnValueForMissingStub: Future<String?>.value(null),
      ) as Future<String?>);

  @override
  Future<void> markSharedClientIdRejected(
    String? instanceUrl,
    String? clientId,
  ) =>
      (super.noSuchMethod(
        Invocation.method(#markSharedClientIdRejected, [instanceUrl, clientId]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);

  @override
  Future<bool> publishSharedClientId(String? instanceUrl, String? clientId) =>
      (super.noSuchMethod(
        Invocation.method(#publishSharedClientId, [instanceUrl, clientId]),
        returnValue: Future<bool>.value(true),
        returnValueForMissingStub: Future<bool>.value(true),
      ) as Future<bool>);

  @override
  Future<void> clearSavedClient(String? instanceUrl) =>
      (super.noSuchMethod(
        Invocation.method(#clearSavedClient, [instanceUrl]),
        returnValue: Future<void>.value(),
        returnValueForMissingStub: Future<void>.value(),
      ) as Future<void>);
}

void main() {
  late MockStorageService mockStorage;
  late MockOAuthPkceService mockOAuthService;

  /// The instance answers the discovery document but advertises no
  /// `registration_endpoint` (every self-hosted Twenty we have tested).
  OAuthServerMetadata metadataWithoutRegistration() => OAuthServerMetadata(
        authorizationEndpoint:
            Uri.parse('https://twentycrm.example.com/authorize'),
        tokenEndpoint: Uri.parse('https://twentycrm.example.com/oauth/token'),
        appVersion: 'v1.19.0',
        isMultiWorkspaceEnabled: false,
      );

  OAuthServerMetadata metadataWithRegistration() => OAuthServerMetadata(
        authorizationEndpoint:
            Uri.parse('https://twentycrm.example.com/authorize'),
        tokenEndpoint: Uri.parse('https://twentycrm.example.com/oauth/token'),
        registrationEndpoint:
            Uri.parse('https://twentycrm.example.com/oauth/register'),
      );

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(mockStorage),
          oauthPkceServiceProvider.overrideWithValue(mockOAuthService),
        ],
        child: localizedTestApp(home: const OAuthLoginScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// The primary action sits at the bottom of a scroll view, so it must be
  /// scrolled into view before tapping (the test surface is only 800x600).
  Future<void> tapLaunchBrowser(WidgetTester tester) async {
    final button = find.byKey(const Key('oauth_launch_browser_button'));
    await tester.ensureVisible(button);
    await tester.pumpAndSettle();
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockStorage = MockStorageService();
    mockOAuthService = MockOAuthPkceService();

    when(mockStorage.read(key: 'instance_url'))
        .thenAnswer((_) async => 'https://twentycrm.example.com');
    when(mockOAuthService.getSavedClientId(any)).thenAnswer((_) async => null);
    when(mockOAuthService.getSavedClientSecret(any))
        .thenAnswer((_) async => null);
  });

  testWidgets('renders header, client ID field, redirect URI and action buttons',
      (tester) async {
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());

    await pumpScreen(tester);

    expect(find.byKey(const Key('oauth_client_id_field')), findsOneWidget);
    expect(find.byKey(const Key('oauth_launch_browser_button')), findsOneWidget);
    expect(find.text('https://twentycrm.example.com'), findsOneWidget);
    expect(find.text('Twenty v1.19.0'), findsOneWidget);
    expect(find.text('Sign in with Browser'), findsOneWidget);
    expect(find.text(OAuthPkceService.defaultRedirectUri), findsOneWidget);
  });

  testWidgets('pre-fills the saved client ID if available', (tester) async {
    when(mockOAuthService.getSavedClientId(any))
        .thenAnswer((_) async => 'saved-client-id-999');
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());

    await pumpScreen(tester);

    final textField = tester.widget<TextFormField>(
      find.byKey(const Key('oauth_client_id_field')),
    );
    expect(textField.controller?.text, 'saved-client-id-999');
    // A stored client id means nothing has to be explained manually.
    expect(find.byKey(const Key('oauth_manual_client_notice')), findsNothing);
  });

  testWidgets('explains the missing automatic registration without opening the browser',
      (tester) async {
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());

    await pumpScreen(tester);

    expect(find.byKey(const Key('oauth_manual_client_notice')), findsOneWidget);
    verifyNever(mockOAuthService.tryAutoRegisterClient(any));
    verifyNever(mockOAuthService.loginWithOAuth(
      instanceUrl: anyNamed('instanceUrl'),
      clientId: anyNamed('clientId'),
      clientSecret: anyNamed('clientSecret'),
      redirectUri: anyNamed('redirectUri'),
      mode: anyNamed('mode'),
    ));
  });

  testWidgets('auto-registers the client when the instance advertises dynamic registration',
      (tester) async {
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithRegistration());
    when(mockOAuthService.tryAutoRegisterClient(any)).thenAnswer(
      (_) async => (clientId: 'auto-registered-id', clientSecret: null),
    );

    await pumpScreen(tester);

    verify(mockOAuthService.saveClientCredentials(
      'https://twentycrm.example.com',
      clientId: 'auto-registered-id',
      clientSecret: null,
    )).called(1);

    final textField = tester.widget<TextFormField>(
      find.byKey(const Key('oauth_client_id_field')),
    );
    expect(textField.controller?.text, 'auto-registered-id');
    expect(find.byKey(const Key('oauth_manual_client_notice')), findsNothing);
    // Registration alone must never launch a browser page.
    verifyNever(mockOAuthService.loginWithOAuth(
      instanceUrl: anyNamed('instanceUrl'),
      clientId: anyNamed('clientId'),
      clientSecret: anyNamed('clientSecret'),
      redirectUri: anyNamed('redirectUri'),
      mode: anyNamed('mode'),
    ));
  });

  testWidgets('blocks an empty client ID with its own message', (tester) async {
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());

    await pumpScreen(tester);

    await tapLaunchBrowser(tester);

    expect(find.text('Enter the OAuth Client ID'), findsOneWidget);
    verifyNever(mockOAuthService.loginWithOAuth(
      instanceUrl: anyNamed('instanceUrl'),
      clientId: anyNamed('clientId'),
      clientSecret: anyNamed('clientSecret'),
      redirectUri: anyNamed('redirectUri'),
      mode: anyNamed('mode'),
    ));
  });

  testWidgets('surfaces the failure reason when the sign-in fails',
      (tester) async {
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());
    when(mockOAuthService.loginWithOAuth(
      instanceUrl: anyNamed('instanceUrl'),
      clientId: anyNamed('clientId'),
      clientSecret: anyNamed('clientSecret'),
      redirectUri: anyNamed('redirectUri'),
      mode: anyNamed('mode'),
    )).thenThrow(OAuthException('invalid_client'));

    await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const Key('oauth_client_id_field')),
      'client-1',
    );
    await tester.pumpAndSettle();
    await tapLaunchBrowser(tester);

    expect(find.text('invalid_client'), findsOneWidget);
    expect(find.byKey(const Key('oauth_launch_browser_button')), findsOneWidget);
    verify(mockOAuthService.clearSavedClient('https://twentycrm.example.com')).called(1);
  });

  testWidgets('pre-fills the shared client ID from the registry when available and saves locally',
      (tester) async {
    when(mockOAuthService.fetchSharedClientId(any))
        .thenAnswer((_) async => 'shared-team-client-id');
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());

    await pumpScreen(tester);

    final textField = tester.widget<TextFormField>(
      find.byKey(const Key('oauth_client_id_field')),
    );
    expect(textField.controller?.text, 'shared-team-client-id');
    expect(find.byKey(const Key('oauth_manual_client_notice')), findsNothing);
    verify(mockOAuthService.saveClientCredentials(
      'https://twentycrm.example.com',
      clientId: 'shared-team-client-id',
    )).called(1);
  });

  testWidgets('ignores a shared client ID the instance already rejected',
      (tester) async {
    when(mockOAuthService.fetchSharedClientId(any))
        .thenAnswer((_) async => 'shared-team-client-id');
    when(mockOAuthService.rejectedSharedClientId(any))
        .thenAnswer((_) async => 'shared-team-client-id');
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());

    await pumpScreen(tester);

    final textField = tester.widget<TextFormField>(
      find.byKey(const Key('oauth_client_id_field')),
    );
    expect(textField.controller?.text, isEmpty);
    // Without a usable client id the manual instructions must come back.
    expect(find.byKey(const Key('oauth_manual_client_notice')), findsOneWidget);
    verifyNever(mockOAuthService.saveClientCredentials(
      'https://twentycrm.example.com',
      clientId: anyNamed('clientId'),
      clientSecret: anyNamed('clientSecret'),
    ));
  });

  testWidgets('marks a registry-served client ID as rejected when the instance refuses it',
      (tester) async {
    when(mockOAuthService.fetchSharedClientId(any))
        .thenAnswer((_) async => 'shared-team-client-id');
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());
    when(mockOAuthService.loginWithOAuth(
      instanceUrl: anyNamed('instanceUrl'),
      clientId: anyNamed('clientId'),
      clientSecret: anyNamed('clientSecret'),
      redirectUri: anyNamed('redirectUri'),
      mode: anyNamed('mode'),
    )).thenThrow(OAuthException('invalid_client', errorCode: 'invalid_client'));

    await pumpScreen(tester);
    await tapLaunchBrowser(tester);

    verify(mockOAuthService.clearSavedClient('https://twentycrm.example.com'))
        .called(1);
    verify(mockOAuthService.markSharedClientIdRejected(
      'https://twentycrm.example.com',
      'shared-team-client-id',
    )).called(1);
  });

  testWidgets('keeps stored credentials when the failure is not a client rejection',
      (tester) async {
    when(mockOAuthService.fetchServerMetadata(any))
        .thenAnswer((_) async => metadataWithoutRegistration());
    when(mockOAuthService.loginWithOAuth(
      instanceUrl: anyNamed('instanceUrl'),
      clientId: anyNamed('clientId'),
      clientSecret: anyNamed('clientSecret'),
      redirectUri: anyNamed('redirectUri'),
      mode: anyNamed('mode'),
    )).thenThrow(OAuthException('Token request timed out', statusCode: 500));

    await pumpScreen(tester);
    await tester.enterText(
      find.byKey(const Key('oauth_client_id_field')),
      'client-1',
    );
    await tester.pumpAndSettle();
    await tapLaunchBrowser(tester);

    expect(find.text('Token request timed out'), findsOneWidget);
    // The client id was not at fault: it must survive for the next attempt.
    verifyNever(mockOAuthService.clearSavedClient(any));
    verifyNever(mockOAuthService.markSharedClientIdRejected(any, any));
  });
}

