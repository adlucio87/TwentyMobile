import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/theme/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pocketcrm/core/notifications/notification_service.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/domain/services/ios_contacts_provider_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/shared/widgets/constrained_content.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/core/localization/locale_provider.dart';
import 'package:pocketcrm/core/config/app_config.dart';

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
        } catch (e) {}
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
    final l10n = AppLocalizations.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final currentLocale = ref.watch(localeProvider);
    final currentOption = appLocaleOptions.firstWhere(
      (o) {
        if (currentLocale == null) return o.code == 'system';
        if (o.locale == null) return false;
        if (currentLocale.countryCode != null) {
          return o.locale!.languageCode == currentLocale.languageCode &&
              o.locale!.countryCode == currentLocale.countryCode;
        }
        return o.locale!.languageCode == currentLocale.languageCode &&
            o.locale!.countryCode == null;
      },
      orElse: () => appLocaleOptions[0],
    );

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
            l10n?.account ?? 'Account',
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
                  final isEmail = method == 'email';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isEmail ? Colors.green.withValues(alpha: 0.1) : Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isEmail
                                  ? (l10n?.personalAccount ?? 'Personal Account')
                                  : (l10n?.apiKeyAdmin ?? 'API Key Admin'),
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: isEmail ? Colors.green : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isEmail) ...[
                        const SizedBox(height: 16),
                        userNameAsync.when(
                          data: (name) => name.isNotEmpty
                              ? Text(name, style: Theme.of(context).textTheme.titleMedium)
                              : const SizedBox.shrink(),
                          loading: () => const CircularProgressIndicator(),
                          error: (_, __) => const SizedBox.shrink(),
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
                        label: Text(l10n?.changeLoginMethod ?? 'Change login method'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(40),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => Text(l10n?.error ?? 'Error loading account data'),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            l10n?.applicationTheme ?? 'Application Theme',
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
                label: Text(l10n?.themeSystem ?? 'System'),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode),
                label: Text(l10n?.themeLight ?? 'Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode),
                label: Text(l10n?.themeDark ?? 'Dark'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) {
              ref.read(themeModeProvider.notifier).setTheme(newSelection.first);
            },
          ),
          const SizedBox(height: 32),
          Text(
            l10n?.language ?? 'Language',
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
            subtitle: Text(l10n?.language ?? 'Language'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              showModalBottomSheet(
                context: context,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                builder: (modalContext) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            l10n?.language ?? 'Select Language',
                            style: Theme.of(modalContext).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Divider(height: 1),
                        Flexible(
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: appLocaleOptions.length,
                            itemBuilder: (context, index) {
                              final option = appLocaleOptions[index];
                              final isSelected = option.code == currentOption.code;
                              return ListTile(
                                leading: Text(option.flag, style: const TextStyle(fontSize: 24)),
                                title: Text(option.name),
                                trailing: isSelected
                                    ? const Icon(Icons.check, color: Colors.green)
                                    : null,
                                onTap: () {
                                  ref.read(localeProvider.notifier).setLocale(option.code);
                                  Navigator.pop(modalContext);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            l10n?.notifications ?? 'Notifications',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            title: Text(l10n?.taskReminderNotifications ?? 'Task reminders'),
            subtitle: Text(l10n?.receiveNotificationBeforeDueDate ?? 'Receive notification before due date'),
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _saveNotificationEnabled,
            ),
          ),
          ListTile(
            title: Text(l10n?.reminderAdvance ?? 'Reminder advance'),
            trailing: DropdownButton<int>(
              value: _reminderAdvanceMinutes,
              items: [
                DropdownMenuItem(value: 15, child: Text(l10n?.minutesBefore(15) ?? '15 minutes before')),
                DropdownMenuItem(value: 30, child: Text(l10n?.minutesBefore(30) ?? '30 minutes before')),
                DropdownMenuItem(value: 60, child: Text(l10n?.hourBefore ?? '1 hour before')),
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
              l10n?.iosContacts ?? 'iOS Contacts',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(l10n?.showTwentyInIosContacts ?? 'Show Twenty people in iOS Contacts'),
              subtitle: Text(
                l10n?.iosContactsSubtitle ??
                    'Adds a Twenty account in the Contacts app (iOS 18+). Does not copy contacts into iCloud.',
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
              l10n?.logout ?? 'Logout',
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
            title: Text(l10n?.privacyPolicy ?? 'Privacy Policy'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => launchUrl(Uri.parse('https://privacy.luciosoft.it/twentymobilecrm/')),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n?.termsOfUse ?? 'Terms of Use (EULA)'),
            trailing: const Icon(Icons.open_in_new, size: 20),
            onTap: () => launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/')),
          ),
        ],
      ),
      ),
    );
  }
}
