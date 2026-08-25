import 'package:analytics/analytics.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._analytics);

  final AnalyticsService _analytics;
  String? _last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _emitFromContext(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _emitFromContext(newRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) _emitFromContext(previousRoute);
  }

  void _emitFromContext(Route<dynamic> route) {
    final nav = route.navigator;
    if (nav == null || !nav.mounted) {
      _emitName(route.settings.name);
      return;
    }
    try {
      final path = GoRouter.of(nav.context).state.uri.path;
      _emitName(path);
    } on Object {
      _emitName(route.settings.name);
    }
  }

  void _emitName(String? location) {
    if (location == null || location.isEmpty) return;
    final screen = screenNameForLocation(location);
    if (screen == _last) return;
    _last = screen;
    if (screen == AnalyticsScreen.settings) {
      _analytics.track(AnalyticsEvent.settingsOpened);
    }
    _analytics.screen(screen);
  }
}

String screenNameForLocation(String location) {
  final path = location.startsWith('/') ? location : '/$location';
  if (path.startsWith('/onboarding')) return AnalyticsScreen.onboarding;
  if (path.startsWith('/downloads/history')) return AnalyticsScreen.history;
  if (path.startsWith('/downloads')) return AnalyticsScreen.downloads;
  if (path.startsWith('/settings')) return AnalyticsScreen.settings;
  if (path.startsWith('/browser')) return AnalyticsScreen.browser;
  if (path.startsWith('/files')) return AnalyticsScreen.files;
  if (path == '/home' || path == '/') return AnalyticsScreen.home;
  return AnalyticsScreen.home;
}
