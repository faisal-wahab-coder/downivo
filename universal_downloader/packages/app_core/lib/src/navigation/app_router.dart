import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:navigation/navigation.dart';
import 'package:permissions/permissions.dart';
import 'package:shared_types/shared_types.dart';

import '../features/downloads/downloads_screen.dart' as downloads_feature;
import '../features/downloads/download_history_screen.dart';
import '../features/browser/browser_screen.dart' as browser_feature;
import '../features/files/files_screen.dart' as files_feature;
import '../features/home/home_screen.dart' as home_feature;
import '../features/settings/settings_screen.dart';

class AppRouter {
  AppRouter({
    required this.showOnboarding,
    required this.storagePath,
    this.onInitialize,
    this.onOnboardingComplete,
    this.onRequestPermission,
    this.onOpenSettings,
  });

  final bool showOnboarding;
  final String storagePath;
  final Future<void> Function()? onInitialize;
  final Future<void> Function()? onOnboardingComplete;
  final Future<PermissionResult> Function(AppPermission permission)?
      onRequestPermission;
  final Future<void> Function()? onOpenSettings;

  late final GoRouter router = GoRouter(
    initialLocation: showOnboarding ? AppRoutes.onboarding : AppRoutes.home,
    routes: [
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => OnboardingFlow(
          storagePath: storagePath,
          onInitialize: () async => onInitialize?.call(),
          onRequestPermission: onRequestPermission,
          onOpenSettings: onOpenSettings,
          onComplete: () async {
            await onOnboardingComplete?.call();
            if (context.mounted) context.go(AppRoutes.home);
          },
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(
            currentIndex: navigationShell.currentIndex,
            onDestinationSelected: navigationShell.goBranch,
            child: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const home_feature.HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.downloads,
                builder: (context, state) =>
                    const downloads_feature.DownloadsScreen(),
                routes: [
                  GoRoute(
                    path: 'history',
                    builder: (context, state) =>
                        const DownloadHistoryScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.browser,
                builder: (context, state) => const browser_feature.BrowserScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.files,
                builder: (context, state) => const files_feature.FilesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
