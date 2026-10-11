import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/core/localization/locale_provider.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

/// Label shown for [option] in the picker.
///
/// Language names stay in their own language (recommended UX), while the
/// "system default" entry is localized with [AppLocalizations.languageSystem].
String localeOptionLabel(AppLocalizations l10n, AppLocaleOption option) {
  return option.locale == null ? l10n.languageSystem : option.name;
}

/// Opens the language picker bottom sheet.
Future<void> showLanguageSelectionSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  final currentOption = ref.read(selectedLocaleOptionProvider);

  await showModalBottomSheet<void>(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (modalContext) {
      final l10n = modalContext.l10n;
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                l10n.selectLanguage,
                style: Theme.of(
                  modalContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    title: Text(localeOptionLabel(l10n, option)),
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
}

/// Compact (icon only) or extended (chip with label) language switcher.
///
/// The extended variant is meant to live inside a [Flexible]: it shrinks and
/// ellipsizes its label instead of overflowing the parent row.
class LanguageSelectorButton extends ConsumerWidget {
  final bool isCompact;

  const LanguageSelectorButton({super.key, this.isCompact = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final currentOption = ref.watch(selectedLocaleOptionProvider);

    if (isCompact) {
      return IconButton(
        icon: Text(currentOption.flag, style: const TextStyle(fontSize: 20)),
        tooltip: l10n.language,
        onPressed: () => showLanguageSelectionSheet(context, ref),
      );
    }

    return ActionChip(
      avatar: Text(currentOption.flag, style: const TextStyle(fontSize: 16)),
      label: Text(
        localeOptionLabel(l10n, currentOption),
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      onPressed: () => showLanguageSelectionSheet(context, ref),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
