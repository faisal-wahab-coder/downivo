import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/zfile_tokens.dart';

class OnboardingLayout extends StatelessWidget {
  const OnboardingLayout({
    super.key,
    required this.title,
    required this.body,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.progress,
    this.icon,
    this.isLoading = false,
  });

  final String title;
  final Widget body;
  final String primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final double? progress;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = ZfileTokens.of(context);
    return Scaffold(
      backgroundColor: tokens.onboarding,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                UdmSpacing.xl,
                UdmSpacing.lg,
                UdmSpacing.xl,
                UdmSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (progress != null) ...[
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(UdmRadius.button),
                      backgroundColor: tokens.onGradientHeading.withValues(alpha: 0.24),
                      color: tokens.secondary,
                    ),
                    const SizedBox(height: UdmSpacing.xl),
                  ],
                  if (icon != null) ...[
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: tokens.onGradientHeading.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(UdmRadius.hero),
                      ),
                      child: Icon(icon, size: 36, color: tokens.onGradientHeading),
                    ),
                    const SizedBox(height: UdmSpacing.lg),
                  ],
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: tokens.onGradientHeading,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: tokens.surfaceElevated.withValues(alpha: 0.96),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(UdmRadius.hero),
                  ),
                  boxShadow: tokens.floatingShadow,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    UdmSpacing.cardPaddingLarge,
                    UdmSpacing.xl,
                    UdmSpacing.cardPaddingLarge,
                    UdmSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(child: body),
                      if (isLoading)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        FilledButton(
                          onPressed: onPrimaryAction,
                          child: Text(primaryActionLabel),
                        ),
                        if (secondaryActionLabel != null) ...[
                          const SizedBox(height: UdmSpacing.sm),
                          TextButton(
                            onPressed: onSecondaryAction,
                            child: Text(secondaryActionLabel!),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PermissionCard extends StatelessWidget {
  const PermissionCard({
    super.key,
    required this.title,
    required this.description,
    this.granted,
    this.onRequest,
    this.optional = true,
    this.actionLabel = 'Allow',
  });

  final String title;
  final String description;
  final bool? granted;
  final VoidCallback? onRequest;
  final bool optional;
  final String actionLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UdmSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: theme.textTheme.titleMedium),
                ),
                if (optional)
                  Text(
                    'Optional',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                if (granted == true)
                  Icon(Icons.check_circle, color: theme.colorScheme.primary),
              ],
            ),
            const SizedBox(height: UdmSpacing.sm),
            Text(
              description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (onRequest != null && granted != true) ...[
              const SizedBox(height: UdmSpacing.lg),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: onRequest,
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FeatureHighlight extends StatelessWidget {
  const FeatureHighlight({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tokens = ZfileTokens.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: tokens.primaryContainer,
          borderRadius: BorderRadius.circular(UdmRadius.icon),
        ),
        child: Icon(icon, color: tokens.primary, size: 22),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
