import re

with open('lib/core/di/providers.dart', 'r') as f:
    content = f.read()

replacement = """@Riverpod(keepAlive: true)
Future<CRMRepository> crmRepository(CrmRepositoryRef ref) async {
  final storage = ref.watch(storageServiceProvider);

  final instanceUrl = storage.readSync('instance_url');
  if (instanceUrl == null) {
    throw Exception('Instance URL not found');
  }

  // Costruiamo i customFields prelevando i metadata
  Map<String, List<String>> customFieldsMap = {};
  try {
    final metadataState = ref.read(workspaceMetadataProvider);
    final metadata = metadataState.value;
    if (metadata != null) {
      final personMetadata = metadata.where((e) => e.nameSingular == 'person').firstOrNull;
      if (personMetadata != null) {
        customFieldsMap['person'] = personMetadata.fields
            .where((f) => f.isActive)
            .map((f) => f.name)
            .toList();
      }
      final companyMetadata = metadata.where((e) => e.nameSingular == 'company').firstOrNull;
      if (companyMetadata != null) {
        customFieldsMap['company'] = companyMetadata.fields
            .where((f) => f.isActive)
            .map((f) => f.name)
            .toList();
      }
    }
  } catch (_) {}

  final customHttpClient = TimeoutHttpClient(
    timeoutDuration: const Duration(seconds: 30),
  );

  final httpLink = HttpLink(
    '$instanceUrl/graphql',
    httpClient: customHttpClient,
  );

  final authLink = AuthLink(
    getToken: () async {
      final token = await const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      ).read(key: 'api_token');
      return token != null ? 'Bearer $token' : null;
    },
  );

  final link = authLink.concat(httpLink);

  final client = GraphQLClient(
    link: link,
    cache: GraphQLCache(),
    queryRequestTimeout: const Duration(seconds: 30),
  );
  final authService = ref.read(authServiceProvider);

  return TwentyConnector(
    client: client,
    authService: authService,
    customFields: customFieldsMap,
    onTokenRefreshed: () {
      // AuthService writes tokens directly to FlutterSecureStorage,
      // bypassing StorageService's in-memory cache. We must clear
      // the cache so AuthLink reads the fresh token.
      storage.invalidateCache(keys: [
        'api_token',
        'refresh_token',
        'token_expires_at',
      ]);
    },
  );
}"""

content = re.sub(
    r'@Riverpod\(keepAlive: true\)\nFuture<CRMRepository> crmRepository\(CrmRepositoryRef ref\) async \{[\s\S]*?    \},\n  \);\n\}',
    replacement,
    content
)

with open('lib/core/di/providers.dart', 'w') as f:
    f.write(content)
