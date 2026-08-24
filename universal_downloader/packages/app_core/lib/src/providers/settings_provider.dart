import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permissions/permissions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_types/shared_types.dart';

import '../bootstrap/app_initializer.dart';
import '../navigation/app_router.dart';

const _unset = Object();

const _onboardingKey = 'onboarding_complete';
const _themeKey = 'theme_mode';
const _clipboardKey = 'clipboard_monitoring';
const _storagePathKey = 'storage_root_path';
const _preferredQualityKey = 'preferred_quality';
const _preferredFormatKey = 'preferred_format';

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
  });

  final bool onboardingComplete;
  final ThemeModePreference themeMode;
  final bool clipboardMonitoringEnabled;
  final String? storageRootPath;
  final String? preferredQuality;
  final String? preferredFormat;

  AppSettings copyWith({
    bool? onboardingComplete,
    ThemeModePreference? themeMode,
    bool? clipboardMonitoringEnabled,
    String? storageRootPath,
    Object? preferredQuality = _unset,
    Object? preferredFormat = _unset,
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
    );
  }

  Future<void> completeOnboarding() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_onboardingKey, true);
    state = state.copyWith(onboardingComplete: true);
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

  Future<void> setStorageRootPath(String path) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_storagePathKey, path);
    state = state.copyWith(storageRootPath: path);
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
