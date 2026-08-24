import 'package:flutter/material.dart';

import '../spacing.dart';

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
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(UdmSpacing.xxxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (progress != null) ...[
                LinearProgressIndicator(value: progress),
                const SizedBox(height: UdmSpacing.xxl),
              ],
              if (icon != null) ...[
                Icon(icon, size: 72, color: theme.colorScheme.primary),
                const SizedBox(height: UdmSpacing.xxl),
              ],
              Text(title, style: theme.textTheme.headlineSmall),
              const SizedBox(height: UdmSpacing.lg),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(UdmSpacing.lg),
                    child: body,
                  ),
                ),
              ),
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
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primaryContainer,
        child: Icon(icon, color: theme.colorScheme.onPrimaryContainer),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
