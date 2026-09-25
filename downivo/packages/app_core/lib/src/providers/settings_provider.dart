import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permissions/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_types/shared_types.dart';

import '../bootstrap/app_initializer.dart';
import '../changelog/app_changelog.dart';
import '../navigation/app_router.dart';
import '../providers/analytics_providers.dart';

const _unset = Object();

const _onboardingKey = 'onboarding_complete';
const _themeKey = 'theme_mode';
const _clipboardKey = 'clipboard_monitoring';
const _storagePathKey = 'storage_root_path';
const _preferredQualityKey = 'preferred_quality';
const _preferredFormatKey = 'preferred_format';
const _changelogVersionKey = 'last_seen_changelog_version';
const _analyticsEnabledKey = 'analytics_enabled';
const _crashReportingKey = 'crash_reporting_enabled';
const _speedLimitEnabledKey = 'speed_limit_enabled';
const _speedLimitBytesKey = 'speed_limit_bytes_per_sec';
const _scheduledLimitEnabledKey = 'scheduled_limit_enabled';
const _scheduledDayLimitKey = 'scheduled_day_limit';
const _scheduledNightLimitKey = 'scheduled_night_limit';
const _scheduledDayStartKey = 'scheduled_day_start_hour';
const _scheduledNightStartKey = 'scheduled_night_start_hour';
const _schedulerEnabledKey = 'scheduler_enabled';
const _schedulerStartTimeKey = 'scheduler_start_time';
const _schedulerStopTimeKey = 'scheduler_stop_time';
const _schedulerMaxConcurrentKey = 'scheduler_max_concurrent';
const _schedulerActionKey = 'scheduler_action_on_completion';
const _defaultConnectionCountKey = 'default_connection_count';
const _autoReloadStuckKey = 'auto_reload_stuck';
const _categoryAutoOrganizeKey = 'category_auto_organize';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden at bootstrap');
});

final appInitializerProvider = Provider<AppInitializer>((ref) {
  throw UnimplementedError('AppInitializer must be overridden at bootstrap');
});

final defaultStoragePathProvider = Provider<String>((ref) {
  throw UnimplementedError('defaultStoragePathProvider must be overridden');
});

class AppSettings {
  const AppSettings({
    required this.onboardingComplete,
    required this.themeMode,
    required this.clipboardMonitoringEnabled,
    required this.storageRootPath,
    this.preferredQuality,
    this.preferredFormat,
    this.lastSeenChangelogVersion,
    this.analyticsEnabled = true,
    this.crashReportingEnabled = true,
    this.speedLimitConfig = const SpeedLimitConfig(),
    this.schedulerConfig = const SchedulerConfig(),
    this.defaultConnectionCount = 4,
    this.autoReloadStuck = true,
    this.categoryAutoOrganize = true,
  });

  final bool onboardingComplete;
  final ThemeModePreference themeMode;
  final bool clipboardMonitoringEnabled;
  final String? storageRootPath;
  final String? preferredQuality;
  final String? preferredFormat;
  final String? lastSeenChangelogVersion;
  final bool analyticsEnabled;
  final bool crashReportingEnabled;
  final SpeedLimitConfig speedLimitConfig;
  final SchedulerConfig schedulerConfig;
  final int defaultConnectionCount;
  final bool autoReloadStuck;
  final bool categoryAutoOrganize;

