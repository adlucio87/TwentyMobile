import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pocketcrm/domain/models/dynamic_record.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/data/connectors/dynamic_object_connector.dart';
import 'package:pocketcrm/core/di/metadata_provider.dart';
import 'package:pocketcrm/core/network/custom_http_client.dart';

/// Blacklisted objects that are already managed natively by the app
const _nativeObjects = {
  'person', 'company', 'task', 'note', 'noteTarget', 'taskTarget',
  'workspaceMember', 'workflow', 'message', 'messageChannel',
  'messageParticipant', 'attachment', 'favorite', 'view', 'viewField',
  'viewSort', 'viewFilter', 'webhook', 'calendarEvent', 'calendarChannel',
  'calendarChannelEventAssociation', 'connectedAccount', 'blocklist',
  'audit', 'behavioralEvent', 'timeline', 'timelineActivity',
  'messageThread', 'messageFolder', 'rocket',
};

/// Provider to control whether we show only custom/important objects or all of them
final customObjectsFilterProvider = StateProvider<bool>((ref) => true);

/// Provider for the list of custom objects available in the workspace
final availableCustomObjectsProvider = FutureProvider<List<ObjectMetadata>>((ref) async {
  final allMetadata = await ref.watch(workspaceMetadataProvider.future);
  final onlyCustom = ref.watch(customObjectsFilterProvider);

  return allMetadata
      .where((obj) => !_nativeObjects.contains(obj.nameSingular))
      .where((obj) => obj.fields.isNotEmpty)
      .where((obj) {
        if (!onlyCustom) return true;
        // Show custom objects and Opportunities
        return obj.isCustom || obj.nameSingular == 'opportunity';
      })
      .toList();
});

/// Provider for the DynamicObjectConnector
final dynamicObjectConnectorProvider = FutureProvider<DynamicObjectConnector>((ref) async {
  const storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  final token = await storage.read(key: 'api_token');
  final instanceUrl = await storage.read(key: 'instance_url');

  if (token == null || instanceUrl == null) {
    throw Exception('Not authenticated');
  }

  final customHttpClient = TimeoutHttpClient(timeoutDuration: const Duration(seconds: 30));
  final httpLink = HttpLink('$instanceUrl/graphql', httpClient: customHttpClient);
  final authLink = AuthLink(getToken: () async => 'Bearer $token');
  final link = authLink.concat(httpLink);
  final client = GraphQLClient(link: link, cache: GraphQLCache());

  return DynamicObjectConnector(client: client);
});

/// Notifier for a paginated list of DynamicRecords for a given object type
class DynamicObjectListNotifier extends StateNotifier<AsyncValue<List<DynamicRecord>>> {
  final Ref ref;
  final String objectType;
  String? _cursor;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool _isLoadingMore = false;
  String _search = '';
  ObjectMetadata? _metadata;

  DynamicObjectListNotifier(this.ref, this.objectType) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final allMetadata = await ref.read(workspaceMetadataProvider.future);
      _metadata = allMetadata.firstWhere((m) => m.nameSingular == objectType);
      await _fetch();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _fetch() async {
    try {
      final connector = await ref.read(dynamicObjectConnectorProvider.future);
      final result = await connector.getRecords(
        _metadata!,
        search: _search.isNotEmpty ? _search : null,
        pageSize: 20,
      );
      _cursor = result.endCursor;
      _hasMore = result.hasNextPage;
      state = AsyncValue.data(result.records);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore || _metadata == null) return;
    _isLoadingMore = true;
    try {
      final connector = await ref.read(dynamicObjectConnectorProvider.future);
      final result = await connector.getRecords(
        _metadata!,
        search: _search.isNotEmpty ? _search : null,
        pageSize: 20,
        after: _cursor,
      );
      _cursor = result.endCursor;
      _hasMore = result.hasNextPage;
      final current = state.value ?? [];
      state = AsyncValue.data([...current, ...result.records]);
    } catch (e, st) {
      // Don't replace state on loadMore error, keep existing data
      print('Error loading more: \$e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> search(String query) async {
    _search = query;
    _cursor = null;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch();
  }

  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    state = const AsyncValue.loading();
    await _fetch();
  }
}

/// Family provider for dynamic object lists
final dynamicObjectListProvider = StateNotifierProvider.family<
    DynamicObjectListNotifier, AsyncValue<List<DynamicRecord>>, String>(
  (ref, objectType) => DynamicObjectListNotifier(ref, objectType),
);

/// Provider for a single dynamic record detail
final dynamicRecordDetailProvider = FutureProvider.family<DynamicRecord, ({String objectType, String id})>(
  (ref, params) async {
    final connector = await ref.read(dynamicObjectConnectorProvider.future);
    final allMetadata = await ref.read(workspaceMetadataProvider.future);
    final metadata = allMetadata.firstWhere((m) => m.nameSingular == params.objectType);
    return connector.getRecordById(metadata, params.id);
  },
);
