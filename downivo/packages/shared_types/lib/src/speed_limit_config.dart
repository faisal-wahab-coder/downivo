/// Configuration for bandwidth throttling.
class SpeedLimitConfig {
  const SpeedLimitConfig({
    this.enabled = false,
    this.limitBytesPerSec = 0,
    this.scheduledLimit = const ScheduledSpeedLimit(),
  });

  final bool enabled;

  /// 0 = unlimited.
  final int limitBytesPerSec;

  final ScheduledSpeedLimit scheduledLimit;

  SpeedLimitConfig copyWith({
    bool? enabled,
    int? limitBytesPerSec,
    ScheduledSpeedLimit? scheduledLimit,
  }) {
    return SpeedLimitConfig(
      enabled: enabled ?? this.enabled,
      limitBytesPerSec: limitBytesPerSec ?? this.limitBytesPerSec,
      scheduledLimit: scheduledLimit ?? this.scheduledLimit,
    );
  }

  Map<String, Object?> toMap() => {
        'enabled': enabled,
        'limit_bytes_per_sec': limitBytesPerSec,
        'scheduled_limit': scheduledLimit.toMap(),
      };

  factory SpeedLimitConfig.fromMap(Map<String, Object?> map) {
    return SpeedLimitConfig(
      enabled: (map['enabled'] as bool?) ?? false,
      limitBytesPerSec: (map['limit_bytes_per_sec'] as int?) ?? 0,
      scheduledLimit: map['scheduled_limit'] is Map
          ? ScheduledSpeedLimit.fromMap(
              Map<String, Object?>.from(map['scheduled_limit'] as Map))
          : const ScheduledSpeedLimit(),
    );
  }
}

/// Day/night scheduled speed limits.
class ScheduledSpeedLimit {
  const ScheduledSpeedLimit({
    this.enabled = false,
    this.daytimeLimitBytesPerSec = 2 * 1024 * 1024,
    this.nighttimeLimitBytesPerSec = 0,
    this.dayStartHour = 8,
    this.nightStartHour = 23,
  });

  final bool enabled;
  final int daytimeLimitBytesPerSec;

  /// 0 = unlimited at night.
  final int nighttimeLimitBytesPerSec;
  final int dayStartHour;
  final int nightStartHour;

  /// Returns the active limit for the current time of day (0 = unlimited).
  int activeLimitNow() {
    if (!enabled) return 0;
    final hour = DateTime.now().hour;
    if (hour >= dayStartHour && hour < nightStartHour) {
      return daytimeLimitBytesPerSec;
    }
    return nighttimeLimitBytesPerSec;
  }

  ScheduledSpeedLimit copyWith({
    bool? enabled,
    int? daytimeLimitBytesPerSec,
    int? nighttimeLimitBytesPerSec,
    int? dayStartHour,
    int? nightStartHour,
  }) {
    return ScheduledSpeedLimit(
      enabled: enabled ?? this.enabled,
      daytimeLimitBytesPerSec:
          daytimeLimitBytesPerSec ?? this.daytimeLimitBytesPerSec,
      nighttimeLimitBytesPerSec:
          nighttimeLimitBytesPerSec ?? this.nighttimeLimitBytesPerSec,
      dayStartHour: dayStartHour ?? this.dayStartHour,
      nightStartHour: nightStartHour ?? this.nightStartHour,
    );
  }

  Map<String, Object?> toMap() => {
        'enabled': enabled,
        'daytime_limit': daytimeLimitBytesPerSec,
        'nighttime_limit': nighttimeLimitBytesPerSec,
        'day_start_hour': dayStartHour,
        'night_start_hour': nightStartHour,
      };

  factory ScheduledSpeedLimit.fromMap(Map<String, Object?> map) {
    return ScheduledSpeedLimit(
      enabled: (map['enabled'] as bool?) ?? false,
      daytimeLimitBytesPerSec: (map['daytime_limit'] as int?) ?? 2 * 1024 * 1024,
      nighttimeLimitBytesPerSec: (map['nighttime_limit'] as int?) ?? 0,
      dayStartHour: (map['day_start_hour'] as int?) ?? 8,
      nightStartHour: (map['night_start_hour'] as int?) ?? 23,
    );
  }
}
