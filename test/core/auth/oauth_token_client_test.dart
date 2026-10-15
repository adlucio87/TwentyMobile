import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pocketcrm/core/auth/oauth_token_client.dart';

void main() {
  group('normalizeBaseUrl', () {
    test('strips trailing slashes and whitespace', () {
      expect(
        OAuthTokenClient.normalizeBaseUrl(' https://crm.example.com/// '),
        'https://crm.example.com',
      );
    });
  });

  group('fetchMetadata', () {
    test('parses the discovery document plus the public client config',
        () async {
      final client = OAuthTokenClient(
        httpClient: MockClient((request) async {
          switch (request.url.path) {
            case '/.well-known/oauth-authorization-server':
              return http.Response(
                jsonEncode({
                  'authorization_endpoint': 'https://crm.example.com/authorize',
                  'token_endpoint': 'https://crm.example.com/oauth/token',
                  'grant_types_supported': ['authorization_code', 'refresh_token'],
                  'code_challenge_methods_supported': ['S256'],
                }),
                200,
              );
            case '/client-config':
              return http.Response(
                jsonEncode({
                  'appVersion': 'v1.19.0',
                  'isMultiWorkspaceEnabled': false,
                }),
                200,
              );
            default:
              return http.Response('Not Found', 404);
          }
        }),
      );

      final metadata = await client.fetchMetadata('https://crm.example.com/');

      expect(metadata, isNotNull);
      expect(
        metadata!.authorizationEndpoint.toString(),
        'https://crm.example.com/authorize',
      );
      expect(
        metadata.tokenEndpoint.toString(),
        'https://crm.example.com/oauth/token',
      );
      expect(metadata.registrationEndpoint, isNull);
      expect(metadata.supportsDynamicRegistration, isFalse);
      expect(metadata.supportsRefreshTokenGrant, isTrue);
      expect(metadata.supportsPkceS256, isTrue);
      expect(metadata.appVersion, 'v1.19.0');
      expect(metadata.isMultiWorkspaceEnabled, isFalse);
    });

    test('exposes the registration endpoint when the instance advertises it',
        () async {
      final client = OAuthTokenClient(
        httpClient: MockClient((request) async {
          if (request.url.path == '/.well-known/oauth-authorization-server') {
            return http.Response(
              jsonEncode({
                'authorization_endpoint': 'https://crm.example.com/authorize',
                'token_endpoint': 'https://crm.example.com/oauth/token',
                'registration_endpoint': 'https://crm.example.com/oauth/register',
                'grant_types_supported': ['authorization_code'],
                'code_challenge_methods_supported': ['S256'],
              }),
              200,
            );
          }
          return http.Response('Not Found', 404);
        }),
      );

      final metadata = await client.fetchMetadata('https://crm.example.com');

      expect(metadata!.supportsDynamicRegistration, isTrue);
      expect(metadata.supportsRefreshTokenGrant, isFalse);
    });

    test('returns null when the instance publishes no discovery document',
        () async {
      final client = OAuthTokenClient(
        httpClient: MockClient((_) async => http.Response('Cannot GET', 404)),
      );

      expect(await client.fetchMetadata('https://crm.example.com'), isNull);
    });
  });

  group('refreshTokens', () {
    test('posts grant_type=refresh_token and returns the rotated tokens',
        () async {
      late Map<String, dynamic> sentBody;
      final client = OAuthTokenClient(
        httpClient: MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          expect(request.url.path, '/oauth/token');
          return http.Response(
            jsonEncode({
              'access_token': 'new-access',
              'refresh_token': 'rotated-refresh',
              'expires_in': 7200,
            }),
            200,
          );
        }),
      );

      final tokens = await client.refreshTokens(
        instanceUrl: 'https://crm.example.com',
        clientId: 'client-1',
        refreshToken: 'old-refresh',
      );

      expect(sentBody['grant_type'], 'refresh_token');
      expect(sentBody['client_id'], 'client-1');
      expect(sentBody['refresh_token'], 'old-refresh');
      expect(sentBody.containsKey('client_secret'), isFalse);
      expect(tokens.accessToken, 'new-access');
      expect(tokens.refreshToken, 'rotated-refresh');
      expect(tokens.expiresIn, 7200);
    });

    test('sends client_secret only when the instance issued one', () async {
      late Map<String, dynamic> sentBody;
      final client = OAuthTokenClient(
        httpClient: MockClient((request) async {
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({'access_token': 'a', 'refresh_token': 'r'}),
            200,
          );
        }),
      );

      await client.refreshTokens(
        instanceUrl: 'https://crm.example.com',
        clientId: 'client-1',
        refreshToken: 'old-refresh',
        clientSecret: 'shh',
      );

      expect(sentBody['client_secret'], 'shh');
    });

    test('defaults expires_in to 3600 when the server omits it', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'access_token': 'a', 'refresh_token': 'r'}),
            200,
          ),
        ),
      );

      final tokens = await client.refreshTokens(
        instanceUrl: 'https://crm.example.com',
        clientId: 'client-1',
        refreshToken: 'old-refresh',
      );

      expect(tokens.expiresIn, 3600);
    });

    test('maps an RFC-compliant error_description to the exception message',
        () async {
      final client = OAuthTokenClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': 'invalid_grant',
              'error_description': 'Refresh token expired',
            }),
            400,
          ),
        ),
      );

      await expectLater(
        client.refreshTokens(
          instanceUrl: 'https://crm.example.com',
          clientId: 'client-1',
          refreshToken: 'old-refresh',
        ),
        throwsA(
          isA<OAuthException>()
              .having((e) => e.message, 'message', 'Refresh token expired')
              .having((e) => e.statusCode, 'statusCode', 400)
              .having((e) => e.errorCode, 'errorCode', 'invalid_grant'),
        ),
      );
    });

    test('maps the NestJS validation message list', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'message': ['client_id should not be null', 'client_secret is required'],
              'error': 'Unauthorized',
            }),
            401,
          ),
        ),
      );

      await expectLater(
        client.refreshTokens(
          instanceUrl: 'https://crm.example.com',
          clientId: 'client-1',
          refreshToken: 'old-refresh',
        ),
        throwsA(
          isA<OAuthException>().having(
            (e) => e.message,
            'message',
            'client_id should not be null, client_secret is required',
          ),
        ),
      );
    });

    test('rejects a 200 response without an access_token', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode({'refresh_token': 'r'}), 200),
        ),
      );

      await expectLater(
        client.refreshTokens(
          instanceUrl: 'https://crm.example.com',
          clientId: 'client-1',
          refreshToken: 'old-refresh',
        ),
        throwsA(
          isA<OAuthException>().having(
            (e) => e.message,
            'message',
            contains('Missing access_token'),
          ),
        ),
      );
    });
  });

  group('registerClient', () {
    test('returns the issued credentials on 201', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient(
          (request) async => http.Response(
            jsonEncode({
              'client_id': 'issued-id',
              'client_secret': 'issued-secret',
            }),
            201,
          ),
        ),
      );

      final credentials = await client.registerClient(
        instanceUrl: 'https://crm.example.com',
        redirectUri: 'https://bouncer.example.com/oauth/callback',
      );

      expect(credentials!.clientId, 'issued-id');
      expect(credentials.clientSecret, 'issued-secret');
    });

    test('returns null when the instance answers 404', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient(
          (_) async => http.Response('Cannot POST /oauth/register', 404),
        ),
      );

      expect(
        await client.registerClient(
          instanceUrl: 'https://crm.example.com',
          redirectUri: 'https://bouncer.example.com/oauth/callback',
        ),
        isNull,
      );
    });
  });

  group('fetchSharedClientId', () {
    test('returns clientId when registry responds with exists: true', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient((request) async {
          expect(request.url.queryParameters['instance'], 'https://crm.example.com');
          return http.Response(
            jsonEncode({'exists': true, 'clientId': 'shared-client-456'}),
            200,
          );
        }),
      );

      final clientId = await client.fetchSharedClientId(
        instanceUrl: 'https://crm.example.com',
        registryUrl: 'https://registry.example.com/api/oauth-client',
      );

      expect(clientId, 'shared-client-456');
    });

    test('returns null when registry responds with exists: false', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient((_) async =>
            http.Response(jsonEncode({'exists': false}), 200)),
      );

      final clientId = await client.fetchSharedClientId(
        instanceUrl: 'https://crm.example.com',
        registryUrl: 'https://registry.example.com/api/oauth-client',
      );

      expect(clientId, isNull);
    });

    test('returns null on HTTP error or network failure', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient((_) async => http.Response('Server Error', 500)),
      );

      final clientId = await client.fetchSharedClientId(
        instanceUrl: 'https://crm.example.com',
        registryUrl: 'https://registry.example.com/api/oauth-client',
      );

      expect(clientId, isNull);
    });
  });

  group('registerSharedClientId', () {
    test('returns true when registry accepts POST', () async {
      late Map<String, dynamic> body;
      final client = OAuthTokenClient(
        httpClient: MockClient((request) async {
          body = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(jsonEncode({'success': true}), 200);
        }),
      );

      final success = await client.registerSharedClientId(
        instanceUrl: 'https://crm.example.com',
        clientId: 'my-id',
        registryUrl: 'https://registry.example.com/api/oauth-client',
      );

      expect(success, isTrue);
      expect(body['instance'], 'https://crm.example.com');
      expect(body['clientId'], 'my-id');
    });

    test('returns false on error', () async {
      final client = OAuthTokenClient(
        httpClient: MockClient((_) async => http.Response('Error', 400)),
      );

      final success = await client.registerSharedClientId(
        instanceUrl: 'https://crm.example.com',
        clientId: 'my-id',
        registryUrl: 'https://registry.example.com/api/oauth-client',
      );

      expect(success, isFalse);
    });
  });

  group('isClientRejection', () {
    test('is true when the server refuses the client credentials', () {
      expect(isClientRejection(OAuthException('invalid_client')), isTrue);
      expect(
        isClientRejection(OAuthException('boom', errorCode: 'invalid_client')),
        isTrue,
      );
      expect(
        isClientRejection(OAuthException('unknown client', errorCode: 'INVALID_CLIENT')),
        isTrue,
      );
      expect(isClientRejection(OAuthException('unknown client id')), isTrue);
      expect(isClientRejection(OAuthException('invalid client_id provided')), isTrue);
    });

    test('is false for unrelated failures that merely mention a client', () {
      // The previous check was `message.contains('client')`: these all wiped
      // stored credentials even though the client id was never at fault.
      expect(
        isClientRejection(OAuthException('Token request timed out', statusCode: 500)),
        isFalse,
      );
      expect(isClientRejection(OAuthException('OAuth request failed (HTTP 502)')), isFalse);
      expect(isClientRejection(OAuthException('client_secret is missing')), isFalse);
      expect(isClientRejection(OAuthException('Invalid credentials for the user')), isFalse);
    });
  });
}
