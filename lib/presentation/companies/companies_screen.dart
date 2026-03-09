import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/di/auth_state.dart';

class CompaniesScreen extends ConsumerWidget {
  const CompaniesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companiesAsync = ref.watch(companiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Aziende'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authStateProvider.notifier).logout(),
            tooltip: 'Logout / Reset',
          ),
        ],
      ),
      body: companiesAsync.when(
        data: (companies) {
          if (companies.isEmpty) {
            return const Center(child: Text('Nessuna azienda trovata.'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(companiesProvider.future),
            child: ListView.separated(
              itemCount: companies.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final company = companies[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: company.logoUrl != null
                        ? NetworkImage(company.logoUrl!)
                        : null,
                    child: company.logoUrl == null
                        ? const Icon(Icons.business)
                        : null,
                  ),
                  title: Text(company.name),
                  subtitle: Text(
                    company.industry ?? company.website ?? 'Nessun dettaglio',
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Errore: $err')),
      ),
    );
  }
}