  AppSettings copyWith({
    bool? onboardingComplete,
    ThemeModePreference? themeMode,
    bool? clipboardMonitoringEnabled,
    String? storageRootPath,
    Object? preferredQuality = _unset,
    Object? preferredFormat = _unset,
    Object? lastSeenChangelogVersion = _unset,
    bool? analyticsEnabled,
    bool? crashReportingEnabled,
    SpeedLimitConfig? speedLimitConfig,
    SchedulerConfig? schedulerConfig,
    int? defaultConnectionCount,
    bool? autoReloadStuck,
    bool? categoryAutoOrganize,
  }) {
    return AppSettings(
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      themeMode: themeMode ?? this.themeMode,
      clipboardMonitoringEnabled:
          clipboardMonitoringEnabled ?? this.clipboardMonitoringEnabled,
      storageRootPath: storageRootPath ?? this.storageRootPath,
      preferredQuality: identical(preferredQuality, _unset)
          ? this.preferredQuality
          : preferredQuality as String?,
      preferredFormat: identical(preferredFormat, _unset)
          ? this.preferredFormat
          : preferredFormat as String?,
      lastSeenChangelogVersion: identical(lastSeenChangelogVersion, _unset)
          ? this.lastSeenChangelogVersion
          : lastSeenChangelogVersion as String?,
      analyticsEnabled: analyticsEnabled ?? this.analyticsEnabled,
      crashReportingEnabled:
          crashReportingEnabled ?? this.crashReportingEnabled,
      speedLimitConfig: speedLimitConfig ?? this.speedLimitConfig,
      schedulerConfig: schedulerConfig ?? this.schedulerConfig,
      defaultConnectionCount:
          defaultConnectionCount ?? this.defaultConnectionCount,
      autoReloadStuck: autoReloadStuck ?? this.autoReloadStuck,
      categoryAutoOrganize: categoryAutoOrganize ?? this.categoryAutoOrganize,
    );
  }
}

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return AppSettings(
      onboardingComplete: prefs.getBool(_onboardingKey) ?? false,
      themeMode: _readThemeMode(prefs),
      clipboardMonitoringEnabled: prefs.getBool(_clipboardKey) ?? true,
      storageRootPath: prefs.getString(_storagePathKey),
      preferredQuality: prefs.getString(_preferredQualityKey),
      preferredFormat: prefs.getString(_preferredFormatKey),
      lastSeenChangelogVersion: prefs.getString(_changelogVersionKey),
      analyticsEnabled: prefs.getBool(_analyticsEnabledKey) ?? true,
      crashReportingEnabled: prefs.getBool(_crashReportingKey) ?? true,
      speedLimitConfig: SpeedLimitConfig(
        enabled: prefs.getBool(_speedLimitEnabledKey) ?? false,
        limitBytesPerSec: prefs.getInt(_speedLimitBytesKey) ?? 0,
        scheduledLimit: ScheduledSpeedLimit(
          enabled: prefs.getBool(_scheduledLimitEnabledKey) ?? false,
          daytimeLimitBytesPerSec: prefs.getInt(_scheduledDayLimitKey) ?? 2 * 1024 * 1024,
          nighttimeLimitBytesPerSec: prefs.getInt(_scheduledNightLimitKey) ?? 0,
          dayStartHour: prefs.getInt(_scheduledDayStartKey) ?? 8,
          nightStartHour: prefs.getInt(_scheduledNightStartKey) ?? 23,
        ),
      ),
      schedulerConfig: SchedulerConfig(
        enabled: prefs.getBool(_schedulerEnabledKey) ?? false,
        startTime: prefs.getString(_schedulerStartTimeKey) ?? '22:00',
        stopTime: prefs.getString(_schedulerStopTimeKey) ?? '06:00',
        maxConcurrentDownloads: prefs.getInt(_schedulerMaxConcurrentKey) ?? 3,
        actionOnCompletion: SchedulerAction.fromStorage(
          prefs.getString(_schedulerActionKey) ?? 'none',
        ),
      ),
      defaultConnectionCount:
          (prefs.getInt(_defaultConnectionCountKey) ?? 4).clamp(1, 8),
      autoReloadStuck: prefs.getBool(_autoReloadStuckKey) ?? true,
      categoryAutoOrganize: prefs.getBool(_categoryAutoOrganizeKey) ?? true,
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_onboardingKey, true);
    await prefs.setString(_changelogVersionKey, latestChangelogVersion);
    state = state.copyWith(
      onboardingComplete: true,
      lastSeenChangelogVersion: latestChangelogVersion,
    );
  }

  Future<void> markChangelogSeen(String version) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_changelogVersionKey, version);
    state = state.copyWith(lastSeenChangelogVersion: version);
  }

  Future<void> setThemeMode(ThemeModePreference mode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeKey, mode.name);
    state = state.copyWith(themeMode: mode);
  }

  Future<void> setClipboardMonitoring(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_clipboardKey, enabled);
    state = state.copyWith(clipboardMonitoringEnabled: enabled);
  }

  Future<void> setPreferredQuality(String? quality) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (quality == null || quality.isEmpty) {
      await prefs.remove(_preferredQualityKey);
    } else {
      await prefs.setString(_preferredQualityKey, quality);
    }
    state = state.copyWith(preferredQuality: quality);
  }

  Future<void> setPreferredFormat(String? format) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (format == null || format.isEmpty) {
      await prefs.remove(_preferredFormatKey);
    } else {
      await prefs.setString(_preferredFormatKey, format);
    }
    state = state.copyWith(preferredFormat: format);
  }

  Future<void> setCrashReportingEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_crashReportingKey, enabled);
    state = state.copyWith(crashReportingEnabled: enabled);
    await ref.read(analyticsServiceProvider).setCollectionEnabled(
          analytics: state.analyticsEnabled,
          crash: enabled,
        );
  }

  Future<void> setAnalyticsEnabled(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_analyticsEnabledKey, enabled);
    state = state.copyWith(analyticsEnabled: enabled);
    await ref.read(analyticsServiceProvider).setCollectionEnabled(
          analytics: enabled,
          crash: state.crashReportingEnabled,
        );
  }

  Future<void> setStorageRootPath(String path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_storagePathKey, path);
    state = state.copyWith(storageRootPath: path);
  }

  Future<void> setSpeedLimitConfig(SpeedLimitConfig config) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_speedLimitEnabledKey, config.enabled);
    await prefs.setInt(_speedLimitBytesKey, config.limitBytesPerSec);
    await prefs.setBool(_scheduledLimitEnabledKey, config.scheduledLimit.enabled);
    await prefs.setInt(_scheduledDayLimitKey, config.scheduledLimit.daytimeLimitBytesPerSec);
    await prefs.setInt(_scheduledNightLimitKey, config.scheduledLimit.nighttimeLimitBytesPerSec);
    await prefs.setInt(_scheduledDayStartKey, config.scheduledLimit.dayStartHour);
    await prefs.setInt(_scheduledNightStartKey, config.scheduledLimit.nightStartHour);
    state = state.copyWith(speedLimitConfig: config);
  }

  Future<void> setSchedulerConfig(SchedulerConfig config) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_schedulerEnabledKey, config.enabled);
    await prefs.setString(_schedulerStartTimeKey, config.startTime);
    await prefs.setString(_schedulerStopTimeKey, config.stopTime);
    await prefs.setInt(_schedulerMaxConcurrentKey, config.maxConcurrentDownloads);
    await prefs.setString(_schedulerActionKey, config.actionOnCompletion.storageValue);
    state = state.copyWith(schedulerConfig: config);
  }

  Future<void> setDefaultConnectionCount(int count) async {
    final clamped = count.clamp(1, 8);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_defaultConnectionCountKey, clamped);
    state = state.copyWith(defaultConnectionCount: clamped);
  }

  Future<void> setAutoReloadStuck(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_autoReloadStuckKey, enabled);
    state = state.copyWith(autoReloadStuck: enabled);
  }

  Future<void> setCategoryAutoOrganize(bool enabled) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_categoryAutoOrganizeKey, enabled);
    state = state.copyWith(categoryAutoOrganize: enabled);
  }

  ThemeModePreference _readThemeMode(SharedPreferences prefs) {
    final value = prefs.getString(_themeKey);
    return ThemeModePreference.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => ThemeModePreference.light,
    );
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final storagePathProvider = Provider<String>((ref) {
  final storedPath = ref.watch(
    settingsProvider.select((settings) => settings.storageRootPath),
  );
  final initializer = ref.watch(appInitializerProvider);
  return storedPath ??
      initializer.storagePaths?.rootPath ??
      ref.watch(defaultStoragePathProvider);
});

AppRouter createAppRouter({
  required bool showOnboarding,
  required String storagePath,
  Future<void> Function()? onInitialize,
  Future<void> Function()? onOnboardingComplete,
  Future<PermissionResult> Function(AppPermission permission)?
      onRequestPermission,
}) {
  return AppRouter(
    showOnboarding: showOnboarding,
    storagePath: storagePath,
    onInitialize: onInitialize,
    onRequestPermission: onRequestPermission,
    onOnboardingComplete: onOnboardingComplete,
  );
}

ThemeMode toFlutterThemeMode(ThemeModePreference preference) {
  return switch (preference) {
    ThemeModePreference.system => ThemeMode.system,
    ThemeModePreference.light => ThemeMode.light,
    ThemeModePreference.dark => ThemeMode.dark,
  };
}
