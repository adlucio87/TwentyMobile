import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:pocketcrm/presentation/shared/skeleton_loading.dart';
import 'package:pocketcrm/core/utils/color_utils.dart';

enum LinkedContactType { company, task }

class LinkedContactsWidget extends ConsumerWidget {
  final String entityId;
  final LinkedContactType type;
  final bool isCompact;

  const LinkedContactsWidget({
    Key? key,
    required this.entityId,
    required this.type,
    this.isCompact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Contact>> contactsAsync;

    switch (type) {
      case LinkedContactType.company:
        contactsAsync = ref.watch(companyContactsProvider(entityId));
        break;
      case LinkedContactType.task:
        contactsAsync = ref.watch(taskContactsProvider(entityId));
        break;
    }

    return contactsAsync.when(
      data: (contacts) {
        if (contacts.isEmpty) {
          if (isCompact) return const SizedBox.shrink();
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text('No linked contacts'),
          );
        }

        if (isCompact) {
          return Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              bottom: 8.0,
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ...contacts.take(3).map<Widget>((contact) {
                  final bgColor = ColorUtils.avatarColor(contact.firstName);
                  return GestureDetector(
                    onTap: () => context.push('/contacts/${contact.id}'),
                    child: Chip(
                      padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    avatar: CircleAvatar(
                      radius: 12,
                      backgroundColor: bgColor.withOpacity(0.2),
                      backgroundImage: contact.avatarUrl != null
                          ? CachedNetworkImageProvider(contact.avatarUrl!)
                          : null,
                      child: contact.avatarUrl == null
                          ? Text(
                              contact.firstName.isNotEmpty
                                  ? contact.firstName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 10,
                                color: bgColor,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    label: Text(
                        '${contact.firstName} ${contact.lastName}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  );
                }),
                if (contacts.length > 3)
                  Chip(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    label: Text(
                      '+${contacts.length - 3} others',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Text(
                'Linked Contacts',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: contacts.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.primaryContainer,
                    backgroundImage: contact.avatarUrl != null
                        ? CachedNetworkImageProvider(contact.avatarUrl!)
                        : null,
                    child: contact.avatarUrl == null
                        ? Text(
                            contact.firstName.isNotEmpty
                                ? contact.firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  title: Text(
                    '${contact.firstName} ${contact.lastName}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    contact.email ?? contact.phone ?? 'No details',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 20),
                  onTap: () => context.push('/contacts/${contact.id}'),
                );
              },
            ),
          ],
        );
      },
      loading: () => isCompact
          ? const SizedBox.shrink()
          : const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: ListSkeleton(itemCount: 2, shrinkWrap: true),
            ),
      error: (err, stack) => isCompact
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: $err',
                style: const TextStyle(color: Colors.red),
              ),
            ),
    );
  }
}
