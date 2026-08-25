import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:job_manager/job_manager.dart';

import '../providers/download_providers.dart';

/// Starts background download coordination after the app mounts.
class DownloadBackgroundScope extends ConsumerStatefulWidget {
  const DownloadBackgroundScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DownloadBackgroundScope> createState() =>
      _DownloadBackgroundScopeState();
}

class _DownloadBackgroundScopeState
    extends ConsumerState<DownloadBackgroundScope> {
  BackgroundDownloadCoordinator? _coordinator;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeStartCoordinator());
    });
  }

  Future<void> _maybeStartCoordinator() async {
    final isTestBinding =
        WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (isTestBinding) return;

    final coordinator = BackgroundDownloadCoordinator(
      downloadManager: ref.read(downloadManagerProvider),
    );
    await coordinator.initialize();
    if (!mounted) {
      await coordinator.dispose();
      return;
    }
    setState(() => _coordinator = coordinator);
  }

  @override
  void dispose() {
    unawaited(_coordinator?.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
