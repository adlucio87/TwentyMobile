import 'package:pocketcrm/core/utils/storage_service.dart';

/// Persists the OAuth client credentials **per instance**.
///
/// A `client_id` is only meaningful on the instance that issued it. Storing it
/// in a single global slot made the app replay a stale id after the user
/// switched instance, and the server answered with an opaque `invalid_client`
/// that no message could explain.
///
/// Reads fall back to the legacy global key and migrate it on the fly, so
/// installs that already stored a client id keep working.
class OAuthClientStore {
  /// Pre-per-instance key, written by earlier app versions.
  static const String legacyClientIdKey = 'oauth_client_id';

  final StorageService _storage;

  OAuthClientStore(this._storage);

  static String clientIdKey(String instanceUrl) =>
      'oauth_client_id_${_slug(instanceUrl)}';

  static String clientSecretKey(String instanceUrl) =>
      'oauth_client_secret_${_slug(instanceUrl)}';

  /// Client id the team registry served for [instanceUrl] and that was
  /// successfully published back (used to avoid a redundant POST per login).
  static String publishedClientIdKey(String instanceUrl) =>
      'oauth_client_shared_${_slug(instanceUrl)}';

  /// Client id the registry served but the instance refused: reusing it would
  /// loop the user through an error a second time.
  static String rejectedClientIdKey(String instanceUrl) =>
      'oauth_client_rejected_${_slug(instanceUrl)}';

  /// Stable, storage-safe fragment identifying the instance (its host when
  /// parseable, otherwise a slug of the raw URL).
  static String _slug(String instanceUrl) {
    final trimmed = instanceUrl.trim();
    final host = Uri.tryParse(trimmed)?.host ?? '';
    final source = host.isNotEmpty ? host : trimmed;
    return source
        .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  Future<String?> readClientId(String instanceUrl) async {
    final key = clientIdKey(instanceUrl);
    final stored = await _storage.read(key: key);
    if (stored != null && stored.isNotEmpty) return stored;

    final legacy = await _storage.read(key: legacyClientIdKey);
    if (legacy == null || legacy.isEmpty) return null;

    final migrated = legacy.trim();
    await _storage.write(key: key, value: migrated);
    await _storage.delete(key: legacyClientIdKey);
    return migrated;
  }

  Future<String?> readClientSecret(String instanceUrl) async {
    final secret = await _storage.read(key: clientSecretKey(instanceUrl));
    return (secret == null || secret.isEmpty) ? null : secret;
  }

  /// Stores the credentials the flow should reuse.
  ///
  /// [clientSecret] is optional: Twenty instances that advertise
  /// `token_endpoint_auth_method: none` (PKCE-only) never issue one.
  Future<void> saveClient(
    String instanceUrl, {
    required String clientId,
    String? clientSecret,
  }) async {
    await _storage.write(key: clientIdKey(instanceUrl), value: clientId.trim());
    if (clientSecret != null && clientSecret.isNotEmpty) {
      await _storage.write(
        key: clientSecretKey(instanceUrl),
        value: clientSecret,
      );
    }
  }

  /// Drops the global key left behind by earlier app versions.
  Future<void> clearLegacyClientId() =>
      _storage.delete(key: legacyClientIdKey);

  /// Client id already published to the shared registry for [instanceUrl].
  Future<String?> readPublishedClientId(String instanceUrl) async {
    final stored = await _storage.read(key: publishedClientIdKey(instanceUrl));
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  /// Remembers that [clientId] now lives in the shared registry.
  Future<void> savePublishedClientId(String instanceUrl, String clientId) =>
      _storage.write(
        key: publishedClientIdKey(instanceUrl),
        value: clientId.trim(),
      );

  /// Client id the registry served but the instance rejected.
  Future<String?> readRejectedClientId(String instanceUrl) async {
    final stored = await _storage.read(key: rejectedClientIdKey(instanceUrl));
    return (stored == null || stored.isEmpty) ? null : stored;
  }

  /// Marks [clientId] as unusable so the registry lookup skips it.
  Future<void> saveRejectedClientId(String instanceUrl, String clientId) =>
      _storage.write(
        key: rejectedClientIdKey(instanceUrl),
        value: clientId.trim(),
      );

  /// Forgets a previous rejection (the credentials just worked).
  Future<void> clearRejectedClientId(String instanceUrl) =>
      _storage.delete(key: rejectedClientIdKey(instanceUrl));

  /// Clears stored client credentials for [instanceUrl].
  Future<void> clearClient(String instanceUrl) async {
    await _storage.delete(key: clientIdKey(instanceUrl));
    await _storage.delete(key: clientSecretKey(instanceUrl));
    await _storage.delete(key: publishedClientIdKey(instanceUrl));
    await _storage.delete(key: rejectedClientIdKey(instanceUrl));
  }
}
