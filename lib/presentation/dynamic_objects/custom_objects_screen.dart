import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/dynamic_object_provider.dart';
import 'package:pocketcrm/core/utils/color_utils.dart';
import 'package:pocketcrm/domain/models/metadata/object_metadata.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:pocketcrm/presentation/shared/error_state_widget.dart';
import 'package:pocketcrm/presentation/shared/empty_state_widget.dart';
import 'package:pocketcrm/shared/widgets/constrained_content.dart';

/// Screen showing all available custom objects as a grid
class CustomObjectsScreen extends ConsumerWidget {
  const CustomObjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customObjectsAsync = ref.watch(availableCustomObjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('More'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final isFiltered = ref.watch(customObjectsFilterProvider);
              return Row(
                children: [
                  Text(
                    'My objects only',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Switch(
                    value: isFiltered,
                    onChanged: (val) => ref.read(customObjectsFilterProvider.notifier).state = val,
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ConstrainedContent(
        child: customObjectsAsync.when(
          data: (objects) {
            if (objects.isEmpty) {
              return const Center(
                child: EmptyStateWidget(
                  icon: Icons.apps,
                  title: 'No objects found',
                  message: 'Your workspace has no custom objects.',
                ),
              );
            }
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
              ),
              itemCount: objects.length,
              itemBuilder: (context, index) {
                final obj = objects[index];
                return _ObjectCard(metadata: obj);
              },
            );
          },
          loading: () => const ListSkeleton(),
          error: (err, _) => ErrorStateWidget(
            title: 'Loading error',
            message: err.toString(),
            onRetry: () => ref.invalidate(availableCustomObjectsProvider),
          ),
        ),
      ),
    );
  }
}

class _ObjectCard extends StatelessWidget {
  final ObjectMetadata metadata;

  const _ObjectCard({required this.metadata});

  IconData _iconFromMetadata(ObjectMetadata meta) {
    // Twenty CRM stores icons as emoji-like identifiers (e.g., "IconBuildingSkyscraper")
    // Map common ones, fallback to a generic icon
    final iconStr = meta.icon?.toLowerCase() ?? '';
    if (iconStr.contains('building')) return Icons.business;
    if (iconStr.contains('user') || iconStr.contains('person')) return Icons.person;
    if (iconStr.contains('briefcase') || iconStr.contains('suitcase')) return Icons.work;
    if (iconStr.contains('calendar')) return Icons.calendar_today;
    if (iconStr.contains('mail') || iconStr.contains('email')) return Icons.email;
    if (iconStr.contains('phone')) return Icons.phone;
    if (iconStr.contains('rocket')) return Icons.rocket_launch;
    if (iconStr.contains('star')) return Icons.star;
    if (iconStr.contains('chart') || iconStr.contains('graph')) return Icons.bar_chart;
    if (iconStr.contains('file') || iconStr.contains('document')) return Icons.description;
    if (iconStr.contains('target')) return Icons.gps_fixed;
    if (iconStr.contains('tag')) return Icons.label;
    if (iconStr.contains('money') || iconStr.contains('currency') || iconStr.contains('dollar')) return Icons.attach_money;
    if (iconStr.contains('car') || iconStr.contains('vehicle')) return Icons.directions_car;
    if (iconStr.contains('home') || iconStr.contains('house')) return Icons.home;
    if (iconStr.contains('map') || iconStr.contains('location')) return Icons.location_on;
    if (iconStr.contains('settings') || iconStr.contains('gear')) return Icons.settings;
    if (iconStr.contains('heart')) return Icons.favorite;
    if (iconStr.contains('check') || iconStr.contains('task')) return Icons.check_circle;
    if (iconStr.contains('list')) return Icons.list;
    if (iconStr.contains('link') || iconStr.contains('chain')) return Icons.link;
    if (iconStr.contains('note') || iconStr.contains('sticky')) return Icons.sticky_note_2;
    if (iconStr.contains('puzzle')) return Icons.extension;
    return Icons.dataset;
  }

  @override
  Widget build(BuildContext context) {
    final label = metadata.labelPlural ?? metadata.namePlural;
    final icon = _iconFromMetadata(metadata);
    final color = ColorUtils.avatarColor(metadata.nameSingular);
    final fieldCount = metadata.fields.where((f) => f.isActive).length;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          context.push('/objects/${metadata.nameSingular}');
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '$fieldCount fields',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
