import 'package:flutter/foundation.dart';

/// Session context copied onto Crashlytics keys and event properties.
class AnalyticsContext {
  String? screen;
  String? lastAction;
  String? platform;
  String? mediaType;
  String? downloadState;
  String? networkType;
  String? appVersion;
  String? buildNumber;
  String? androidVersion;
  String? manufacturer;
  String? model;
  String? cpuAbi;

  Map<String, String> crashlyticsKeys() {
    final keys = <String, String>{};
    void put(String name, String? value) {
      if (value != null && value.isNotEmpty) keys[name] = value;
    }

    put('app_version', appVersion);
    put('build_number', buildNumber);
    put('platform', platform);
    put('media_type', mediaType);
    put('download_state', downloadState);
    put('network_type', networkType);
    put('screen', screen);
    put('last_action', lastAction);
    put('android_version', androidVersion);
    put('device_manufacturer', manufacturer);
    put('device_model', model);
    put('cpu_architecture', cpuAbi);
    put('debug', kDebugMode.toString());
    return keys;
  }

  Map<String, Object> eventDefaults() {
    final map = <String, Object>{};
    void put(String name, String? value) {
      if (value != null && value.isNotEmpty) map[name] = value;
    }

    put('app_version', appVersion);
    put('network_type', networkType);
    put('screen', screen);
    put('android_version', androidVersion);
    return map;
  }
}
