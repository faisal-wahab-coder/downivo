import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/udm_colors.dart';

abstract final class UdmMotion {
  static Duration of(BuildContext context, Duration duration) {
    return MediaQuery.disableAnimationsOf(context) ? Duration.zero : duration;
  }
}

class UdmSkeleton extends StatelessWidget {
  const UdmSkeleton({super.key, this.height = 16, this.width});

  final double height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading',
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class UdmSectionLabel extends StatelessWidget {
  const UdmSectionLabel({
    super.key,
    required this.label,
    this.trailing,
  });

  final String label;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UdmSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label.toUpperCase(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class PlatformBadge extends StatelessWidget {
  const PlatformBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: scheme.outline),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

enum UdmStatusTone { info, progress, caution, success, fault, muted }

class UdmStatusChip extends StatelessWidget {
  const UdmStatusChip({
    super.key,
    required this.label,
    this.tone = UdmStatusTone.info,
  });

  final String label;
  final UdmStatusTone tone;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      UdmStatusTone.progress => UdmColors.signalCyan,
      UdmStatusTone.caution => UdmColors.cautionAmber,
      UdmStatusTone.success => UdmColors.successMoss,
      UdmStatusTone.fault => UdmColors.faultCoral,
      UdmStatusTone.info => Theme.of(context).colorScheme.primary,
      UdmStatusTone.muted => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class UdmErrorState extends StatelessWidget {
  const UdmErrorState({
    super.key,
    required this.title,
    this.subtitle,
    this.onRetry,
  });

  final String title;
  final String? subtitle;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyLike(
      icon: Icons.error_outline,
      title: title,
      subtitle: subtitle,
      actionLabel: onRetry == null ? null : 'Retry',
      onAction: onRetry,
    );
  }
}

/// Compact empty/error composition used when [EmptyState] would be too large.
class EmptyLike extends StatelessWidget {
  const EmptyLike({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: UdmSpacing.xxl),
      child: Column(
        children: [
          Icon(icon, size: 40, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: UdmSpacing.md),
          Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
          if (subtitle != null) ...[
            const SizedBox(height: UdmSpacing.sm),
            Text(
              subtitle!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: UdmSpacing.lg),
            FilledButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class UrlInputField extends StatelessWidget {
  const UrlInputField({
    super.key,
    required this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onPaste,
    this.helperText = 'Paste a link to download',
    this.errorText,
    this.enabled = true,
    this.isResolving = false,
  });

  final TextEditingController controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onPaste;
  final String? helperText;
  final String? errorText;
  final bool enabled;
  final bool isResolving;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.go,
          autocorrect: false,
          onChanged: onChanged,
          onSubmitted: onSubmitted,
          style: Theme.of(context).textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'https://',
            prefixIcon: const Icon(Icons.link),
            suffixIcon: onPaste == null
                ? null
                : TextButton(
                    onPressed: onPaste,
                    child: const Text('Paste'),
                  ),
            errorText: errorText,
          ),
        ),
        if (isResolving) ...[
          const SizedBox(height: UdmSpacing.xs),
          const LinearProgressIndicator(),
        ],
        if (helperText != null && errorText == null && !isResolving) ...[
          const SizedBox(height: UdmSpacing.sm),
          Text(
            helperText!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ],
    );
  }
}
