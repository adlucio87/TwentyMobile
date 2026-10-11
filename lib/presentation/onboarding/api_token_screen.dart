import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/data/connectors/twenty_connector.dart';
import 'package:pocketcrm/presentation/shared/clipboard_paste.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class ApiTokenScreen extends ConsumerStatefulWidget {
  const ApiTokenScreen({super.key});

  @override
  ConsumerState<ApiTokenScreen> createState() => _ApiTokenScreenState();
}

class _ApiTokenScreenState extends ConsumerState<ApiTokenScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _error;
  bool _isTesting = false;

  @override
  void initState() {
    super.initState();
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    final storage = ref.read(storageServiceProvider);
    final token = await storage.read(key: 'api_token');
    if (!mounted || token == null) return;
    setState(() {
      _controller.text = token;
    });
  }

  /// Pastes the system clipboard content into the token field.
  ///
  /// Only called from explicit user interactions (context menu entry and the
  /// suffix button), never as a side effect of building the selection toolbar.
  Future<void> _pasteFromClipboard() async {
    final l10n = context.l10n;
    final pasted = await pasteFromClipboard(
      context,
      _controller,
      successMessage: l10n.pastedFromClipboard,
      emptyMessage: l10n.clipboardEmpty,
    );
    if (!mounted || !pasted) return;
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.apiTokenTitle),
        actions: const [LanguageSelectorButton()],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(l10n.enterApiToken),
                          const SizedBox(height: 8),
                          Text(
                            l10n.whereFindToken,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _controller,
                            obscureText: true,
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
                            decoration: InputDecoration(
                              labelText: l10n.apiTokenTitle,
                              hintText: l10n.tokenHint,
                              prefixIcon: const Icon(Icons.key),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.paste_rounded),
                                tooltip: l10n.pasteFromClipboard,
                                onPressed: _pasteFromClipboard,
                              ),
                              errorText: _error,
                              errorMaxLines: 10,
                            ),
                            validator: (val) {
                              if (val == null || val.isEmpty) {
                                return l10n.tokenRequired;
                              }
                              return null;
                            },
                          ),
                          const Spacer(),
                          ElevatedButton(
                            onPressed: _isLoading ? null : _testConnection,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(l10n.connect),
                          ),
                          const SizedBox(height: 24),
                        ],
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

  Future<void> _testConnection() async {
    if (_isTesting) return;
    if (!_formKey.currentState!.validate()) return;

    _isTesting = true;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      final baseUrl = await storage.read(key: 'instance_url');
      if (baseUrl == null) throw Exception('Instance URL missing');

      final token = _controller.text.trim();

      await TwentyConnector.testConnection(baseUrl, token);

      final authService = ref.read(authServiceProvider);
      await authService.loginWithApiKey(baseUrl, token);

      // Salva il token e aggiorna authState → il router si occuperà del redirect
      await ref.read(authStateProvider.notifier).login(token);
      ref.invalidate(crmRepositoryProvider);
      ref.invalidate(authMethodProvider);
      ref.invalidate(currentUserNameProvider);

      if (mounted) context.go('/onboarding/notifications');
    } catch (e, stackTrace) {
      debugPrint('CONNECTION ERROR: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
      if (mounted) {
        String message = e.toString();
        if (message.startsWith('Exception: ')) {
          message = message.substring(11);
        }
        setState(() => _error = message);
      }
    } finally {
      _isTesting = false;
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
