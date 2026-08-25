/// Optional engine callbacks. Default is no-op so tests stay vendor-free.
class DownloadEngineTelemetry {
  const DownloadEngineTelemetry();

  void downloadStarted({
    required String downloadId,
    String? platform,
    String? mediaType,
  }) {}

  void downloadPaused({
    required String downloadId,
    String? platform,
  }) {}

  void downloadResumed({
    required String downloadId,
    String? platform,
  }) {}

  void downloadCompleted({
    required String downloadId,
    String? platform,
    String? mediaType,
    int? durationMs,
    int? fileSizeBytes,
    int? speedBytesPerSec,
    int retryCount = 0,
  }) {}

  void downloadFailed({
    required String downloadId,
    String? platform,
    String? mediaType,
    String? errorMessage,
    int retryCount = 0,
  }) {}

  void downloadCancelled({
    required String downloadId,
    String? platform,
  }) {}

  void resolveStarted({
    required String platform,
    String? mediaType,
  }) {}

  void resolveSuccess({
    required String platform,
    String? mediaType,
    int? durationMs,
  }) {}

  void resolveFailed({
    required String platform,
    String? mediaType,
    String? errorMessage,
  }) {}

  void log({
    required String level,
    required String message,
    Map<String, Object?> fields = const {},
  }) {}
}
