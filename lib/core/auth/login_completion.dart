import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/di/providers.dart';

/// Persists the freshly issued session, drops the cached providers and moves the
/// user to the notification-permissions step.
///
/// Every login entry point (email/password, API token, OTP, embedded WebView,
/// OAuth PKCE) funnels through here: the sequence used to be copy-pasted in five
/// screens and had already drifted apart.
///
/// [accessToken] is only needed by callers that hold a token not (yet) stored,
/// such as the WebView cookie flow.
Future<void> completeSignIn(
  WidgetRef ref,
  BuildContext context, {
  String? accessToken,
}) async {
  final token =
      accessToken ?? await ref.read(storageServiceProvider).read(key: 'api_token');

  if (token == null || token.isEmpty) {
    throw Exception('Session token missing after sign-in');
  }

  await ref.read(authStateProvider.notifier).login(token);

  ref.invalidate(crmRepositoryProvider);
  ref.invalidate(authMethodProvider);
  ref.invalidate(currentUserNameProvider);

  if (context.mounted) {
    context.go('/onboarding/notifications');
  }
}
