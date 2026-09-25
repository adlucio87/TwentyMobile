// Schermata di review con campi pre-compilati editabili
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/di/providers.dart';
import 'scan_provider.dart';
import 'package:pocketcrm/core/utils/demo_utils.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';

class ScanReviewScreen extends ConsumerStatefulWidget {
  const ScanReviewScreen({super.key});

  @override
  ConsumerState<ScanReviewScreen> createState() => _ScanReviewScreenState();
}

class _ScanReviewScreenState extends ConsumerState<ScanReviewScreen> {
  late TextEditingController _firstName;
  late TextEditingController _lastName;
  late TextEditingController _email;
  late TextEditingController _phone;
  late TextEditingController _company;
  late TextEditingController _jobTitle;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final state = ref.read(scanNotifierProvider);
    final data = state.parsedData;
    if (kDebugMode) {
      debugPrint('REVIEW: initState - status: ${state.status}, data: $data');
    }
    _firstName = TextEditingController(text: data?.firstName ?? '');
    _lastName = TextEditingController(text: data?.lastName ?? '');
    _email = TextEditingController(text: data?.email ?? '');
    _phone = TextEditingController(text: data?.phone ?? '');
    _company = TextEditingController(text: data?.company ?? '');
    _jobTitle = TextEditingController(text: data?.jobTitle ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(scanNotifierProvider);
    if (kDebugMode) {
      debugPrint(
          'REVIEW: build - status: ${scanState.status}, data: ${scanState.parsedData}');
    }

    final l10n = AppLocalizations.of(context);

    // Mostra loading se ancora in elaborazione
    if (scanState.status == ScanStatus.processing) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(l10n?.analyzingBusinessCard ?? 'Analyzing business card...'),
            ],
          ),
        ),
      );
    }

    // Mostra errore
    if (scanState.status == ScanStatus.error) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(scanState.errorMessage ?? (l10n?.error ?? 'Unknown error')),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n?.tryAgain ?? 'Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    // Confidence indicator
    final confidence = scanState.parsedData?.confidence ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.verifyData ?? 'Verify data'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(scanNotifierProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Banner confidenza
          _ConfidenceBanner(confidence: confidence),

          // Form campi editabili
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n?.contacts.toUpperCase() ?? 'CONTACT',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 1.2, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(children: [
                    Expanded(child: _Field(l10n?.firstName ?? 'Name', _firstName, Icons.person)),
                    const SizedBox(width: 12),
                    Expanded(child: _Field(l10n?.lastName ?? 'Last Name', _lastName, null)),
                  ]),
                  const SizedBox(height: 12),
                  _Field(l10n?.email ?? 'Email', _email, Icons.email),
                  const SizedBox(height: 12),
                  _Field(l10n?.phone ?? 'Phone', _phone, Icons.phone),
                  const SizedBox(height: 24),
                  Text(l10n?.company.toUpperCase() ?? 'COMPANY',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                        letterSpacing: 1.2, color: Colors.grey)),
                  const SizedBox(height: 8),
                  _Field(l10n?.company ?? 'Company', _company, Icons.business),
                  const SizedBox(height: 12),
                  _Field(l10n?.jobTitle ?? 'Role', _jobTitle, Icons.work_outline),
                ],
              ),
            ),
          ),

          // Bottone salva
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(l10n?.addContact ?? 'Create Contact'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _Field(String label, TextEditingController ctrl, IconData? icon) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    if (!await DemoUtils.checkDemoAction(context, ref)) return;

    if (_firstName.text.trim().isEmpty && _email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n?.enterNameOrEmail ?? 'Enter at least name or email')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(crmRepositoryProvider).requireValue;
      final contact = await repo.createContact(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        email: _email.text.trim().isEmpty ? null : _email.text.trim(),
        phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      );

      ref.read(scanNotifierProvider.notifier).reset();
      ref.invalidate(contactsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${l10n?.contactAdded ?? 'Contact added'}'),
            backgroundColor: Colors.green,
          ),
        );
        // Navigate to contact details
        context.go('/contacts/${contact.id}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n?.error ?? 'Error'}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstName.dispose(); _lastName.dispose();
    _email.dispose(); _phone.dispose();
    _company.dispose(); _jobTitle.dispose();
    super.dispose();
  }
}

// Banner che mostra confidenza del parsing
class _ConfidenceBanner extends StatelessWidget {
  final double confidence;
  const _ConfidenceBanner({required this.confidence});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = confidence >= 0.7
        ? Colors.green
        : confidence >= 0.4
            ? Colors.orange
            : Colors.red;

    final message = confidence >= 0.7
        ? (l10n?.confidenceHigh ?? '✅ Excellent capture — verify data')
        : confidence >= 0.4
            ? (l10n?.confidenceMedium ?? '⚠️ Partial capture — check fields')
            : (l10n?.confidenceLow ?? '❌ Difficult to read — fill manually');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: color.withValues(alpha: 0.1),
      child: Text(message,
        style: TextStyle(color: color, fontWeight: FontWeight.w500, fontSize: 13)),
    );
  }
}