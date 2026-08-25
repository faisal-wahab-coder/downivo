import 'dart:async';

import 'package:analytics/analytics.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/analytics_providers.dart';
import '../providers/library_providers.dart';
import '../providers/settings_provider.dart';

/// Maintenance banner, first `app_opened`, and low-storage warning.
class ObservabilityScope extends ConsumerStatefulWidget {
  const ObservabilityScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ObservabilityScope> createState() => _ObservabilityScopeState();
}

class _ObservabilityScopeState extends ConsumerState<ObservabilityScope> {
  var _opened = false;
  var _storageWarned = false;

  static const _lowStorageBytes = 500 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _emitOpened();
      unawaited(_checkStorage());
    });
  }

  void _emitOpened() {
    if (_opened) return;
    _opened = true;
    ref.read(analyticsServiceProvider).track(AnalyticsEvent.appOpened);
  }

  Future<void> _checkStorage() async {
    if (!mounted || _storageWarned) return;
    final info = await ref.read(volumeStatsProvider.future);
    if (!mounted || !info.hasVolumeStats) return;
    if (info.freeBytes >= _lowStorageBytes) return;
    _storageWarned = true;
    ref.read(analyticsServiceProvider).track(AnalyticsEvent.storageWarning, {
      AnalyticsProp.fileSize: fileSizeBucket(info.freeBytes),
    });
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(
      const SnackBar(
        content: Text(
          'Storage is running low. Free up space so downloads can finish.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remote = ref.watch(remoteAppConfigProvider);
    final onboarding = ref.watch(
      settingsProvider.select((s) => s.onboardingComplete),
    );
    return Column(
      children: [
        if (remote.maintenanceMode && onboarding)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: UdmSpacing.md,
                  vertical: UdmSpacing.sm,
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: UdmSpacing.sm),
                    Expanded(
                      child: Text(
                        'Downloads are temporarily limited. Some sources may be unavailable.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
