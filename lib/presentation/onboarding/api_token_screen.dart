import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/core/di/providers.dart';
import 'package:pocketcrm/core/di/auth_state.dart';

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

  @override
  void initState() {
    super.initState();
    _loadStoredToken();
  }

  Future<void> _loadStoredToken() async {
    final storage = ref.read(storageServiceProvider);
    final token = await storage.read(key: 'api_token');
    if (token != null) {
      setState(() {
        _controller.text = token;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('API Token')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Scrivi il tuo API Token di Twenty CRM.'),
              const SizedBox(height: 8),
              const Text(
                'Dove trovo il token? Twenty → Settings → API & Webhooks',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _controller,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'API Token',
                  hintText: 'Inserisci il token...',
                  prefixIcon: const Icon(Icons.key),
                  errorText: _error,
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Inserisci un token';
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
                    : const Text('Connetti'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final storage = ref.read(storageServiceProvider);
      final baseUrl = await storage.read(key: 'instance_url');
      if (baseUrl == null) throw Exception('Instance URL missing');

      final token = _controller.text.trim();

      // Usa direttamente il connettore senza provider completo per evitare caching
      // Per simularlo possiamo usare una logica custom o watchare temporaneamente.
      // E' preferibile invocare la Repo bypassando la cache per il test:
      // Wait, let's just create a new HTTP client or test it directly.
      // Nel requirement si chiedeva repo.testConnection(baseUrl, apiToken).
      // Creiamo un'istanza repo temporanea?
      // La repo nel provider si inizializza da storage. Salviamo prima su storage.
      await ref.read(authStateProvider.notifier).login(token);

      // Invalida il provider per ricaricare repo.
      ref.invalidate(crmRepositoryProvider);

      final repo = await ref.read(crmRepositoryProvider.future);
      final isOk = await repo.testConnection(baseUrl, token);

      if (isOk) {
        if (mounted) context.go('/contacts');
      } else {
        if (mounted) {
          setState(
            () => _error = 'Connessione fallita. Controlla URL e Token.',
          );
        }
        await storage.delete(key: 'api_token');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Errore di connessione: $e');
      }
      final storage = ref.read(storageServiceProvider);
      await storage.delete(key: 'api_token');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
