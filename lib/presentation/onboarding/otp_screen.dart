import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// OTP verification screen for Two-Factor Authentication.
/// Receives [instanceUrl] and [loginToken] from the first auth step.
/// Email/password are NOT stored — only the loginToken is kept in memory.
class OtpScreen extends ConsumerStatefulWidget {
  final String instanceUrl;
  final String loginToken;

  const OtpScreen({
    super.key,
    required this.instanceUrl,
    required this.loginToken,
  });

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  bool _hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(_onOtpChanged);
  }

  @override
  void dispose() {
    _otpController.removeListener(_onOtpChanged);
    _otpController.dispose();
    super.dispose();
  }

  void _onOtpChanged() {
    // Clear error when user starts typing again
    if (_error != null) {
      setState(() => _error = null);
    }

    // Auto-submit when 6 digits are entered
    if (_otpController.text.length == 6 && !_hasSubmitted && !_isLoading) {
      _verifyOtp();
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _hasSubmitted = true;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.loginWithOTP(
        instanceUrl: widget.instanceUrl,
        loginToken: widget.loginToken,
        otp: otp,
      );

      final storage = ref.read(storageServiceProvider);
      final token = await storage.read(key: 'api_token');
      if (token != null) {
        await ref.read(authStateProvider.notifier).login(token);
      }

      ref.invalidate(crmRepositoryProvider);
      ref.invalidate(authMethodProvider);
      ref.invalidate(currentUserNameProvider);

      if (mounted) {
        context.go('/onboarding/notifications');
      }
    } catch (e, stackTrace) {
      debugPrint('OTP ERROR: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
      if (mounted) {
        HapticFeedback.heavyImpact();
        _otpController.clear();
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        setState(() {
          _error = message;
          _isLoading = false;
          _hasSubmitted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isReady = _otpController.text.length == 6;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Two-Factor Authentication'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 48),

                        // Shield icon
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer.withAlpha(80),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.shield_outlined,
                            size: 40,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Title
                        Text(
                          'Enter your verification code',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          'Open your authenticator app and enter the 6-digit code',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // OTP Input
                        SizedBox(
                          width: 240,
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            enabled: !_isLoading,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 16,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '', // hide "0/6"
                              hintText: '------',
                              hintStyle: TextStyle(
                                fontSize: 32,
                                letterSpacing: 16,
                                color: theme.colorScheme.outline.withAlpha(100),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: _error != null
                                      ? theme.colorScheme.error
                                      : theme.colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: theme.colorScheme.error,
                                  width: 2,
                                ),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 16,
                              ),
                            ),
                          ),
                        ),

                        // Error message
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: theme.colorScheme.error,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _error!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 32),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isReady && !_isLoading) ? _verifyOtp : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Verify'),
                          ),
                        ),

                        const Spacer(),

                        // Help text
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Text(
                            "Can't find the code? Check your authenticator app (e.g. Google Authenticator, Authy).",
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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
