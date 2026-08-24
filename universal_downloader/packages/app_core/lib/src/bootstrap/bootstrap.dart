import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storage/storage.dart';

import '../bootstrap/app_initializer.dart';
import '../navigation/app_router.dart';
import '../providers/app_providers.dart';
import '../providers/download_providers.dart';
import '../providers/performance_providers.dart';
import '../providers/settings_provider.dart';

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

  late final DownloadManager downloadManager;

  if (!isTestBinding && prefs.getBool('onboarding_complete') == true) {
    await initializer.initialize();
    final path = initializer.storagePaths?.rootPath ?? previewPaths.rootPath;
    if (prefs.getString('storage_root_path') == null) {
      await prefs.setString('storage_root_path', path);
    }
    downloadManager = await initializer.createDownloadManager(
      initializer.storagePaths ?? previewPaths,
    );
  } else {
    downloadManager = await initializer.createDownloadManager(
      previewPaths,
      restoreTasks: !isTestBinding,
    );
  }

  ProviderContainer? containerRef;

  final router = AppRouter(
    showOnboarding: !(prefs.getBool('onboarding_complete') ?? false),
    storagePath: prefs.getString('storage_root_path') ?? previewPaths.rootPath,
    onInitialize: () async {
      final paths = await initializer.initialize();
      await containerRef!
          .read(settingsProvider.notifier)
          .setStorageRootPath(paths.rootPath);
    },
    onRequestPermission: initializer.requestPermission,
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
    ],
  );

  startupStopwatch.stop();
  containerRef.read(performanceManagerProvider).recordStartup(
        Duration(milliseconds: startupStopwatch.elapsedMilliseconds),
      );

  return containerRef;
}
