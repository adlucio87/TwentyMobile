import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketcrm/core/auth/login_completion.dart';
import 'package:pocketcrm/core/auth/oauth_pkce_service.dart';
import 'package:pocketcrm/core/auth/oauth_token_client.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/core/utils/error_utils.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';

class OAuthLoginScreen extends ConsumerStatefulWidget {
  const OAuthLoginScreen({super.key});

  @override
  ConsumerState<OAuthLoginScreen> createState() => _OAuthLoginScreenState();
}

class _OAuthLoginScreenState extends ConsumerState<OAuthLoginScreen> {
  final _clientIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _instanceUrl;
  String? _effectiveRedirectUri;
  OAuthServerMetadata? _metadata;
  bool _isLoadingInstance = true;
  bool _isCheckingConfiguration = false;
  bool _isAuthenticating = false;
  bool _showManualClientNotice = false;

  /// True while the field holds a client id served by the team registry (and
  /// not typed by the user): only those are marked as rejected on failure.
  bool _usingSharedClientId = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initFlow();
  }

  @override
  void dispose() {
    _clientIdController.dispose();
    super.dispose();
  }

  Future<void> _initFlow() async {
    try {
      final storage = ref.read(storageServiceProvider);
      final oauthService = ref.read(oauthPkceServiceProvider);

      final url = (await storage.read(key: 'instance_url'))?.trim();
      if (url == null || url.isEmpty) {
        if (!mounted) return;
        setState(() {
          _isLoadingInstance = false;
          _error = context.l10n.unableToReachServer;
        });
        return;
      }

      final savedClientId = await oauthService.getSavedClientId(url);

      // Show the screen as soon as the local credentials are known: the
      // registry lookup and the discovery document are network calls, and the
      // user must not stare at a spinner for their combined timeout.
      if (!mounted) return;
      setState(() {
        _instanceUrl = url;
        _isLoadingInstance = false;
        _isCheckingConfiguration = true;
        if (savedClientId != null && savedClientId.isNotEmpty) {
          _clientIdController.text = savedClientId;
        }
      });

      final needsSharedClientId = savedClientId == null || savedClientId.isEmpty;

      // Started together, awaited one after the other: concurrent, not sequential.
      final metadataFuture = oauthService.fetchServerMetadata(url);
      final sharedClientIdFuture = needsSharedClientId
          ? _lookupSharedClientId(oauthService, url)
          : Future<String?>.value(null);

      final metadata = await metadataFuture;
      final sharedClientId = await sharedClientIdFuture;

      var effectiveClientId = savedClientId;
      if (needsSharedClientId &&
          sharedClientId != null &&
          sharedClientId.isNotEmpty) {
        effectiveClientId = sharedClientId;
        _usingSharedClientId = true;
        await oauthService.saveClientCredentials(url, clientId: sharedClientId);
      }

      // A failure only means "unknown": the screen still works with a manually
      // pasted Client ID.
      final mode = await oauthService.resolveRedirectMode(
        url,
        metadata: metadata,
      );
      final redirectUri = await oauthService.effectiveRedirectUri(
        url,
        mode: mode,
      );

      if (!mounted) return;
      setState(() {
        _metadata = metadata;
        _effectiveRedirectUri = redirectUri;
        _isCheckingConfiguration = false;
        if (effectiveClientId != null && effectiveClientId.isNotEmpty) {
          _clientIdController.text = effectiveClientId;
        }
        _showManualClientNotice =
            (effectiveClientId == null || effectiveClientId.isEmpty) &&
                metadata?.supportsDynamicRegistration != true;
      });

      // Only worth trying when the instance advertises dynamic registration.
      if ((effectiveClientId == null || effectiveClientId.isEmpty) &&
          metadata?.supportsDynamicRegistration == true) {
        await _attemptAutoRegistration(url);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingInstance = false;
        _isCheckingConfiguration = false;
        _error = userFacingError(e);
      });
    }
  }

  /// Reads the team-shared client id, ignoring one the instance already refused.
  ///
  /// Without that filter a registry entry whose application was deleted (or
  /// that belongs to another instance) would be re-offered on every attempt.
  Future<String?> _lookupSharedClientId(
    OAuthPkceService oauthService,
    String url,
  ) async {
    final sharedClientId = await oauthService.fetchSharedClientId(url);
    if (sharedClientId == null || sharedClientId.isEmpty) return null;

    final rejected = await oauthService.rejectedSharedClientId(url);
    if (rejected != null && rejected == sharedClientId) {
      debugPrint(
        'Ignoring shared OAuth client id previously rejected by $url',
      );
      return null;
    }
    return sharedClientId;
  }

  /// Registers a client when the instance advertises dynamic registration.
  ///
  /// The browser is deliberately *not* opened here: an
  /// `ASWebAuthenticationSession` without a user gesture is fragile on iOS and
  /// the user would have no idea why a browser appeared. They tap
  /// "Sign in with Browser" when they are ready.
  Future<void> _attemptAutoRegistration(String url) async {
    if (!mounted) return;
    setState(() => _isCheckingConfiguration = true);

    try {
      final oauthService = ref.read(oauthPkceServiceProvider);
      final registered = await oauthService.tryAutoRegisterClient(url);

      if (registered == null) return;

      await oauthService.saveClientCredentials(
        url,
        clientId: registered.clientId,
        clientSecret: registered.clientSecret,
      );

      // Publish to the shared registry so team members connecting to the same
      // instance can reuse this application instead of creating their own.
      unawaited(
        oauthService.publishSharedClientId(url, registered.clientId),
      );

      if (!mounted) return;
      setState(() {
        _clientIdController.text = registered.clientId;
        _showManualClientNotice = false;
        _usingSharedClientId = false;
      });
    } catch (_) {
      // Best effort: the user can still paste a Client ID manually.
    } finally {
      if (mounted) {
        setState(() => _isCheckingConfiguration = false);
      }
    }
  }

  Future<void> _startOAuthFlow() async {
    final clientId = _clientIdController.text.trim();
    if (clientId.isEmpty) {
      // Surface the validator message instead of sending an empty client_id.
      _formKey.currentState?.validate();
      return;
    }

    final instanceUrl = _instanceUrl;
    if (instanceUrl == null) return;

    setState(() {
      _isAuthenticating = true;
      _error = null;
    });

    try {
      final oauthService = ref.read(oauthPkceServiceProvider);
      final clientSecret = await oauthService.getSavedClientSecret(instanceUrl);

      await oauthService.loginWithOAuth(
        instanceUrl: instanceUrl,
        clientId: clientId,
        clientSecret: clientSecret,
      );

      if (!mounted) return;
      await completeSignIn(ref, context);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isAuthenticating = false;
        if (!isUserCancellation(e)) {
          _error = userFacingError(e);
          _forgetRejectedClientCredentials(instanceUrl, e);
        }
      });
    }
  }

  /// Drops stored credentials the server just refused.
  ///
  /// Only a real client rejection counts (the application was deleted on
  /// Twenty, or the id belongs to another instance): matching on any message
  /// containing "client" used to wipe credentials for unrelated failures.
  void _forgetRejectedClientCredentials(String instanceUrl, Object error) {
    if (error is! OAuthException || !isClientRejection(error)) return;

    final oauthService = ref.read(oauthPkceServiceProvider);
    final rejectedClientId = _clientIdController.text.trim();

    unawaited(oauthService.clearSavedClient(instanceUrl));

    // A registry-served id must not be offered again on the next attempt.
    if (_usingSharedClientId && rejectedClientId.isNotEmpty) {
      unawaited(
        oauthService.markSharedClientIdRejected(instanceUrl, rejectedClientId),
      );
      _usingSharedClientId = false;
    }
  }

  Future<void> _pasteClientId() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _clientIdController.text = text;
        // Pasted by hand: it is not a registry entry any more.
        _usingSharedClientId = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.pastedFromClipboard),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.clipboardEmpty),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyRedirectUri() async {
    await Clipboard.setData(
      ClipboardData(
        text: _effectiveRedirectUri ?? OAuthPkceService.defaultRedirectUri,
      ),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.copiedToClipboard),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final appVersion = _metadata?.appVersion;
    final instanceVersion =
        (appVersion != null && appVersion.isNotEmpty) ? appVersion : null;

    if (_isLoadingInstance) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.webAuthTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.webAuthTitle),
        actions: const [
          LanguageSelectorButton(),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                l10n.loginWithGoogleSso,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.loginWithGoogleSsoDesc,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),

              // Server indicator
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    Icon(Icons.dns, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _instanceUrl ?? '',
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis,
                          ),
                          // Read from /client-config: explains which version is
                          // answering, and why the Client ID cannot always be
                          // filled in automatically.
                          if (instanceVersion != null)
                            Text(
                              'Twenty $instanceVersion',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              if (_isCheckingConfiguration) ...[
                Card(
                  elevation: 0,
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            l10n.checkingConfiguration,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: theme.colorScheme.onErrorContainer),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // A missing `registration_endpoint` (all self-hosted Twenty so far)
              // is the reason the Client ID cannot be filled in automatically.
              if (_showManualClientNotice) ...[
                Container(
                  key: const Key('oauth_manual_client_notice'),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.oauthNoAutoRegistrationNotice,
                          style: TextStyle(
                            color: theme.colorScheme.onSecondaryContainer,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Client ID form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.oauthClientIdTitle,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.oauthClientIdSubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Redirect URI helper
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.redirectUriLabel,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _effectiveRedirectUri ??
                                      OAuthPkceService.defaultRedirectUri,
                                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            tooltip: l10n.copiedToClipboard,
                            onPressed: _copyRedirectUri,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      key: const Key('oauth_client_id_field'),
                      controller: _clientIdController,
                      decoration: InputDecoration(
                        labelText: l10n.oauthClientIdTitle,
                        hintText: l10n.oauthClientIdHint,
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.content_paste),
                          tooltip: l10n.paste,
                          onPressed: _pasteClientId,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.oauthClientIdRequired;
                        }
                        return null;
                      },
                      onChanged: (_) => _usingSharedClientId = false,
                    ),

                    const SizedBox(height: 24),

                    // Primary Button: Open Browser
                    FilledButton.icon(
                      key: const Key('oauth_launch_browser_button'),
                      onPressed: _isAuthenticating ? null : () => _startOAuthFlow(),
                      icon: _isAuthenticating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.open_in_browser),
                      label: Text(
                        _isAuthenticating ? l10n.completingSignIn : l10n.openInBrowser,
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
