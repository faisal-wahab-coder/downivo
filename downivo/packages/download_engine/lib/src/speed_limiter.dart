import 'dart:math' as math;

import 'package:shared_types/shared_types.dart';

/// Token-bucket bandwidth cap shared by every active connection.
///
/// When the limit is off, [isActive] is false and callers must not await
/// [acquire]. That keeps the download loop from yielding on every chunk.
class SpeedLimiter {
  SpeedLimiter({
    SpeedLimitConfig? config,
    DateTime Function()? clock,
    Future<void> Function(Duration delay)? delay,
  }) : _config = config ?? const SpeedLimitConfig(),
       _clock = clock,
       _delay = delay;

  SpeedLimitConfig _config;
  final DateTime Function()? _clock;
  final Future<void> Function(Duration delay)? _delay;

  double _tokens = 0;
  int? _lastRefillMicros;

  SpeedLimitConfig get config => _config;

  /// True only when a positive byte cap is currently in force.
  bool get isActive => _effectiveLimit > 0;

  void updateConfig(SpeedLimitConfig config) {
    _config = config;
    _tokens = 0;
    _lastRefillMicros = null;
  }

  /// Blocks until [byteCount] bytes fit the current cap.
  ///
  /// Returns immediately when limiting is off. Prefer checking [isActive]
  /// before awaiting so an unlimited download does not yield per chunk.
  Future<void> acquire(int byteCount) {
    if (byteCount <= 0 || !isActive) return Future<void>.value();
    return _waitForTokens(byteCount);
  }

  Future<void> _waitForTokens(int byteCount) async {
    var remaining = byteCount.toDouble();
    while (remaining > 0) {
      final limit = _effectiveLimit;
      if (limit <= 0) return;
      _refill(limit);
      if (_tokens > 0) {
        final take = math.min(_tokens, remaining);
        _tokens -= take;
        remaining -= take;
        if (remaining <= 0) return;
      }
      final need = math.min(remaining, limit.toDouble());
      final waitMs = (need * 1000 / limit).ceil().clamp(1, 200);
      await _sleep(Duration(milliseconds: waitMs));
    }
  }

  void _refill(int limitBytesPerSec) {
    final now = _now().microsecondsSinceEpoch;
    final last = _lastRefillMicros;
    if (last == null) {
      _lastRefillMicros = now;
      _tokens = limitBytesPerSec.toDouble();
      return;
    }
    final elapsed = now - last;
    if (elapsed <= 0) return;
    _tokens += limitBytesPerSec * elapsed / 1000000;
    final cap = limitBytesPerSec.toDouble();
    if (_tokens > cap) _tokens = cap;
    _lastRefillMicros = now;
  }

  /// Active global limit in bytes/sec. 0 means unlimited.
  int get _effectiveLimit {
    if (!_config.enabled) return 0;

    if (_config.scheduledLimit.enabled) {
      final scheduled = _config.scheduledLimit.activeLimitNow();
      if (scheduled > 0) return scheduled;
      return 0;
    }

    return _config.limitBytesPerSec;
  }

  DateTime _now() => _clock?.call() ?? DateTime.now();

  Future<void> _sleep(Duration duration) {
    final delay = _delay;
    if (delay != null) return delay(duration);
    return Future<void>.delayed(duration);
  }
}
