import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bootstrap/download_background_scope.dart';
import '../bootstrap/intake_scope.dart';
import '../providers/app_providers.dart';
import '../providers/settings_provider.dart';

class UniversalDownloaderApp extends ConsumerWidget {
  const UniversalDownloaderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Universal Downloader',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: toFlutterThemeMode(settings.themeMode),
      routerConfig: router,
      builder: (context, child) {
        return DownloadBackgroundScope(
          child: IntakeScope(
            child: child ?? const SizedBox.shrink(),
          ),
        );
      },
    );
  }
}
