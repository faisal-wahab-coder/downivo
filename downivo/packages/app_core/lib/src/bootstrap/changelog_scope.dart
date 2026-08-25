import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../changelog/app_changelog.dart';
import '../changelog/changelog_dialog.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';

/// Shows What's new once after the app version changes.
class ChangelogScope extends ConsumerStatefulWidget {
  const ChangelogScope({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ChangelogScope> createState() => _ChangelogScopeState();
}

class _ChangelogScopeState extends ConsumerState<ChangelogScope> {
  var _presented = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_maybeShow());
    });
  }

  Future<void> _maybeShow() async {
    if (!mounted || _presented) return;

    final settings = ref.read(settingsProvider);
    if (!settings.onboardingComplete) return;

    final unread = unreadChangelogEntries(settings.lastSeenChangelogVersion);
    if (unread.isEmpty) return;

    final navContext = await _waitForNavigator();
    if (navContext == null || !navContext.mounted || !mounted) return;

    _presented = true;
    await showChangelogDialog(navContext, entries: unread);
    if (!mounted) return;
    await ref
        .read(settingsProvider.notifier)
        .markChangelogSeen(latestChangelogVersion);
  }

  Future<BuildContext?> _waitForNavigator() async {
    for (var i = 0; i < 8; i++) {
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return null;
      final nav = _navigatorContext;
      if (nav != null && nav.mounted) return nav;
    }
    return _navigatorContext;
  }

  BuildContext? get _navigatorContext =>
      ref.read(goRouterProvider).routerDelegate.navigatorKey.currentContext;

  @override
  Widget build(BuildContext context) => widget.child;
}
