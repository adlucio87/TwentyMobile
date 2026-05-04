import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pocketcrm/presentation/onboarding/welcome_screen.dart';
import 'package:pocketcrm/presentation/onboarding/instance_setup_screen.dart';
import 'package:pocketcrm/presentation/onboarding/api_token_screen.dart';
import 'package:pocketcrm/presentation/contacts/contacts_screen.dart';
import 'package:pocketcrm/presentation/contact_detail/contact_detail_screen.dart';
import 'package:pocketcrm/presentation/companies/companies_screen.dart';
import 'package:pocketcrm/presentation/companies/company_detail_screen.dart';
import 'package:pocketcrm/presentation/tasks/tasks_screen.dart';
import 'package:pocketcrm/presentation/settings/settings_screen.dart';
import 'package:pocketcrm/presentation/home/today_screen.dart';
import 'package:pocketcrm/shared/main_shell.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/di/providers.dart';

import 'package:pocketcrm/presentation/onboarding/notification_permission_screen.dart';
import 'package:pocketcrm/presentation/onboarding/auth_method_screen.dart';
import 'package:pocketcrm/presentation/onboarding/email_login_screen.dart';

part 'router.g.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

late GoRouter appRouterInstance;

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authNotifier = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) {
    authNotifier.value++;
  });
  ref.onDispose(authNotifier.dispose);

  appRouterInstance = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: '/',
    refreshListenable: authNotifier,
    redirect: (context, state) async {
      final authState = ref.read(authStateProvider);

      if (authState.isLoading && !authState.hasValue) {
        return '/';
      }

      if (authState.hasError || authState.value == null) {
        return null;
      }

      final hasToken = authState.value!;
      final isOnboarding =
          state.matchedLocation.startsWith('/onboarding') ||
          state.matchedLocation == '/';

      if (!hasToken && !isOnboarding) {
        return '/onboarding';
      }

      if (!hasToken && state.matchedLocation == '/') {
        return '/onboarding';
      }

      if (hasToken && isOnboarding && state.matchedLocation != "/onboarding/notifications") {
        return "/home";
      }

      // Automatically refresh token if expired before going to any page (except onboarding)
      if (hasToken && !isOnboarding) {
        final authService = ref.read(authServiceProvider);
        final storage = ref.read(storageServiceProvider);
        final method = await storage.read(key: 'auth_method');
        if (method == 'email') {
          if (await authService.isTokenExpired()) {
            final refreshed = await authService.refreshAccessToken();
            if (!refreshed) {
              return '/onboarding';
            }
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/onboarding/instance',
        builder: (context, state) => const InstanceSetupScreen(),
      ),
      GoRoute(
        path: '/onboarding/method',
        builder: (context, state) => const AuthMethodScreen(),
      ),
      GoRoute(
        path: '/onboarding/email',
        builder: (context, state) => const EmailLoginScreen(),
      ),
      GoRoute(
        path: '/onboarding/token',
        builder: (context, state) => const ApiTokenScreen(),
      ),
      GoRoute(
        path: '/onboarding/notifications',
        builder: (context, state) => const NotificationPermissionScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsScreen(),
          ),
          GoRoute(
            path: '/contacts/:id',
            builder: (context, state) =>
                ContactDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/companies',
            builder: (context, state) => const CompaniesScreen(),
          ),
          GoRoute(
            path: '/companies/:id',
            builder: (context, state) =>
                CompanyDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/tasks',
            builder: (context, state) => const TasksScreen(),
            routes: [
              GoRoute(
                path: ":id",
                builder: (context, state) => const TasksScreen(),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
  return appRouterInstance;
}
