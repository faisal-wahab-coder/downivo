import 'dart:async';

import 'package:content_intake/content_intake.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/intake/intake_prompt_sheet.dart';
import '../providers/app_providers.dart';
import '../providers/intake_providers.dart';
import 'share_intake_factory.dart';

/// Foreground clipboard polling and share-intent handling — docs/19, docs/20
class IntakeScope extends ConsumerStatefulWidget {
  const IntakeScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IntakeScope> createState() => _IntakeScopeState();
}

class _IntakeScopeState extends ConsumerState<IntakeScope>
    with WidgetsBindingObserver {
  Timer? _clipboardTimer;
  final _shareIntake = createShareIntake();
  var _handlingShare = false;
  var _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_initShareHandling());
      _startClipboardPolling();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopClipboardPolling();
    unawaited(_shareIntake.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
        _startClipboardPolling();
        unawaited(_pollClipboard());
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _isForeground = false;
        _stopClipboardPolling();
    }
  }

  Future<void> _initShareHandling() async {
    if (_isTestBinding) return;
    await _shareIntake.start(_handleSharedPayload);
  }

  void _startClipboardPolling() {
    if (kIsWeb || _isTestBinding || !_isForeground || _clipboardTimer != null) {
      return;
    }

    _clipboardTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      unawaited(_pollClipboard());
    });
  }

  void _stopClipboardPolling() {
    _clipboardTimer?.cancel();
    _clipboardTimer = null;
  }

  Future<void> _pollClipboard() async {
    if (kIsWeb || !mounted || _isTestBinding || !_isForeground) return;
    if (!ref.read(settingsProvider).clipboardMonitoringEnabled) return;

    final detected = await ref.read(clipboardMonitorProvider).poll();
    if (detected == null || !mounted) return;
    if (!detected.hasUrls && detected.rawText.trim().isEmpty) return;

    await ref.read(clipboardHistoryStoreProvider).add(
          text: detected.rawText,
          detectedUrl: detected.primaryUrl,
        );
    refreshIntakeData(ref);

    final action =
        ref.read(qrContentResolverProvider).resolveClipboard(detected);
    if (action.type == IntakeActionType.showText && !detected.hasUrls) {
      return;
    }

    if (!mounted) return;
    await _presentAction(action);
  }

  Future<void> _handleSharedPayload(SharePayload payload) async {
    if (_handlingShare || !mounted || payload.isEmpty) return;
    _handlingShare = true;
    try {
      final action = ref.read(qrContentResolverProvider).resolveShare(payload);
      await _shareIntake.reset();
      if (!mounted) return;
      await _presentAction(action);
    } finally {
      _handlingShare = false;
    }
  }

  Future<void> _presentAction(IntakeAction action) async {
    var navContext = _navigatorContext;
    if (navContext == null) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      navContext = _navigatorContext;
    }
    if (navContext == null || !navContext.mounted) return;
    await showIntakeActionSheet(navContext, ref, action);
  }

  BuildContext? get _navigatorContext =>
      ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;

  bool get _isTestBinding =>
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  @override
  Widget build(BuildContext context) => widget.child;
}
