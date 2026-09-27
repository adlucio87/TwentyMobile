import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pocketcrm/core/router/router.dart';
import 'package:pocketcrm/core/theme/app_theme.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:pocketcrm/core/notifications/notification_service.dart';
import 'package:pocketcrm/core/auth/app_lifecycle_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/theme/theme_provider.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:pocketcrm/core/config/app_config.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/core/localization/locale_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Previene eccezioni non gestite quando il dispositivo è offline:
  // i font cadranno sul fallback di sistema invece di crashare.
  GoogleFonts.config.allowRuntimeFetching = false;

  Future<void> startApp() async {
    try {
      await NotificationService().initialize();

      final appDocDir = await getApplicationSupportDirectory();
      if (kDebugMode) debugPrint('Hive storage path: ${appDocDir.path}');
      Hive.init(appDocDir.path);

      final box = await Hive.openBox<String>('app_storage');
      if (kDebugMode) {
        debugPrint('Hive box keys at startup: ${box.keys.toList()}');
      }

      await Future.wait([
        initializeDateFormatting('en', null),
        initializeDateFormatting('it', null),
        initializeDateFormatting('fr', null),
        initializeDateFormatting('de', null),
        initializeDateFormatting('hi', null),
      ]);

      runApp(
        ProviderScope(
          overrides: [hiveStorageBoxProvider.overrideWithValue(box)],
          child: const PocketCRMApp(),
        ),
      );
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Fatal error during initialization: $e');
        debugPrint(stack.toString());
      }
      // In case of error, still try to run the app to show an error or the UI
      runApp(
        ProviderScope(
          overrides: [], // No box available
          child: const PocketCRMApp(),
        ),
      );
    } finally {
      // Rimuoviamo lo splash screen una volta che l'app è pronta o è fallita
      FlutterNativeSplash.remove();
    }
  }

  // Error reporting is off in debug builds, in builds made with
  // --dart-define=ERROR_REPORTING=false, and when the user turned it off in
  // Settings. Without init, Sentry.capture* calls elsewhere are no-ops.
  final prefs = await SharedPreferences.getInstance();
  final errorReporting = !kDebugMode &&
      AppConfig.errorReportingBuildEnabled &&
      (prefs.getBool(AppConfig.errorReportingPrefKey) ?? true);
  if (!errorReporting) {
    await startApp();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = AppConfig.glitchtipDsn;
      options.tracesSampleRate = 1.0;
      options.debug = false;
      // Filter out non-fatal network errors that spam GlitchTip
      options.beforeSend = (event, hint) {
        final exceptions = event.exceptions;
        if (exceptions != null && exceptions.isNotEmpty) {
          final errorValue = exceptions.first.value ?? '';
          // Drop font-loading errors entirely (offline noise)
          if (errorValue.contains('Failed to load font with url') ||
              errorValue.contains('fonts.gstatic.com')) {
            return null; // Ignore and drop this event
          }
          // Downgrade transient network errors from Fatal to Warning
          if (errorValue.contains('TimeoutException') ||
              errorValue.contains('SocketException') ||
              errorValue.contains('Connection closed') ||
              errorValue.contains('Network unreachable')) {
            event.level = SentryLevel.warning;
            return event;
          }
        }
        return event;
      };
    },
    appRunner: startApp,
  );
}

class PocketCRMApp extends ConsumerStatefulWidget {
  const PocketCRMApp({super.key});

  @override
  ConsumerState<PocketCRMApp> createState() => _PocketCRMAppState();
}

class _PocketCRMAppState extends ConsumerState<PocketCRMApp> {
  AppLifecycleHandler? _lifecycleHandler;

  @override
  void initState() {
    super.initState();
    // Defer lifecycle handler registration to after the first frame,
    // so that all providers are available.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _lifecycleHandler = AppLifecycleHandler(ref);
      _lifecycleHandler!.register();
    });
  }

  @override
  void dispose() {
    _lifecycleHandler?.unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pendingRoute = initialNotificationRoute;
      if (pendingRoute != null) {
        clearInitialNotificationRoute();
        Future.delayed(const Duration(milliseconds: 500), () {
          if (navigatorKey.currentContext != null) {
            navigatorKey.currentContext!.go(pendingRoute);
          }
        });
      }
    });

    return MaterialApp.router(
      title: 'TwentyMobile',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
