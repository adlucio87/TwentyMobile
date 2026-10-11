import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';
import '../../core/notifications/notification_service.dart';

class NotificationPermissionScreen extends StatelessWidget {
  const NotificationPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.notifications_active, size: 80, color: Colors.blue),
              const SizedBox(height: 24),
              Text(
                l10n.stayUpdated,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.receiveRemindersTasks,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              FilledButton(
                onPressed: () async {
                  await NotificationService().requestPermission();
                  if (context.mounted) {
                    context.go('/home');
                  }
                },
                child: Text(l10n.enableNotifications),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(l10n.notNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
