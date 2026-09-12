/// Configuration for automatic download scheduling.
class SchedulerConfig {
  const SchedulerConfig({
    this.enabled = false,
    this.startTime = '22:00',
    this.stopTime = '06:00',
    this.maxConcurrentDownloads = 3,
    this.actionOnCompletion = SchedulerAction.none,
    this.daysOfWeek = const [0, 1, 2, 3, 4, 5, 6],
    this.autoStartQueue = true,
  });

  final bool enabled;
  final String startTime;
  final String stopTime;
  final int maxConcurrentDownloads;
  final SchedulerAction actionOnCompletion;
  final List<int> daysOfWeek;
  final bool autoStartQueue;

  /// Parses "HH:mm" into hour and minute.
  (int hour, int minute) _parseTime(String time) {
    final parts = time.split(':');
    return (int.tryParse(parts[0]) ?? 0, int.tryParse(parts.last) ?? 0);
  }

  /// Whether the scheduler is currently in its active window.
  bool isInActiveWindow() {
    if (!enabled) return false;
    final now = DateTime.now();
    if (!daysOfWeek.contains(now.weekday % 7)) return false;
    final (startH, startM) = _parseTime(startTime);
    final (stopH, stopM) = _parseTime(stopTime);
    final startMinutes = startH * 60 + startM;
    final stopMinutes = stopH * 60 + stopM;
    final nowMinutes = now.hour * 60 + now.minute;

    if (startMinutes <= stopMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < stopMinutes;
    }
    // Overnight window (e.g. 22:00 → 06:00).
    return nowMinutes >= startMinutes || nowMinutes < stopMinutes;
  }

  SchedulerConfig copyWith({
    bool? enabled,
    String? startTime,
    String? stopTime,
    int? maxConcurrentDownloads,
    SchedulerAction? actionOnCompletion,
    List<int>? daysOfWeek,
    bool? autoStartQueue,
  }) {
    return SchedulerConfig(
      enabled: enabled ?? this.enabled,
      startTime: startTime ?? this.startTime,
      stopTime: stopTime ?? this.stopTime,
      maxConcurrentDownloads:
          maxConcurrentDownloads ?? this.maxConcurrentDownloads,
      actionOnCompletion: actionOnCompletion ?? this.actionOnCompletion,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      autoStartQueue: autoStartQueue ?? this.autoStartQueue,
    );
  }

  Map<String, Object?> toMap() => {
        'enabled': enabled,
        'start_time': startTime,
        'stop_time': stopTime,
        'max_concurrent': maxConcurrentDownloads,
        'action_on_completion': actionOnCompletion.storageValue,
        'days_of_week': daysOfWeek,
        'auto_start_queue': autoStartQueue,
      };

  factory SchedulerConfig.fromMap(Map<String, Object?> map) {
    return SchedulerConfig(
      enabled: (map['enabled'] as bool?) ?? false,
      startTime: (map['start_time'] as String?) ?? '22:00',
      stopTime: (map['stop_time'] as String?) ?? '06:00',
      maxConcurrentDownloads: (map['max_concurrent'] as int?) ?? 3,
      actionOnCompletion: SchedulerAction.fromStorage(
        (map['action_on_completion'] as String?) ?? 'none',
      ),
      daysOfWeek: (map['days_of_week'] as List?)
              ?.map((e) => e as int)
              .toList() ??
          const [0, 1, 2, 3, 4, 5, 6],
      autoStartQueue: (map['auto_start_queue'] as bool?) ?? true,
    );
  }
}

/// Action to perform when the scheduled queue completes.
enum SchedulerAction {
  none('none'),
  closeApp('close_app'),
  sleep('sleep'),
  hibernate('hibernate'),
  shutdown('shutdown');

  const SchedulerAction(this.storageValue);
  final String storageValue;

  static SchedulerAction fromStorage(String value) {
    return SchedulerAction.values.firstWhere(
      (a) => a.storageValue == value,
      orElse: () => SchedulerAction.none,
    );
  }

  String get label => switch (this) {
        SchedulerAction.none => 'Do nothing',
        SchedulerAction.closeApp => 'Close app',
        SchedulerAction.sleep => 'Sleep',
        SchedulerAction.hibernate => 'Hibernate',
        SchedulerAction.shutdown => 'Shut down',
      };
}
