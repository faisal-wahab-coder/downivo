import 'models/download_task.dart';

/// Configuration for stall/slow-speed detection.
class StallDetectorConfig {
  const StallDetectorConfig({
    this.autoReloadStuck = true,
    this.stuckTimeoutSeconds = 8,
    this.slowSpeedThresholdKB = 25,
  });

  final bool autoReloadStuck;
  final int stuckTimeoutSeconds;
  final int slowSpeedThresholdKB;

  int get slowSpeedThresholdBytes => slowSpeedThresholdKB * 1024;
}

/// Tracks download speed and detects stalled/slow connections.
class StallDetector {
  StallDetector({this.config = const StallDetectorConfig()});

  StallDetectorConfig config;

  final _zeroSpeedStart = <String, DateTime>{};

  /// Evaluates the current speed and returns an updated task with
  /// isStuck / isSlow / stuckDurationSecs set accordingly.
  DownloadTask evaluate(DownloadTask task, int currentSpeed) {
    if (currentSpeed <= 0) {
      final start = _zeroSpeedStart.putIfAbsent(task.id, DateTime.now);
      final stuckSecs = DateTime.now().difference(start).inSeconds;
      return task.copyWith(
        isStuck: stuckSecs >= config.stuckTimeoutSeconds,
        isSlow: false,
        stuckDurationSecs: stuckSecs,
      );
    }

    // Speed is nonzero — clear stuck tracking.
    _zeroSpeedStart.remove(task.id);

    final isSlow = currentSpeed > 0 && currentSpeed < config.slowSpeedThresholdBytes;
    return task.copyWith(
      isStuck: false,
      isSlow: isSlow,
      stuckDurationSecs: 0,
    );
  }

  /// Whether the given task should be auto-reloaded based on stall state.
  bool shouldAutoReload(DownloadTask task) {
    if (!config.autoReloadStuck) return false;
    return task.isStuck &&
        task.stuckDurationSecs >= config.stuckTimeoutSeconds;
  }

  /// Clear tracking for a task (e.g. after reload or completion).
  void clear(String taskId) {
    _zeroSpeedStart.remove(taskId);
  }
}
