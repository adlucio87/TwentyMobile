import 'package:flutter/widgets.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

/// Non-nullable access to [AppLocalizations] from a [BuildContext].
///
/// The localization delegate is always installed by `MaterialApp`
/// (see `lib/main.dart`), so a missing instance means the widget is rendered
/// outside of a localized app. Failing loudly is preferable to silently
/// falling back to hardcoded English strings, which would hide missing
/// translations.
extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n {
    final localizations = AppLocalizations.of(this);
    assert(
      localizations != null,
      'AppLocalizations not found in the widget tree. '
      'Did you forget AppLocalizations.localizationsDelegates?',
    );
    return localizations!;
  }
}
