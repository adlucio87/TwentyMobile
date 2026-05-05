import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/network/custom_http_client.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/data/graphql/auth_mutations.dart';

class AuthService {
  final FlutterSecureStorage _storage;

  AuthService(this._storage);

  Future<void> loginWithCredentials(
    String instanceUrl,
    String email,
    String password,
  ) async {
    final client = _createUnauthenticatedClient(instanceUrl);

    // Step 1: Get a temporary login token from credentials
    final loginOptions = MutationOptions(
      document: gql(getLoginTokenFromCredentialsMutation),
      variables: {
        'email': email,
        'password': password,
        'origin': instanceUrl,
      },
    );

    final loginResult = await client.mutate(loginOptions);

    if (loginResult.hasException) {
      final exStr = loginResult.exception.toString().toLowerCase();
      if (exStr.contains('unauthenticated') ||
          exStr.contains('wrong credentials') ||
          exStr.contains('invalid credentials') ||
          exStr.contains('wrong password') ||
          exStr.contains('wrong-credentials') ||
          exStr.contains('invalid password') ||
          exStr.contains('incorrect password')) {
        throw Exception('Invalid email or password.');
      }
      if (exStr.contains('user not found') ||
          exStr.contains('no account')) {
        throw Exception('No account found with this email.');
      }
      if (exStr.contains('password login is disabled') ||
          exStr.contains('password-login-disabled')) {
        throw Exception(
          'Password login is disabled on this Twenty instance.',
        );
      }
      throw Exception(loginResult.exception.toString());
    }

    final loginData = loginResult.data?['getLoginTokenFromCredentials'];
    if (loginData == null) {
      throw Exception('Invalid response from server');
    }

    final loginToken = loginData['loginToken']['token'] as String;

    // Step 2: Exchange login token for access + refresh tokens
    final tokenOptions = MutationOptions(
      document: gql(getAuthTokensFromLoginTokenMutation),
      variables: {
        'loginToken': loginToken,
        'origin': instanceUrl,
      },
    );

    final tokenResult = await client.mutate(tokenOptions);

    if (tokenResult.hasException) {
      throw Exception(tokenResult.exception.toString());
    }

    final tokenData = tokenResult.data?['getAuthTokensFromLoginToken'];
    if (tokenData == null) {
      throw Exception('Failed to exchange login token for access tokens');
    }

    final tokens = tokenData['tokens'];
    final accessToken = tokens['accessOrWorkspaceAgnosticToken']['token'] as String;
    final refreshToken = tokens['refreshToken']['token'] as String;
    final expiresAt = tokens['accessOrWorkspaceAgnosticToken']['expiresAt'] as String;

    // Now fetch user info with the new access token
    final authedClient = _createAuthenticatedClient(instanceUrl, accessToken);
    String userFirstName = '';
    String userLastName = '';
    try {
      const meQuery = r'''
        query Me {
          workspaceMembers(first: 1) {
            edges {
              node {
                name { firstName lastName }
              }
            }
          }
        }
      ''';
      final meResult = await authedClient.query(
        QueryOptions(document: gql(meQuery)),
      );
      final edges = meResult.data?['workspaceMembers']?['edges'] as List?;
      if (edges != null && edges.isNotEmpty) {
        final name = edges.first['node']?['name'];
        if (name != null) {
          userFirstName = name['firstName'] as String? ?? '';
          userLastName = name['lastName'] as String? ?? '';
        }
      }
    } catch (_) {
      // Non-critical: user name fetch failed, continue anyway
    }

    await _storage.write(key: 'api_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'token_expires_at', value: expiresAt);
    await _storage.write(key: 'auth_method', value: 'email');
    await _storage.write(key: 'user_first_name', value: userFirstName);
    await _storage.write(key: 'user_last_name', value: userLastName);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_expires_at', expiresAt);
  }

  Future<void> loginWithApiKey(String instanceUrl, String apiKey) async {
    await _storage.write(key: 'api_token', value: apiKey);
    await _storage.write(key: 'auth_method', value: 'api_key');
  }

  Future<bool> refreshAccessToken() async {
    final instanceUrl = await _storage.read(key: 'instance_url');
    final refreshToken = await _storage.read(key: 'refresh_token');

    if (instanceUrl == null || refreshToken == null) {
      await logout();
      return false;
    }

    final client = _createUnauthenticatedClient(instanceUrl);

    final options = MutationOptions(
      document: gql(renewTokenMutation),
      variables: {
        'appToken': refreshToken,
      },
    );

    final result = await client.mutate(options);

    if (result.hasException) {
      await logout();
      return false;
    }

    final data = result.data?['renewToken'];
    if (data == null) {
      await logout();
      return false;
    }

    final tokens = data['tokens'];
    final newAccessToken = tokens['accessOrWorkspaceAgnosticToken']['token'] as String;
    final newRefreshToken = tokens['refreshToken']['token'] as String;
    final expiresAt = tokens['accessOrWorkspaceAgnosticToken']['expiresAt'] as String;

    await _storage.write(key: 'api_token', value: newAccessToken);
    await _storage.write(key: 'refresh_token', value: newRefreshToken);
    await _storage.write(key: 'token_expires_at', value: expiresAt);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token_expires_at', expiresAt);

    return true;
  }

  Future<bool> isTokenExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAtStr = prefs.getString('token_expires_at');

    if (expiresAtStr == null) return false;

    final expiresAt = DateTime.tryParse(expiresAtStr);
    if (expiresAt == null) return false;

    // Se scade entro 5 minuti, consideralo scaduto
    return DateTime.now().toUtc().add(const Duration(minutes: 5)).isAfter(expiresAt);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'api_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'token_expires_at');
    await _storage.delete(key: 'auth_method');
    await _storage.delete(key: 'user_first_name');
    await _storage.delete(key: 'user_last_name');
    await _storage.delete(key: 'is_demo_mode');

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token_expires_at');
  }

  GraphQLClient _createUnauthenticatedClient(String baseUrl) {
    final customHttpClient = TimeoutHttpClient(
      timeoutDuration: const Duration(seconds: 30),
    );
    final link = HttpLink(
      '$baseUrl/metadata',
      httpClient: customHttpClient,
    );
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
  }

  GraphQLClient _createAuthenticatedClient(String baseUrl, String token) {
    final customHttpClient = TimeoutHttpClient(
      timeoutDuration: const Duration(seconds: 30),
    );
    final link = HttpLink(
      '$baseUrl/graphql',
      defaultHeaders: {'Authorization': 'Bearer $token'},
      httpClient: customHttpClient,
    );
    return GraphQLClient(
      link: link,
      cache: GraphQLCache(),
    );
  }
}
