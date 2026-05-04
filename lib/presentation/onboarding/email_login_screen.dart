import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/auth_state.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:pocketcrm/core/di/providers.dart';

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
    });

    try {
      final storage = ref.read(storageServiceProvider);
      final baseUrl = await storage.read(key: 'instance_url');
      if (baseUrl == null) throw Exception('Instance URL missing');

      final authService = ref.read(authServiceProvider);
      await authService.loginWithCredentials(
        baseUrl,
        _emailController.text.trim(),
        _passwordController.text,
      );

      final token = await storage.read(key: 'api_token');
      if (token != null) {
        await ref.read(authStateProvider.notifier).login(token);
      }

      // AuthState Provider and Router handle the navigation once the tokens are saved.
      // But we invalidate crmRepository to re-init
      ref.invalidate(crmRepositoryProvider);

      if (mounted) {
        context.go('/onboarding/notifications');
      }
    } catch (e, stackTrace) {
      debugPrint('LOGIN ERROR: $e');
      Sentry.captureException(e, stackTrace: stackTrace);
      if (mounted) {
        String message = e.toString();
        if (message.contains('UNAUTHENTICATED')) {
          message = 'Email o password non corretti. Riprova.';
        } else if (message.contains('Not Found') || message.contains('user not found')) {
          message = 'Nessun account trovato con questa email.';
        } else if (message.contains('SocketException') || message.contains('Failed host lookup')) {
          message = 'Impossibile raggiungere il server. Verifica l\'URL.';
        } else if (message.contains('password login is disabled')) {
           message = 'Il login con password non è abilitato su questa istanza Twenty.';
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
    return Scaffold(
      appBar: AppBar(title: const Text('Accedi con Email')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'Inserisci la tua email',
                  prefixIcon: Icon(Icons.email),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'L\'email è obbligatoria';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(val)) {
                    return 'Inserisci un\'email valida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Inserisci la tua password',
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
                  if (val == null || val.isEmpty) return 'La password è obbligatoria';
                  if (val.length < 6) return 'La password deve avere almeno 6 caratteri';
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
                  child: const Text('Hai dimenticato la password?'),
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Accedi'),
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
                child: const Text('Torna indietro'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
