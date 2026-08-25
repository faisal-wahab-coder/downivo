import 'package:analytics/analytics.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permissions/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';

import '../bootstrap/app_initializer.dart';
import '../navigation/app_router.dart';
import '../observability/analytics_route_observer.dart';
import '../observability/engine_analytics_bridge.dart';
import '../providers/analytics_providers.dart';
import '../providers/app_providers.dart';
import '../providers/download_providers.dart';
import '../providers/performance_providers.dart';

Future<ProviderContainer> bootstrap() async {
  final startupStopwatch = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  final prefsFuture = SharedPreferences.getInstance();
  final pathsFuture = StoragePaths.resolve();
  final initializer = AppInitializer();
  await initializer.fileStore.initialize();
  final prefs = await prefsFuture;
  final previewPaths = await pathsFuture;

  final isTestBinding =
      WidgetsBinding.instance.runtimeType.toString().contains('Test');

  final analytics = isTestBinding
      ? AnalyticsService.disabled()
      : await AnalyticsService.bootstrap(
          analyticsEnabled: prefs.getBool('analytics_enabled') ?? true,
          crashReportingEnabled:
              prefs.getBool('crash_reporting_enabled') ?? true,
        );
  final telemetry = EngineAnalyticsBridge(analytics);

  late final DownloadManager downloadManager;

  if (!isTestBinding && prefs.getBool('onboarding_complete') == true) {
    await initializer.initialize();
    final path = initializer.storagePaths?.rootPath ?? previewPaths.rootPath;
    if (prefs.getString('storage_root_path') == null) {
      await prefs.setString('storage_root_path', path);
    }
    downloadManager = await initializer.createDownloadManager(
      initializer.storagePaths ?? previewPaths,
      telemetry: telemetry,
    );
  } else {
    downloadManager = await initializer.createDownloadManager(
      previewPaths,
      restoreTasks: !isTestBinding,
      telemetry: telemetry,
    );
  }
  downloadManager.setMaxConcurrent(analytics.remote.maxConcurrentDownloads);

  ProviderContainer? containerRef;

  Future<PermissionResult> requestPermission(AppPermission permission) async {
    analytics.track(AnalyticsEvent.permissionRequested, {
      AnalyticsProp.permission: permission.name,
    });
    final result = await initializer.requestPermission(permission);
    analytics.track(
      result.granted
          ? AnalyticsEvent.permissionGranted
          : AnalyticsEvent.permissionDenied,
      {AnalyticsProp.permission: permission.name},
    );
    return result;
  }

  final router = AppRouter(
    showOnboarding: !(prefs.getBool('onboarding_complete') ?? false),
    storagePath: prefs.getString('storage_root_path') ?? previewPaths.rootPath,
    observers: [AnalyticsRouteObserver(analytics)],
    onInitialize: () async {
      final paths = await initializer.initialize();
      await containerRef!
          .read(settingsProvider.notifier)
          .setStorageRootPath(paths.rootPath);
    },
    onRequestPermission: requestPermission,
    onOpenSettings: initializer.permissionService.openSettings,
    onOnboardingComplete: () async {
      await containerRef!.read(settingsProvider.notifier).completeOnboarding();
    },
  ).router;

  containerRef = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      appInitializerProvider.overrideWithValue(initializer),
      defaultStoragePathProvider.overrideWithValue(previewPaths.rootPath),
      downloadManagerProvider.overrideWithValue(downloadManager),
      goRouterProvider.overrideWithValue(router),
      analyticsServiceProvider.overrideWithValue(analytics),
    ],
  );

  startupStopwatch.stop();
  containerRef.read(performanceManagerProvider).recordStartup(
        Duration(milliseconds: startupStopwatch.elapsedMilliseconds),
      );

  return containerRef;
}
