import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_types/shared_types.dart';

import '../../changelog/app_changelog.dart';
import '../../changelog/changelog_dialog.dart';
import '../../providers/analytics_providers.dart';
import '../../providers/library_providers.dart';
import '../../providers/performance_providers.dart';
import '../../providers/settings_provider.dart';
import '../home/storage_dashboard.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final storagePath = ref.watch(storagePathProvider);
    final metrics = ref.watch(performanceMetricsProvider);
    final storageStats = ref.watch(managedStorageStatsProvider);
    final summaries = ref.watch(categorySummariesProvider);
    final volume = ref.watch(volumeStatsProvider);
    final wide =
        MediaQuery.sizeOf(context).width >= UdmBreakpoints.desktop;

    final appearance = [
      const UdmSectionLabel(label: 'Appearance'),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(UdmSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Theme',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: UdmSpacing.md),
              SegmentedButton<ThemeModePreference>(
                segments: const [
                  ButtonSegment(
                    value: ThemeModePreference.system,
                    label: Text('System'),
                  ),
                  ButtonSegment(
                    value: ThemeModePreference.light,
                    label: Text('Light'),
                  ),
                  ButtonSegment(
                    value: ThemeModePreference.dark,
                    label: Text('Dark'),
                  ),
                ],
                selected: {settings.themeMode},
                onSelectionChanged: (selected) {
                  ref
                      .read(settingsProvider.notifier)
                      .setThemeMode(selected.first);
                },
              ),
            ],
          ),
        ),
      ),
    ];

    final quality = [
      const UdmSectionLabel(label: 'Preferred quality'),
      Card(
        child: Column(
          children: [
            ListTile(
              title: const Text('Quality'),
              subtitle: Text(settings.preferredQuality ?? 'Recommended'),
              trailing: PopupMenuButton<String>(
                tooltip: 'Preferred quality',
                onSelected: (value) => ref
                    .read(settingsProvider.notifier)
                    .setPreferredQuality(value.isEmpty ? null : value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: '', child: Text('Recommended')),
                  PopupMenuItem(value: '1080', child: Text('1080p')),
                  PopupMenuItem(value: '720', child: Text('720p')),
                  PopupMenuItem(value: '480', child: Text('480p')),
                  PopupMenuItem(value: '360', child: Text('360p')),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              title: const Text('Format'),
              subtitle: Text(settings.preferredFormat ?? 'Any'),
              trailing: PopupMenuButton<String>(
                tooltip: 'Preferred format',
                onSelected: (value) => ref
                    .read(settingsProvider.notifier)
                    .setPreferredFormat(value.isEmpty ? null : value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: '', child: Text('Any')),
                  PopupMenuItem(value: 'mp4', child: Text('MP4')),
                  PopupMenuItem(value: 'webm', child: Text('WebM')),
                  PopupMenuItem(value: 'audio', child: Text('Audio')),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    final downloads = [
      const UdmSectionLabel(label: 'Downloads'),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Download history'),
              subtitle: const Text('All completed and failed downloads'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.downloadHistory),
            ),
            const Divider(height: 1),
            if (kIsWeb)
              const ListTile(
                title: Text('Clipboard monitoring'),
                subtitle: Text(
                  'Browsers block background clipboard reads. Use Paste on Home, or Ctrl+V / ⌘V.',
                ),
              )
            else
              SwitchListTile(
                title: const Text('Clipboard monitoring'),
                subtitle: const Text('Suggest downloads when you copy links'),
                value: settings.clipboardMonitoringEnabled,
                onChanged: (enabled) => ref
                    .read(settingsProvider.notifier)
                    .setClipboardMonitoring(enabled),
              ),
          ],
        ),
      ),
    ];

    final privacy = [
      const UdmSectionLabel(label: 'Privacy & diagnostics'),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Usage analytics'),
              subtitle: const Text(
                'Anonymous events for downloads and screens. URLs and tokens are never sent.',
              ),
              value: settings.analyticsEnabled,
              onChanged: (enabled) => ref
                  .read(settingsProvider.notifier)
                  .setAnalyticsEnabled(enabled),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Crash reporting'),
              subtitle: const Text(
                'Send crash reports so failures can be fixed. No download URLs are included.',
              ),
              value: settings.crashReportingEnabled,
              onChanged: (enabled) => ref
                  .read(settingsProvider.notifier)
                  .setCrashReportingEnabled(enabled),
            ),
          ],
        ),
      ),
    ];

    final storage = [
      const UdmSectionLabel(label: 'Storage'),
      StorageDashboard(
        managedStats: storageStats,
        summaries: summaries,
        volume: volume,
      ),
      const SizedBox(height: UdmSpacing.md),
      Card(
        child: ListTile(
          leading: const Icon(Icons.folder_outlined),
          title: Text(kIsWeb ? 'Browser storage' : 'Download folder'),
          subtitle: Text(
            kIsWeb
                ? 'Files stay in this browser until you save them to disk from Files.'
                : storagePath,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    final advanced = [
      const UdmSectionLabel(label: 'Advanced'),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.speed_outlined),
              title: const Text('Startup time'),
              subtitle: Text('${metrics['startup_ms'] ?? 0} ms'),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cached_outlined),
              title: const Text('Library scan cache'),
              subtitle: Text(
                '${metrics['cache_hits'] ?? 0} hits · ${metrics['cache_misses'] ?? 0} misses',
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.cleaning_services_outlined),
              title: const Text('Clear caches'),
              subtitle: const Text('Free memory and refresh library scans'),
              onTap: () async {
                ref.read(performanceManagerProvider).clearCaches();
                ref.read(mediaLibraryServiceProvider).invalidateScanCache();
                invalidateLibrary(ref);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Caches cleared')),
                  );
                }
              },
            ),
            if (kDebugMode) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Send test crash'),
                subtitle: const Text('Debug only — verifies Crashlytics'),
                onTap: () {
                  throw StateError('UDM controlled test crash');
                },
              ),
              ListTile(
                leading: const Icon(Icons.report_outlined),
                title: const Text('Send test non-fatal'),
                subtitle: const Text('Debug only — verifies error reporting'),
                onTap: () {
                  ref.read(analyticsServiceProvider).recordNonFatal(
                    StateError('UDM controlled non-fatal'),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Non-fatal sent')),
                  );
                },
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: UdmSpacing.xxl),
      ListTile(
        leading: const Icon(Icons.info_outline),
        title: const Text('About'),
        subtitle: Text('${AppIdentity.displayName} v$latestChangelogVersion'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => showChangelogDialog(context),
      ),
    ];

    Widget column(List<Widget> children) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1) const SizedBox(height: UdmSpacing.xxl),
          ],
        ],
      );
    }

    return UdmScaffold(
      title: 'Settings',
      body: ListView(
        padding: const EdgeInsets.all(UdmSpacing.lg),
        children: [
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: column([...appearance, ...quality, ...downloads]),
                ),
                const SizedBox(width: UdmSpacing.xxl),
                Expanded(
                  child: column([...storage, ...privacy, ...advanced]),
                ),
              ],
            )
          else ...[
            ...appearance,
            const SizedBox(height: UdmSpacing.xxl),
            ...quality,
            const SizedBox(height: UdmSpacing.xxl),
            ...downloads,
            const SizedBox(height: UdmSpacing.xxl),
            ...storage,
            const SizedBox(height: UdmSpacing.xxl),
            ...privacy,
            const SizedBox(height: UdmSpacing.xxl),
            ...advanced,
          ],
        ],
      ),
    );
  }
}
