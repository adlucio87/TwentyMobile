import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/domain/models/contact.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pocketcrm/core/utils/color_utils.dart';

class RecentContactsRow extends StatelessWidget {
  final List<Contact> contacts;

  const RecentContactsRow({super.key, required this.contacts});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          final bgColor = ColorUtils.avatarColor(contact.firstName);
          return GestureDetector(
            onTap: () => context.push('/contacts/${contact.id}'),
            child: Container(
              width: 72,
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: bgColor.withOpacity(0.2),
                    backgroundImage:
                        (contact.avatarUrl != null &&
                            contact.avatarUrl!.isNotEmpty)
                        ? CachedNetworkImageProvider(contact.avatarUrl!)
                        : null,
                    child:
                        (contact.avatarUrl == null ||
                            contact.avatarUrl!.isEmpty)
                        ? Text(
                            contact.firstName.isNotEmpty
                                ? contact.firstName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: bgColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    contact.firstName,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
