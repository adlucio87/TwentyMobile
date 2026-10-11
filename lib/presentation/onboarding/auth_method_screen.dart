import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pocketcrm/l10n/app_localizations.dart';
import 'package:pocketcrm/presentation/shared/language_button.dart';

class AuthMethodScreen extends StatelessWidget {
  const AuthMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.authentication ?? 'Authentication'),
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
              Text(
                l10n?.howDoYouWantToConnect ?? 'How do you want to connect?',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                l10n?.chooseAccessMethod ??
                    'Choose how you want to access your Twenty CRM instance',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: (0.6)),
                ),
              ),
              const SizedBox(height: 32),
              _buildMethodCard(
                context,
                title: l10n?.loginWithAccount ?? 'Login with your account',
                description: l10n?.loginWithAccountDesc ??
                    'Use your email and password. You will only see data assigned to you.',
                icon: Icons.person,
                badgeText: l10n?.recommended ?? 'Recommended',
                badgeColor: Colors.green,
                onTap: () => context.push('/onboarding/email'),
              ),
              const SizedBox(height: 16),
              _buildMethodCard(
                context,
                title: l10n?.loginWithApiKey ?? 'Login with API Key',
                description: l10n?.loginWithApiKeyDesc ??
                    'Full workspace access. For administrators and owners.',
                icon: Icons.key,
                badgeText: l10n?.adminBadge ?? 'Admin',
                badgeColor: theme.colorScheme.primary,
                onTap: () => context.push('/onboarding/token'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          description,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: (0.6)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: (0.1)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  badgeText,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: badgeColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
