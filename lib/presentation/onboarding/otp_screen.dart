import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/auth/login_completion.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/core/utils/error_utils.dart';
import 'package:pocketcrm/presentation/shared/clipboard_paste.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// OTP verification screen for Two-Factor Authentication.
/// Receives [instanceUrl] and [loginToken] from the first auth step.
/// Email/password are NOT stored — only the loginToken is kept in memory.
class OtpScreen extends ConsumerStatefulWidget {
  final String instanceUrl;
  final String loginToken;

  /// Auth method that started the flow (`email` or `sso`). Carried through so
  /// the completed session keeps the correct label.
  final String authMethod;

  const OtpScreen({
    super.key,
    required this.instanceUrl,
    required this.loginToken,
    this.authMethod = 'email',
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

  /// Pastes the verification code from the system clipboard.
  ///
  /// Only called from explicit user interactions (context menu entry and the
  /// "Paste from clipboard" button), so that no clipboard read happens as a
  /// side effect of building the text selection toolbar.
  Future<void> _pasteFromClipboard() async {
    final l10n = context.l10n;
    await pasteFromClipboard(
      context,
      _otpController,
      successMessage: l10n.codePasted,
      emptyMessage: l10n.clipboardEmpty,
      otpMode: true,
    );
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
        authMethod: widget.authMethod,
      );

      if (!mounted) return;
      await completeSignIn(ref, context);
    } catch (e, stackTrace) {
      debugPrint('OTP ERROR: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
      if (mounted) {
        HapticFeedback.heavyImpact();
        _otpController.clear();
        setState(() {
          _error = userFacingError(e);
          _isLoading = false;
          _hasSubmitted = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final isReady = _otpController.text.length == 6;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.twoFactorTitle),
        actions: const [LanguageSelectorButton()],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(authServiceProvider).clearPending2FA();
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/onboarding/method');
            }
          },
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                            color: theme.colorScheme.primaryContainer.withAlpha(
                              80,
                            ),
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
                          l10n.enterVerificationCode,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),

                        // Subtitle
                        Text(
                          l10n.openAuthenticatorApp,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),

                        // OTP input. A long press opens the platform context
                        // menu whose paste entry sanitizes the code from the
                        // clipboard (digits only, at most 6).
                        SizedBox(
                          width: 240,
                          child: TextField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            autofocus: true,
                            textAlign: TextAlign.center,
                            enabled: !_isLoading,
                            contextMenuBuilder: (context, editableTextState) {
                              return AdaptiveTextSelectionToolbar.buttonItems(
                                anchors: editableTextState.contextMenuAnchors,
                                buttonItems: pasteContextMenuButtonItems(
                                  editableTextState,
                                  pasteLabel: context.l10n.paste,
                                  onPaste: _pasteFromClipboard,
                                ),
                              );
                            },
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

                        const SizedBox(height: 12),

                        // Quick paste button
                        TextButton.icon(
                          onPressed: _isLoading ? null : _pasteFromClipboard,
                          icon: const Icon(Icons.paste_rounded, size: 18),
                          label: Text(l10n.pasteFromClipboard),
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

                        const SizedBox(height: 24),

                        // Verify button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: (isReady && !_isLoading)
                                ? _verifyOtp
                                : null,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.verify),
                          ),
                        ),

                        const Spacer(),

                        // Help text
                        Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Text(
                            l10n.cantFindCode,
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
