import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_types/shared_types.dart';

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
              subtitle: Text(
                settings.preferredFormat == 'audio' ? 'Audio' : 'Video',
              ),
              trailing: PopupMenuButton<String>(
                tooltip: 'Preferred format',
                onSelected: (value) => ref
                    .read(settingsProvider.notifier)
                    .setPreferredFormat(value),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'video', child: Text('Video')),
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

    final connectionSettings = [
      const UdmSectionLabel(label: 'Connection'),
      Card(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.hub_outlined),
              title: const Text('Default connections per download'),
              subtitle: Text('${settings.defaultConnectionCount} parallel connections'),
              trailing: SizedBox(
                width: 120,
                child: Slider(
                  value: settings.defaultConnectionCount.toDouble(),
                  min: 1,
                  max: 8,
                  divisions: 7,
                  label: '${settings.defaultConnectionCount}',
                  onChanged: (value) => ref
                      .read(settingsProvider.notifier)
                      .setDefaultConnectionCount(value.round()),
                ),
              ),
            ),
            const Divider(height: 1),
            SwitchListTile(
              secondary: const Icon(Icons.refresh_rounded),
              title: const Text('Auto-reload stuck downloads'),
              subtitle: const Text(
                  'Reconnect when speed drops to 0 for 8+ seconds'),
              value: settings.autoReloadStuck,
              onChanged: (enabled) => ref
                  .read(settingsProvider.notifier)
                  .setAutoReloadStuck(enabled),
            ),
          ],
        ),
      ),
    ];

    final speedLimiterSettings = [
      const UdmSectionLabel(label: 'Speed Limiter'),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.speed_outlined),
              title: const Text('Speed limiter'),
              subtitle: Text(settings.speedLimitConfig.enabled
                  ? _formatSpeedLimit(settings.speedLimitConfig.limitBytesPerSec)
                  : 'Unlimited'),
              value: settings.speedLimitConfig.enabled,
              onChanged: (enabled) {
                final updated =
                    settings.speedLimitConfig.copyWith(enabled: enabled);
                ref.read(settingsProvider.notifier).setSpeedLimitConfig(updated);
              },
            ),
            if (settings.speedLimitConfig.enabled) ...[
              const Divider(height: 1),
              ListTile(
                title: const Text('Global cap'),
                subtitle: Text(_formatSpeedLimit(
                    settings.speedLimitConfig.limitBytesPerSec)),
                trailing: SizedBox(
                  width: 160,
                  child: Slider(
                    value: (settings.speedLimitConfig.limitBytesPerSec /
                            (1024 * 1024))
                        .clamp(0.1, 100)
                        .toDouble(),
                    min: 0.1,
                    max: 100,
                    divisions: 999,
                    label: _formatSpeedLimit(
                        settings.speedLimitConfig.limitBytesPerSec),
                    onChanged: (value) {
                      final bytes = (value * 1024 * 1024).round();
                      final updated =
                          settings.speedLimitConfig.copyWith(limitBytesPerSec: bytes);
                      ref
                          .read(settingsProvider.notifier)
                          .setSpeedLimitConfig(updated);
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: const Text('Day/night schedule'),
                subtitle: const Text(
                    'Different speeds for daytime vs nighttime'),
                value: settings.speedLimitConfig.scheduledLimit.enabled,
                onChanged: (enabled) {
                  final updated = settings.speedLimitConfig.copyWith(
                    scheduledLimit: settings.speedLimitConfig.scheduledLimit
                        .copyWith(enabled: enabled),
                  );
                  ref.read(settingsProvider.notifier).setSpeedLimitConfig(updated);
                },
              ),
              if (settings.speedLimitConfig.scheduledLimit.enabled) ...[
                ListTile(
                  title: Text(
                      'Day (${settings.speedLimitConfig.scheduledLimit.dayStartHour}:00–'
                      '${settings.speedLimitConfig.scheduledLimit.nightStartHour}:00)'),
                  subtitle: Text(_formatSpeedLimit(
                      settings.speedLimitConfig.scheduledLimit.daytimeLimitBytesPerSec)),
                ),
                ListTile(
                  title: Text(
                      'Night (${settings.speedLimitConfig.scheduledLimit.nightStartHour}:00–'
                      '${settings.speedLimitConfig.scheduledLimit.dayStartHour}:00)'),
                  subtitle: Text(settings.speedLimitConfig.scheduledLimit
                              .nighttimeLimitBytesPerSec ==
                          0
                      ? 'Unlimited'
                      : _formatSpeedLimit(settings.speedLimitConfig.scheduledLimit
                          .nighttimeLimitBytesPerSec)),
                ),
              ],
            ],
          ],
        ),
      ),
    ];

    final schedulerSettings = [
      const UdmSectionLabel(label: 'Scheduler'),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.schedule_outlined),
              title: const Text('Download scheduler'),
              subtitle: Text(settings.schedulerConfig.enabled
                  ? '${settings.schedulerConfig.startTime} – ${settings.schedulerConfig.stopTime}'
                  : 'Disabled'),
              value: settings.schedulerConfig.enabled,
              onChanged: (enabled) {
                final updated =
                    settings.schedulerConfig.copyWith(enabled: enabled);
                ref.read(settingsProvider.notifier).setSchedulerConfig(updated);
              },
            ),
            if (settings.schedulerConfig.enabled) ...[
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Start time'),
                subtitle: Text(settings.schedulerConfig.startTime),
                onTap: () async {
                  final time = await _pickTime(context,
                      settings.schedulerConfig.startTime);
                  if (time != null) {
                    ref.read(settingsProvider.notifier).setSchedulerConfig(
                          settings.schedulerConfig.copyWith(startTime: time),
                        );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.stop_rounded),
                title: const Text('Stop time'),
                subtitle: Text(settings.schedulerConfig.stopTime),
                onTap: () async {
                  final time = await _pickTime(context,
                      settings.schedulerConfig.stopTime);
                  if (time != null) {
                    ref.read(settingsProvider.notifier).setSchedulerConfig(
                          settings.schedulerConfig.copyWith(stopTime: time),
                        );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Max concurrent'),
                subtitle: Text(
                    '${settings.schedulerConfig.maxConcurrentDownloads} downloads'),
                trailing: SizedBox(
                  width: 120,
                  child: Slider(
                    value: settings.schedulerConfig.maxConcurrentDownloads
                        .toDouble(),
                    min: 1,
                    max: 8,
                    divisions: 7,
                    label: '${settings.schedulerConfig.maxConcurrentDownloads}',
                    onChanged: (value) {
                      ref.read(settingsProvider.notifier).setSchedulerConfig(
                            settings.schedulerConfig.copyWith(
                              maxConcurrentDownloads: value.round(),
                            ),
                          );
                    },
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('When finished'),
                subtitle: Text(settings.schedulerConfig.actionOnCompletion.label),
                trailing: PopupMenuButton<SchedulerAction>(
                  tooltip: 'Action on completion',
                  onSelected: (action) =>
                      ref.read(settingsProvider.notifier).setSchedulerConfig(
                            settings.schedulerConfig
                                .copyWith(actionOnCompletion: action),
                          ),
                  itemBuilder: (context) => SchedulerAction.values
                      .map(
                        (action) => PopupMenuItem(
                          value: action,
                          child: Text(action.label),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    ];

    final categorySettings = [
      const UdmSectionLabel(label: 'Categories'),
      Card(
        child: Column(
          children: [
            SwitchListTile(
              secondary: const Icon(Icons.folder_special_outlined),
              title: const Text('Auto-organize downloads'),
              subtitle: const Text(
                  'Save files to subfolders by category (Videos, Images, Audio, etc.)'),
              value: settings.categoryAutoOrganize,
              onChanged: (enabled) => ref
                  .read(settingsProvider.notifier)
                  .setCategoryAutoOrganize(enabled),
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
        subtitle: const Text(AppIdentity.slogan),
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
                  child: column([
                    ...appearance,
                    ...quality,
                    ...downloads,
                    ...connectionSettings,
                    ...categorySettings,
                  ]),
                ),
                const SizedBox(width: UdmSpacing.xxl),
                Expanded(
                  child: column([
                    ...speedLimiterSettings,
                    ...schedulerSettings,
                    ...storage,
                    ...privacy,
                    ...advanced,
                  ]),
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
            ...connectionSettings,
            const SizedBox(height: UdmSpacing.xxl),
            ...speedLimiterSettings,
            const SizedBox(height: UdmSpacing.xxl),
            ...schedulerSettings,
            const SizedBox(height: UdmSpacing.xxl),
            ...categorySettings,
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

  static String _formatSpeedLimit(int bytesPerSec) {
    if (bytesPerSec <= 0) return 'Unlimited';
    if (bytesPerSec < 1024) return '${bytesPerSec} B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }

  static Future<String?> _pickTime(
    BuildContext context,
    String currentTime,
  ) async {
    final parts = currentTime.split(':');
    final initialTime = TimeOfDay(
      hour: int.tryParse(parts[0]) ?? 0,
      minute: int.tryParse(parts.last) ?? 0,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked == null) return null;
    return '${picked.hour.toString().padLeft(2, '0')}:'
        '${picked.minute.toString().padLeft(2, '0')}';
  }
}
