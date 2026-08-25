import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

import 'analytics_config.dart';
import 'analytics_platform.dart';
import 'firebase_bootstrap.dart';

class PerformanceTraces {
  const PerformanceTraces();

  Future<TraceHandle> start(String name) async {
    if (!FirebaseBootstrap.available) return const TraceHandle._noop();
    try {
      final trace = FirebasePerformance.instance.newTrace(name);
      await trace.start();
      return TraceHandle._(trace);
    } on Object {
      return const TraceHandle._noop();
    }
  }
}

class TraceHandle {
  const TraceHandle._(this._trace);
  const TraceHandle._noop() : _trace = null;

  final Trace? _trace;

  Future<void> stop() async {
    final trace = _trace;
    if (trace == null) return;
    try {
      await trace.stop();
    } on Object {
      // Ignore.
    }
  }
}

class RemoteConfigClient {
  RemoteAppConfig current = RemoteAppConfig.defaults;

  Future<RemoteAppConfig> fetch() async {
    if (!FirebaseBootstrap.available) return current;
    try {
      final remote = FirebaseRemoteConfig.instance;
      await remote.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );
      await remote.setDefaults(_defaults());
      await remote.fetchAndActivate();
      current = _read(remote);
    } on Object {
      current = RemoteAppConfig.defaults;
    }
    return current;
  }

  Map<String, Object> _defaults() {
    final map = <String, Object>{
      RemoteConfigKeys.maintenanceMode: false,
      RemoteConfigKeys.maxConcurrentDownloads: 3,
      RemoteConfigKeys.defaultQuality: '',
    };
    for (final key in RemoteConfigKeys.resolverFlags.values) {
      map[key] = true;
    }
    return map;
  }

  RemoteAppConfig _read(FirebaseRemoteConfig remote) {
    final enabled = <String, bool>{};
    for (final entry in RemoteConfigKeys.resolverFlags.entries) {
      enabled[entry.key] = remote.getBool(entry.value);
    }
    final quality = remote.getString(RemoteConfigKeys.defaultQuality);
    return RemoteAppConfig(
      maintenanceMode: remote.getBool(RemoteConfigKeys.maintenanceMode),
      maxConcurrentDownloads: remote
          .getInt(RemoteConfigKeys.maxConcurrentDownloads)
          .clamp(1, 8),
      defaultQuality: quality.isEmpty ? null : quality,
      resolverEnabled: enabled,
    );
  }

  static String? disabledResolverMessage(String platform) {
    if (!AnalyticsPlatform.all.contains(platform)) return null;
    return 'This source is temporarily unavailable. Try again later.';
  }
}
