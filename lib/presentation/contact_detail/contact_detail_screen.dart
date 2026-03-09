import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/models/contact.dart';

class ContactDetailScreen extends ConsumerWidget {
  final String id;
  const ContactDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(contactDetailProvider(id));

    return Scaffold(
      appBar: AppBar(title: const Text('Dettaglio Contatto')),
      body: detailAsync.when(
        data: (contact) => _buildDetail(context, contact),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
      ),
    );
  }

  Widget _buildDetail(BuildContext context, Contact contact) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundImage: contact.avatarUrl != null
                ? NetworkImage(contact.avatarUrl!)
                : null,
            child: contact.avatarUrl == null
                ? Text(
                    contact.firstName.isNotEmpty ? contact.firstName[0] : '?',
                    style: const TextStyle(fontSize: 40),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          Text(
            '${contact.firstName} ${contact.lastName}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          if (contact.companyName != null)
            Text(
              contact.companyName!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          const SizedBox(height: 32),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.email),
                  title: Text(contact.email ?? 'Nessuna email'),
                ),
                ListTile(
                  leading: const Icon(Icons.phone),
                  title: Text(contact.phone ?? 'Nessun telefono'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Note relative',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          // TODO: Implementare list notes by contact
          const Center(
            child: Text('Note non disponibili in questa view semplificata'),
          ),
        ],
      ),
    );
  }
}
