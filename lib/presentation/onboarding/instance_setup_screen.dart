import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:pocketcrm/core/config/demo_config.dart';
import 'package:pocketcrm/core/localization/l10n_extension.dart';
import 'package:pocketcrm/data/connectors/twenty_connector.dart';
import 'package:pocketcrm/presentation/shared/snackbar_helper.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';

class InstanceSetupScreen extends ConsumerStatefulWidget {
  const InstanceSetupScreen({super.key});

  @override
  ConsumerState<InstanceSetupScreen> createState() =>
      _InstanceSetupScreenState();
}

class _InstanceSetupScreenState extends ConsumerState<InstanceSetupScreen> {
  final _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isDemoLoading = false;
  bool _isNextLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadStoredUrl();
  }

  Future<void> _trackServerConnection(
    String serverUrl, {
    required bool isDemo,
  }) async {
    // Temporarily disabled due to Glitchtip quota limits
    /*
    await Sentry.captureMessage(
      'app_connected',
      level: SentryLevel.info,
      withScope: (scope) {
        scope.setTag('server_type', isDemo ? 'demo' : 'own_server');
        scope.setContexts('connection', {
          'is_demo': isDemo,
          'platform': Theme.of(context).platform.name,
        });
      },
    );
    */
  }

  Future<void> _loadStoredUrl() async {
    final storage = ref.read(storageServiceProvider);
    final url = await storage.read(key: 'instance_url');
    if (url != null) {
      setState(() {
        _controller.text = url;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.configureCrm),
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
                OutlinedButton.icon(
                onPressed: _isDemoLoading ? null : _connectDemo,
                icon: _isDemoLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(l10n.tryDemo),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.demoSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      l10n.orDivider,
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),
              Text(l10n.instanceUrlQuestion),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                autofillHints: const [AutofillHints.url],
                decoration: InputDecoration(
                  labelText: l10n.instanceUrl,
                  hintText: l10n.instanceUrlHint,
                  prefixIcon: const Icon(Icons.link),
                ),
                onChanged: (_) {
                  if (_error != null) {
                    setState(() => _error = null);
                  }
                },
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return l10n.enterValidUrl;
                  }
                  var trimmed = val.trim();
                  if (!trimmed.startsWith('http://') && !trimmed.startsWith('https://')) {
                    trimmed = 'https://$trimmed';
                  }
                  final uri = Uri.tryParse(trimmed);
                  if (uri == null || !uri.hasAuthority || uri.host.isEmpty) {
                    return l10n.enterValidUrl;
                  }
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const Spacer(),
              ElevatedButton(
                onPressed: (_isNextLoading || _isDemoLoading) ? null : _submitUrl,
                child: _isNextLoading
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
                          const SizedBox(width: 12),
                          Text(
                            l10n.verifyingServer,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      )
                    : Text(l10n.next),
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

  Future<void> _submitUrl() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isNextLoading = true;
      _error = null;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      final rawUrl = _controller.text.trim();
      final validatedUrl = await TwentyConnector.validateInstance(rawUrl);

      _controller.text = validatedUrl;

      await storage.write(
        key: 'instance_url',
        value: validatedUrl,
      );
      await storage.delete(key: 'is_demo_mode');
      if (mounted) {
        context.push('/onboarding/method');
        await _trackServerConnection(
          validatedUrl,
          isDemo: false,
        );
      }
    } on InstanceValidationException catch (e) {
      if (mounted) {
        final l10n = context.l10n;
        final String message;
        switch (e.error) {
          case InstanceValidationError.unreachable:
            message = l10n.unableToReachServer;
            break;
          case InstanceValidationError.notTwentyInstance:
            message = l10n.invalidTwentyInstance;
            break;
          case InstanceValidationError.invalidUrl:
            message = l10n.enterValidUrl;
            break;
        }
        setState(() => _error = message);
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = context.l10n.unableToReachServer,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isNextLoading = false);
      }
    }
  }

  Future<void> _connectDemo() async {
    setState(() {
      _isDemoLoading = true;
      _error = null;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      await storage.write(key: 'instance_url', value: DemoConfig.instanceUrl);
      await storage.write(key: 'api_token', value: DemoConfig.apiToken);

      await ref
          .read(authStateProvider.notifier)
          .login(DemoConfig.apiToken, isDemo: true);
      ref.invalidate(crmRepositoryProvider);

      // Attempt connection implicitly, by navigating and letting app structure resolve.
      // But we should test it first to show error if it fails
      try {
        final repo = await ref.read(crmRepositoryProvider.future);
        await repo.getCurrentUserName(); // A simple check
        if (mounted) {
          context.go('/home');
          await _trackServerConnection(DemoConfig.instanceUrl, isDemo: true);
        }
      } catch (e) {
        // Test failed
        await storage.delete(key: 'instance_url');
        await storage.delete(key: 'api_token');
        await storage.delete(key: 'is_demo_mode');
        if (mounted) {
          SnackbarHelper.showError(
            context,
            context.l10n.demoUnavailable,
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isDemoLoading = false);
      }
    }
  }
}
