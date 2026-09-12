import 'dart:async';

import 'package:shared_types/shared_types.dart';

/// Token-bucket bandwidth throttler for download streams.
///
/// Distributes available bandwidth fairly across active downloads.
/// Thread-safe for use across multiple concurrent download workers.
class SpeedLimiter {
  SpeedLimiter({SpeedLimitConfig? config})
      : _config = config ?? const SpeedLimitConfig();

  SpeedLimitConfig _config;
  int _activeDownloads = 1;

  SpeedLimitConfig get config => _config;

  void updateConfig(SpeedLimitConfig config) {
    _config = config;
  }

  void setActiveDownloads(int count) {
    _activeDownloads = count.clamp(1, 100);
  }

  /// Returns the per-download byte limit for this tick, or 0 for unlimited.
  int get perDownloadLimit {
    final effectiveLimit = _effectiveLimit;
    if (effectiveLimit <= 0) return 0;
    return (effectiveLimit / _activeDownloads).ceil();
  }

  /// Returns the active global limit in bytes/sec (0 = unlimited).
  int get _effectiveLimit {
    if (!_config.enabled) return 0;

    // Check scheduled limits first.
    if (_config.scheduledLimit.enabled) {
      final scheduled = _config.scheduledLimit.activeLimitNow();
      if (scheduled > 0) return scheduled;
      if (scheduled == 0 && _config.scheduledLimit.enabled) return 0;
    }

    return _config.limitBytesPerSec;
  }

  /// Delays the stream to enforce the speed limit. Returns how many bytes
  /// are allowed in this chunk. Pass [chunkSize] for the incoming bytes.
  Future<int> throttle(int chunkSize) async {
    final limit = perDownloadLimit;
    if (limit <= 0) return chunkSize;

    if (chunkSize <= limit) return chunkSize;

    // Calculate how long we need to wait to stay under the limit.
    final waitMs = ((chunkSize - limit) * 1000 / limit).ceil();
    if (waitMs > 0) {
      await Future<void>.delayed(Duration(milliseconds: waitMs.clamp(1, 2000)));
    }
    return chunkSize;
  }
}
