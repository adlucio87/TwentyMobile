import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/auth/two_factor_exception.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/presentation/onboarding/otp_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isLoading = false;
  String? _error;
  String? _loadingMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _loadingMessage = null;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      final baseUrl = await storage.read(key: 'instance_url');
      if (baseUrl == null) throw Exception('Instance URL missing');

      // Step 1: Check if captcha is required on this instance
      String? captchaToken;
      final captchaService = ref.read(captchaServiceProvider);
      final captchaConfig = await captchaService.fetchCaptchaConfig(baseUrl);

      if (captchaConfig != null) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          setState(() => _loadingMessage = l10n?.securityCheck ?? 'Security check...');
        }
        captchaToken = await captchaService.generateCaptchaToken(captchaConfig);
        debugPrint('Captcha token obtained successfully');
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        setState(() => _loadingMessage = l10n?.loggingIn ?? 'Logging in...');
      }

      // Step 2: Login with credentials (and captcha token if required)
      final authService = ref.read(authServiceProvider);
      await authService.loginWithCredentials(
        baseUrl,
        _emailController.text.trim(),
        _passwordController.text,
        captchaToken: captchaToken,
      );

      final token = await storage.read(key: 'api_token');
      if (token != null) {
        await ref.read(authStateProvider.notifier).login(token);
      }

      // AuthState Provider and Router handle the navigation once the tokens are saved.
      // But we invalidate crmRepository to re-init
      ref.invalidate(crmRepositoryProvider);
      ref.invalidate(authMethodProvider);
      ref.invalidate(currentUserNameProvider);

      if (mounted) {
        context.go('/onboarding/notifications');
      }
    } on TwoFactorRequiredException catch (e) {
      // 2FA required — navigate to OTP screen with the loginToken
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OtpScreen(
              instanceUrl: e.instanceUrl,
              loginToken: e.loginToken,
            ),
          ),
        );
      }
      return; // Don't show error
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        String message = e.toString();
        if (message.contains('UNAUTHENTICATED')) {
          message = l10n?.incorrectCredentials ?? 'Incorrect email or password. Please try again.';
        } else if (message.contains('Not Found') || message.contains('user not found')) {
          message = l10n?.noAccountFound ?? 'No account found with this email.';
        } else if (message.contains('SocketException') || message.contains('Failed host lookup')) {
          message = l10n?.unableToReachServer ?? 'Unable to reach the server. Check the URL.';
        } else if (message.contains('password login is disabled')) {
          message = l10n?.passwordLoginDisabled ?? 'Password login is not enabled on this Twenty instance.';
        } else if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        setState(() => _error = message);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openForgotPassword() async {
    final storage = ref.read(storageServiceProvider);
    final baseUrl = await storage.read(key: 'instance_url');
    if (baseUrl != null) {
      final url = Uri.parse('$baseUrl/forgot-password');
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.loginWithEmailTitle ?? 'Login with Email'),
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: l10n?.email ?? 'Email',
                          hintText: l10n?.emailHint ?? 'Enter your email',
                          prefixIcon: const Icon(Icons.email),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return l10n?.emailRequired ?? 'Email is required';
                          }
                          if (!val.contains('@') || !val.contains('.')) {
                            return l10n?.enterValidEmail ?? 'Enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscureText,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: l10n?.password ?? 'Password',
                          hintText: l10n?.passwordHint ?? 'Enter your password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return l10n?.passwordRequired ?? 'Password is required';
                          }
                          if (val.length < 6) {
                            return l10n?.passwordMinLength ?? 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Theme.of(context).colorScheme.error),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _openForgotPassword,
                          child: Text(l10n?.forgotPassword ?? 'Forgot password?'),
                        ),
                      ),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (_loadingMessage != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        _loadingMessage!,
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  ],
                                 )
                              : Text(l10n?.loginButton ?? 'Login'),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/onboarding/method');
                          }
                        },
                        child: Text(l10n?.goBack ?? 'Go back'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                        ),
                      ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
