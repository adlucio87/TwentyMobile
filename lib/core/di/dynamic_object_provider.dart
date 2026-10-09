import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/dynamic_record.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/data/connectors/dynamic_object_connector.dart';
import 'package:pocketcrm/core/di/metadata_provider.dart';
import 'package:pocketcrm/core/network/custom_http_client.dart';

part 'dynamic_object_provider.g.dart';

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
@riverpod
class CustomObjectsFilter extends _$CustomObjectsFilter {
  @override
  bool build() => true;

  void setFilter(bool value) {
    state = value;
  }
}

/// Provider for the list of custom objects available in the workspace
@riverpod
Future<List<ObjectMetadata>> availableCustomObjects(AvailableCustomObjectsRef ref) async {
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
}

/// Provider for the DynamicObjectConnector
@riverpod
Future<DynamicObjectConnector> dynamicObjectConnector(DynamicObjectConnectorRef ref) async {
  final storage = ref.watch(storageServiceProvider);
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
}

/// Notifier for a paginated list of DynamicRecords for a given object type
@riverpod
class DynamicObjectList extends _$DynamicObjectList {
  String? _cursor;
  bool _hasMore = true;
  bool get hasMore => _hasMore;
  bool _isLoadingMore = false;
  String _search = '';
  ObjectMetadata? _metadata;

  @override
  FutureOr<List<DynamicRecord>> build(String objectType) async {
    final allMetadata = await ref.read(workspaceMetadataProvider.future);
    _metadata = allMetadata.firstWhere((m) => m.nameSingular == objectType);
    return _fetch();
  }

  Future<List<DynamicRecord>> _fetch() async {
    final connector = await ref.read(dynamicObjectConnectorProvider.future);
    final result = await connector.getRecords(
      _metadata!,
      search: _search.isNotEmpty ? _search : null,
      pageSize: 20,
    );
    _cursor = result.endCursor;
    _hasMore = result.hasNextPage;
    return result.records;
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
    } catch (e) {
      // Don't replace state on loadMore error, keep existing data
      debugPrint('Error loading more: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> search(String query) async {
    _search = query;
    _cursor = null;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }

  Future<void> refresh() async {
    _cursor = null;
    _hasMore = true;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetch());
  }
}

/// Provider for a single dynamic record detail
@riverpod
Future<DynamicRecord> dynamicRecordDetail(
  DynamicRecordDetailRef ref, {
  required String objectType,
  required String id,
}) async {
  final connector = await ref.read(dynamicObjectConnectorProvider.future);
  final allMetadata = await ref.read(workspaceMetadataProvider.future);
  final metadata = allMetadata.firstWhere((m) => m.nameSingular == objectType);
  return connector.getRecordById(metadata, id);
}
