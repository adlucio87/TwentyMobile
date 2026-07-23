import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/dynamic_object_provider.dart';
import 'package:pocketcrm/core/di/metadata_provider.dart';
import 'package:pocketcrm/core/utils/color_utils.dart';
import 'package:pocketcrm/domain/models/dynamic_record.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/presentation/dynamic_objects/dynamic_form_screen.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';
import 'package:pocketcrm/presentation/shared/empty_state_widget.dart';
import 'package:pocketcrm/shared/widgets/constrained_content.dart';

/// Generic list screen for any dynamic object type
class DynamicListScreen extends ConsumerStatefulWidget {
  final String objectType;

  const DynamicListScreen({super.key, required this.objectType});

  @override
  ConsumerState<DynamicListScreen> createState() => _DynamicListScreenState();
}

class _DynamicListScreenState extends ConsumerState<DynamicListScreen> {
  Timer? _debounce;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      ref.read(dynamicObjectListProvider(widget.objectType).notifier).loadMore();
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(dynamicObjectListProvider(widget.objectType).notifier).search(query);
    });
  }

  /// Try to extract a subtitle from record data
  String _getSubtitle(DynamicRecord record, ObjectMetadata? metadata) {
    // Try to find a secondary text field
    if (metadata == null) return '';
    final textFields = metadata.fields
        .where((f) => f.isActive && f.type.toUpperCase() == 'TEXT' && f.name != 'name')
        .toList();
    for (final field in textFields) {
      final value = record.data[field.name];
      if (value is String && value.isNotEmpty) return value;
    }
    // Try date
    if (record.createdAt != null) {
      return 'Created on ${record.createdAt!.day}/${record.createdAt!.month}/${record.createdAt!.year}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final recordsAsync = ref.watch(dynamicObjectListProvider(widget.objectType));
    final metadataAsync = ref.watch(workspaceMetadataProvider);

    // Get the label for this object type
    final objectMetadata = metadataAsync.valueOrNull
        ?.where((m) => m.nameSingular == widget.objectType)
        .firstOrNull;
    final title = objectMetadata?.labelPlural ?? widget.objectType;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search $title...',
            prefixIcon: const Icon(Icons.search),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(20),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surfaceContainerHighest
                : Colors.white,
          ),
          onChanged: _onSearchChanged,
        ),
      ),
      body: ConstrainedContent(
        child: recordsAsync.when(
          data: (records) {
            if (records.isEmpty) {
              return RefreshIndicator(
                onRefresh: () async {
                  await ref.read(dynamicObjectListProvider(widget.objectType).notifier).refresh();
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: EmptyStateWidget(
                      icon: Icons.dataset_outlined,
                      title: 'No records',
                      message: 'There are no records for $title.',
                    ),
                  ),
                ),
              );
            }

            final notifier = ref.read(dynamicObjectListProvider(widget.objectType).notifier);

            return RefreshIndicator(
              onRefresh: () async {
                await notifier.refresh();
              },
              child: ListView.separated(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: records.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  if (index == records.length) {
                    if (notifier.hasMore) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return const SizedBox.shrink();
                  }

                  final record = records[index];
                  final bgColor = ColorUtils.avatarColor(record.displayName);
                  final subtitle = _getSubtitle(record, objectMetadata);

                  return Card(
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      leading: CircleAvatar(
                        radius: 24,
                        backgroundColor: bgColor.withValues(alpha: 0.2),
                        child: Text(
                          record.displayName.isNotEmpty
                              ? record.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: bgColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      title: Text(
                        record.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      subtitle: subtitle.isNotEmpty
                          ? Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            )
                          : null,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () {
                              if (objectMetadata != null) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => DynamicFormScreen(
                                    metadata: objectMetadata,
                                    existingRecord: record,
                                  ),
                                ));
                              }
                            },
                          ),
                          Icon(
                            Icons.chevron_right,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      onTap: () {
                        context.push('/objects/${widget.objectType}/${record.id}');
                      },
                    ),
                  );
                },
              ),
            );
          },
          loading: () => const ListSkeleton(),
          error: (err, _) => ErrorStateWidget(
            title: 'Loading error',
            message: err.toString(),
            onRetry: () => ref.read(dynamicObjectListProvider(widget.objectType).notifier).refresh(),
          ),
        ),
      ),
      floatingActionButton: objectMetadata != null ? FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => DynamicFormScreen(
              metadata: objectMetadata,
            ),
          ));
        },
        child: const Icon(Icons.add),
      ) : null,
    );
  }
}
