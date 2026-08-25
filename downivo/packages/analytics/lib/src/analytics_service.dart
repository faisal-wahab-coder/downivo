import 'dart:async';

import 'package:flutter/foundation.dart';

import 'analytics_config.dart';
import 'analytics_context.dart';
import 'analytics_events.dart';
import 'app_logger.dart';
import 'crashlytics_adapter.dart';
import 'device_context.dart';
import 'firebase_bootstrap.dart';
import 'posthog_adapter.dart';
import 'privacy_sanitizer.dart';
import 'remote_performance.dart';

/// Single write API for product events, crashes, and breadcrumbs.
class AnalyticsService {
  AnalyticsService({
    required AppLogger logger,
    required this.config,
    PrivacySanitizer sanitizer = const PrivacySanitizer(),
    CrashlyticsAdapter? crashlytics,
    PosthogAdapter? posthog,
    RemoteConfigClient? remoteConfig,
    PerformanceTraces? traces,
  }) : _logger = logger,
       _sanitizer = sanitizer,
       crashlytics = crashlytics ?? CrashlyticsAdapter(sanitizer: sanitizer),
       posthog = posthog ?? PosthogAdapter(sanitizer: sanitizer),
       remoteConfig = remoteConfig ?? RemoteConfigClient(),
       traces = traces ?? const PerformanceTraces();

  factory AnalyticsService.disabled() {
    return AnalyticsService(
      logger: AppLogger(),
      config: const AnalyticsConfig(
        posthogApiKey: '',
        posthogHost: 'https://us.i.posthog.com',
        analyticsEnabled: false,
        crashReportingEnabled: false,
      ),
    );
  }

  final AppLogger _logger;
  final PrivacySanitizer _sanitizer;
  final AnalyticsConfig config;
  final CrashlyticsAdapter crashlytics;
  final PosthogAdapter posthog;
  final RemoteConfigClient remoteConfig;
  final PerformanceTraces traces;
  final context = AnalyticsContext();

  var analyticsEnabled = true;
  var crashReportingEnabled = true;

  AppLogger get logger => _logger;
  RemoteAppConfig get remote => remoteConfig.current;

  static Future<AnalyticsService> bootstrap({
    required bool analyticsEnabled,
    required bool crashReportingEnabled,
  }) async {
    final config = AnalyticsConfig.fromEnvironment(
      analyticsEnabled: analyticsEnabled,
      crashReportingEnabled: crashReportingEnabled,
    );
    final service = AnalyticsService(logger: AppLogger(), config: config)
      ..analyticsEnabled = analyticsEnabled
      ..crashReportingEnabled = crashReportingEnabled;

    await FirebaseBootstrap.ensureInitialized();
    await service.crashlytics.attach(collectionEnabled: crashReportingEnabled);
    await service.posthog.setup(
      apiKey: config.posthogApiKey,
      host: config.posthogHost,
      enabled: analyticsEnabled,
    );
    await hydrateDeviceContext(service.context);
    await service.crashlytics.setKeys(service.context.crashlyticsKeys());
    await service.remoteConfig.fetch();
    service.installErrorHandlers();
    return service;
  }

  void installErrorHandlers() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      _logger.error(
        'FlutterError',
        fields: {'exception': details.exceptionAsString()},
      );
      unawaited(crashlytics.recordFlutterError(details, fatal: true));
      previous?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(recordError(error, stack, fatal: true));
      return true;
    };
  }

  void setScreen(String screen) {
    context.screen = screen;
    unawaited(crashlytics.setKeys(context.crashlyticsKeys()));
  }

  void setLastAction(String action) {
    context.lastAction = action;
    unawaited(crashlytics.setKeys(context.crashlyticsKeys()));
  }

  void setDownloadContext({
    String? platform,
    String? mediaType,
    String? downloadState,
  }) {
    if (platform != null) context.platform = platform;
    if (mediaType != null) context.mediaType = mediaType;
    if (downloadState != null) context.downloadState = downloadState;
    unawaited(crashlytics.setKeys(context.crashlyticsKeys()));
  }

  Future<void> setCollectionEnabled({
    required bool analytics,
    required bool crash,
  }) async {
    analyticsEnabled = analytics;
    crashReportingEnabled = crash;
    await posthog.setEnabled(analytics);
    await crashlytics.setCollectionEnabled(crash);
  }

  void track(String event, [Map<String, Object?>? properties]) {
    final merged = <String, Object>{
      ...context.eventDefaults(),
      ..._sanitizer.sanitize(properties),
    };
    _logger.info(event, fields: merged);
    if (!analyticsEnabled) return;
    unawaited(posthog.capture(event, merged));
  }

  void screen(String name) {
    setScreen(name);
    track(AnalyticsEvent.screenViewed, {AnalyticsProp.screen: name});
    unawaited(posthog.screen(name, context.eventDefaults()));
  }

  Future<void> recordError(
    Object error,
    StackTrace stack, {
    bool fatal = false,
    String? reason,
  }) async {
    _logger.log(
      fatal ? LogLevel.fatal : LogLevel.error,
      reason ?? error.runtimeType.toString(),
      fields: {'error': error.toString()},
    );
    await crashlytics.recordError(
      error,
      stack,
      fatal: fatal,
      reason: reason,
    );
  }

  Future<void> recordNonFatal(Object error, [StackTrace? stack]) {
    return recordError(error, stack ?? StackTrace.current, fatal: false);
  }
}
