import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/localization/locale_provider.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

void showLanguageSelectionSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context);
  final currentLocale = ref.read(localeProvider);
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
                l10n?.selectLanguage ?? 'Select Language',
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
                    leading: Text(
                      option.flag,
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(option.name),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () {
                      ref
                          .read(localeProvider.notifier)
                          .setLocale(option.code);
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
}

class LanguageSelectorButton extends ConsumerWidget {
  final bool isCompact;

  const LanguageSelectorButton({
    super.key,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    if (isCompact) {
      return IconButton(
        icon: Text(
          currentOption.flag,
          style: const TextStyle(fontSize: 20),
        ),
        tooltip: AppLocalizations.of(context)?.selectLanguage ?? 'Language',
        onPressed: () => showLanguageSelectionSheet(context, ref),
      );
    }

    return ActionChip(
      avatar: Text(
        currentOption.flag,
        style: const TextStyle(fontSize: 16),
      ),
      label: Text(
        currentOption.name,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      onPressed: () => showLanguageSelectionSheet(context, ref),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}
