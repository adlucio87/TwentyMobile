import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/network/custom_http_client.dart';
import 'package:pocketcrm/data/connectors/metadata_connector.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metadata_provider.g.dart';

@Riverpod(keepAlive: true)
Future<MetadataConnector> metadataConnector(MetadataConnectorRef ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final instanceUrl = await storage.read(key: 'instance_url');
  final token = await storage.read(key: 'api_token');

  if (instanceUrl == null) {
    throw Exception('Instance URL not found');
  }

  final customHttpClient = TimeoutHttpClient(
    timeoutDuration: const Duration(seconds: 30),
  );

  final Link link;
  if (token != null && token.isNotEmpty) {
    link = HttpLink(
      '$instanceUrl/metadata',
      defaultHeaders: {'Authorization': 'Bearer $token'},
      httpClient: customHttpClient,
    );
  } else {
    link = HttpLink(
      '$instanceUrl/metadata',
      httpClient: customHttpClient,
    );
  }

  final client = GraphQLClient(
    link: link,
    cache: GraphQLCache(),
    queryRequestTimeout: const Duration(seconds: 30),
  );

  return MetadataConnector(
    client: client,
    authService: ref.watch(authServiceProvider),
  );
}

@Riverpod(keepAlive: true)
class WorkspaceMetadata extends _$WorkspaceMetadata {
  @override
  FutureOr<List<ObjectMetadata>> build() async {
    final connector = await ref.watch(metadataConnectorProvider.future);
    return connector.getWorkspaceMetadata();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final connector = await ref.watch(metadataConnectorProvider.future);
      return connector.getWorkspaceMetadata();
    });
  }

  Future<ObjectMetadata?> getMetadataForObject(String nameSingular) async {
    if (!state.hasValue) {
      await refresh();
    }

    final metadata = state.value;
    if (metadata == null) return null;

    try {
      return metadata.firstWhere((element) => element.nameSingular == nameSingular);
    } catch (e) {
      return null;
    }
  }
}
