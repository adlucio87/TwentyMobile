import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/core/notifications/notification_service.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/data/connectors/base_graphql_connector.dart';
import 'package:pocketcrm/domain/models/workspace_member.dart';
import 'package:pocketcrm/presentation/home/today_provider.dart';
import 'package:pocketcrm/domain/services/ios_contacts_provider_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/shared/widgets/constrained_content.dart';
import 'package:pocketcrm/core/localization/locale_provider.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';
import 'package:pocketcrm/core/config/app_config.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  int _reminderAdvanceMinutes = 30;
  bool _iosContactsSupported = false;
  bool _iosContactsEnabled = false;
  bool _isSyncingIos = false;
  bool _errorReportingEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final iosSupported = await IosContactsProviderService.instance.isSupported();
    if (!mounted) return;
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _reminderAdvanceMinutes = prefs.getInt('reminder_advance_minutes') ?? 30;
      _iosContactsSupported = iosSupported;
      _iosContactsEnabled =
          prefs.getBool(iosContactsProviderEnabledPrefKey) ?? false;
      _errorReportingEnabled =
          prefs.getBool(AppConfig.errorReportingPrefKey) ?? true;
    });
  }

  Future<void> _saveErrorReportingEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConfig.errorReportingPrefKey, value);
    setState(() {
      _errorReportingEnabled = value;
    });
  }

  Future<void> _saveIosContactsEnabled(bool value) async {
    if (_isSyncingIos) return;
    setState(() {
      _isSyncingIos = true;
    });
    final service = IosContactsProviderService.instance;
    try {
      if (value) {
        final all = await ref
            .read(contactsProvider.notifier)
            .fetchAllContactsForIosProvider();
        if (!mounted) return;
        await service.writeSnapshot(all);
        if (!mounted) return;
        final enabled = await service.setEnabled(true);
        if (!mounted) return;
        if (!enabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not enable Twenty in iOS Contacts.'),
            ),
          );
          return;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(iosContactsProviderEnabledPrefKey, true);
        if (!mounted) return;
        setState(() {
          _iosContactsEnabled = true;
        });
      } else {
        try {
          await service.setEnabled(false);
          await service.writeSnapshot(const []);
        } catch (e) {
          // Best effort: the local flag is still updated below, and the next
          // full refresh retries the provider teardown.
          debugPrint('iOS contacts provider disable failed: $e');
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(iosContactsProviderEnabledPrefKey, false);
        if (mounted) {
          setState(() {
            _iosContactsEnabled = false;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not enable Twenty in iOS Contacts: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSyncingIos = false;
        });
      }
    }
  }

  Future<void> _saveNotificationEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      _notificationsEnabled = value;
    });

    if (value) {
      await NotificationService().requestPermission();
      final tasks = ref.read(tasksProvider).value;
      if (tasks != null) {
        await NotificationService().syncTaskNotifications(tasks);
      }
    } else {
      await NotificationService().cancelAll();
    }
  }

  Future<void> _saveReminderAdvance(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('reminder_advance_minutes', value);
    setState(() {
      _reminderAdvanceMinutes = value;
    });

    if (_notificationsEnabled) {
      final tasks = ref.read(tasksProvider).value;
      if (tasks != null) {
        await NotificationService().syncTaskNotifications(tasks);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final currentOption = ref.watch(selectedLocaleOptionProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
      ),
      body: ConstrainedContent(
        maxWidth: 600,
        child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text(
            l10n.account,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) {
              final authMethodAsync = ref.watch(authMethodProvider);
              final userNameAsync = ref.watch(currentUserNameProvider);

              return authMethodAsync.when(
                data: (method) {
                  final isUserSession = method == 'email' || method == 'sso';
                  final badgeColor = method == 'sso'
                      ? Colors.blue
                      : (method == 'email' ? Colors.green : Theme.of(context).colorScheme.primary);
                  final badgeText = method == 'sso'
                      ? l10n.googleSsoBadge
                      : (method == 'email' ? l10n.personalAccount : l10n.apiKeyAdmin);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: badgeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!isUserSession) ...[
                        const SizedBox(height: 8),
                        // An API key has no user behind it: let the person say who they are, so the
                        // greeting and "my tasks" are theirs and not the first workspace member's.
                        ListTile(
                          key: const Key('settings_i_am_tile'),
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.person_outline),
                          title: Text(l10n.iAm),
                          subtitle: Text(
                            (userNameAsync.valueOrNull ?? '').isNotEmpty
                                ? userNameAsync.valueOrNull!
                                : (l10n.iAmNotSet),
                          ),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => _chooseApiKeyMember(context, ref),
                        ),
                      ],
                      if (isUserSession) ...[
                        const SizedBox(height: 16),
                        userNameAsync.when(
                          data: (name) => name.isNotEmpty
                              ? Text(name, style: Theme.of(context).textTheme.titleMedium)
                              : const SizedBox.shrink(),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () async {
                          // Clear the current credentials to avoid router redirecting back to home
                          await ref.read(authServiceProvider).logout();
                          await ref.read(authStateProvider.notifier).logout();
                          if (context.mounted) {
                            context.go('/onboarding/method');
                          }
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(l10n.changeLoginMethod),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, _) => Text(l10n.error),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            l10n.applicationTheme,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto),
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode),
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode),
                label: Text(l10n.themeDark),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              ref.read(themeModeProvider.notifier).setTheme(newSelection.first);
            },
          ),
          const SizedBox(height: 32),
          Text(
            l10n.language,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
            leading: Text(currentOption.flag, style: const TextStyle(fontSize: 24)),
            title: Text(currentOption.name),
            subtitle: Text(l10n.language),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => showLanguageSelectionSheet(context, ref),
          ),
          const SizedBox(height: 32),
          Text(
            l10n.notifications,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(l10n.taskReminderNotifications),
            subtitle: Text(l10n.receiveNotificationBeforeDueDate),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _saveNotificationEnabled,
            ),
          ),
          ListTile(
            title: Text(l10n.reminderAdvance),
            trailing: DropdownButton<int>(
              value: _reminderAdvanceMinutes,
              items: [
                DropdownMenuItem(value: 15, child: Text(l10n.minutesBefore(15))),
                DropdownMenuItem(value: 30, child: Text(l10n.minutesBefore(30))),
                DropdownMenuItem(value: 60, child: Text(l10n.hourBefore)),
              ],
              onChanged: _notificationsEnabled
                  ? (value) {
                      if (value != null) _saveReminderAdvance(value);
                    }
                  : null,
            ),
          ),
          if (AppConfig.errorReportingBuildEnabled) ...[
            const SizedBox(height: 32),
            const Text(
              'Privacy',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Send crash reports'),
              subtitle: const Text(
                'Sends crash and error reports to the developer (GlitchTip). Takes effect after restarting the app.',
              ),
              trailing: Switch(
                value: _errorReportingEnabled,
                onChanged: _saveErrorReportingEnabled,
              ),
            ),
          ],
          if (_iosContactsSupported) ...[
            const SizedBox(height: 32),
            Text(
              l10n.iosContacts,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n.showTwentyInIosContacts),
              subtitle: Text(
                l10n.iosContactsSubtitle,
              ),
              trailing: _isSyncingIos
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Switch(
                      value: _iosContactsEnabled,
                      onChanged: _saveIosContactsEnabled,
                    ),
            ),
          ],
          const SizedBox(height: 48),
          const Divider(),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(
              l10n.logout,
              style: const TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              ref.read(authStateProvider.notifier).logout();
            },
          ),
          const SizedBox(height: 32),
          const Text(
            'Privacy & Terms',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l10n.privacyPolicy),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => launchUrl(Uri.parse('https://privacy.luciosoft.it/twentymobilecrm/')),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.termsOfUse),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/')),
          ),
        ],
      ),
      ),
    );
  }
}

/// Lets an API-key user pick which workspace member they are (stored on the device only).
Future<void> _chooseApiKeyMember(BuildContext context, WidgetRef ref) async {
  final l10n = context.l10n;
  final members = await ref.read(workspaceMembersProvider.future);
  if (!context.mounted) return;
  final picked = await showModalBottomSheet<WorkspaceMember>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.iAmHint),
          ),
          for (final m in members)
            ListTile(
              leading: const Icon(Icons.person),
              title: Text('${m.firstName} ${m.lastName}'.trim()),
              onTap: () => Navigator.of(context).pop(m),
            ),
        ],
      ),
    ),
  );
  if (picked == null) return;
  final storage = ref.read(storageServiceProvider);
  await storage.write(key: BaseGraphQLConnector.apiKeyMemberIdKey, value: picked.id);
  await storage.write(
    key: BaseGraphQLConnector.apiKeyMemberNameKey,
    value: '${picked.firstName} ${picked.lastName}'.trim(),
  );
  ref.invalidate(currentUserNameProvider);
  ref.invalidate(tasksProvider);
  ref.invalidate(todayNotifierProvider);
}

