import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/presentation/home/today_provider.dart';

/// Monitors app lifecycle events and automatically refreshes
/// authentication tokens when the app resumes from background.
class AppLifecycleHandler with WidgetsBindingObserver {
  final WidgetRef _ref;
  bool _isRefreshing = false;

  AppLifecycleHandler(this._ref);

  void register() {
    WidgetsBinding.instance.addObserver(this);
  }

  void unregister() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    if (_isRefreshing) return;

    // Only act if the user is currently authenticated
    final authState = _ref.read(authStateProvider);
    if (!authState.hasValue || authState.value != true) return;

    final storage = _ref.read(storageServiceProvider);
    final method = await storage.read(key: 'auth_method');

    // API key auth doesn't expire
    if (method != 'email') return;

    final authService = _ref.read(authServiceProvider);

    if (!await authService.isTokenExpired()) return;

    _isRefreshing = true;
    try {
      print('[AppLifecycleHandler] Token expired, attempting refresh...');
      final refreshed = await authService.refreshAccessToken();

      if (refreshed) {
        print('[AppLifecycleHandler] Token refreshed successfully, reloading data...');
        
        // CRITICAL: AuthService writes new tokens directly to FlutterSecureStorage,
        // but StorageService has its own in-memory cache with the OLD token.
        // We MUST clear that cache before any provider reads the token.
        final storage = _ref.read(storageServiceProvider);
        storage.invalidateCache(keys: [
          'api_token',
          'refresh_token',
          'token_expires_at',
        ]);
        
        // Invalidate all data providers so they refetch with the new token
        _ref.invalidate(crmRepositoryProvider);
        _ref.invalidate(contactsProvider);
        _ref.invalidate(companiesProvider);
        _ref.invalidate(tasksProvider);
        _ref.invalidate(todayNotifierProvider);
        _ref.invalidate(workspaceMembersProvider);
      } else {
        print('[AppLifecycleHandler] Token refresh failed, forcing re-authentication...');
        // Check if 2FA is pending — the router will handle the redirect
        final pending2fa = await storage.read(key: 'pending_2fa_login_token');
        if (pending2fa != null) {
          // AuthState stays true but router redirect will catch the pending 2FA
          // and redirect to OTP screen
          _ref.invalidate(authStateProvider);
        } else {
          // Full logout — force AuthState to false so router redirects to login
          _ref.read(authStateProvider.notifier).logout();
        }
      }
    } catch (e) {
      print('[AppLifecycleHandler] Error during token refresh: $e');
      // On unexpected errors, force re-authentication
      _ref.read(authStateProvider.notifier).logout();
    } finally {
      _isRefreshing = false;
    }
  }
}
