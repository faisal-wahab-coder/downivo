import 'package:analytics/analytics.dart';
import 'package:download_engine/download_engine.dart';

class EngineAnalyticsBridge extends DownloadEngineTelemetry {
  EngineAnalyticsBridge(this._analytics);

  final AnalyticsService _analytics;

  Map<String, Object?> _base({
    required String downloadId,
    String? platform,
    String? mediaType,
  }) {
    return {
      AnalyticsProp.downloadId: downloadId,
      if (platform != null)
        AnalyticsProp.platform: AnalyticsPlatform.fromSocialName(platform),
      if (mediaType != null)
        AnalyticsProp.mediaType: mediaTypeFromKind(null, mimeType: mediaType),
    };
  }

  @override
  void downloadStarted({
    required String downloadId,
    String? platform,
    String? mediaType,
  }) {
    _analytics.setLastAction('StartDownload');
    _analytics.setDownloadContext(
      platform: platform == null
          ? null
          : AnalyticsPlatform.fromSocialName(platform),
      mediaType: mediaType,
      downloadState: 'downloading',
    );
    _analytics.track(
      AnalyticsEvent.downloadStarted,
      _base(downloadId: downloadId, platform: platform, mediaType: mediaType),
    );
  }

  @override
  void downloadPaused({required String downloadId, String? platform}) {
    _analytics.setLastAction('PauseDownload');
    _analytics.track(
      AnalyticsEvent.downloadPaused,
      _base(downloadId: downloadId, platform: platform),
    );
  }

  @override
  void downloadResumed({required String downloadId, String? platform}) {
    _analytics.setLastAction('ResumeDownload');
    _analytics.track(
      AnalyticsEvent.downloadResumed,
      _base(downloadId: downloadId, platform: platform),
    );
  }

  @override
  void downloadCompleted({
    required String downloadId,
    String? platform,
    String? mediaType,
    int? durationMs,
    int? fileSizeBytes,
    int? speedBytesPerSec,
    int retryCount = 0,
  }) {
    _analytics.setDownloadContext(downloadState: 'completed');
    _analytics.track(AnalyticsEvent.downloadCompleted, {
      ..._base(
        downloadId: downloadId,
        platform: platform,
        mediaType: mediaType,
      ),
      AnalyticsProp.downloadStatus: 'completed',
      AnalyticsProp.retryCount: retryCount,
      if (durationMs != null) AnalyticsProp.downloadDuration: durationMs,
      if (fileSizeBytes != null)
        AnalyticsProp.fileSize: fileSizeBucket(fileSizeBytes),
      if (speedBytesPerSec != null && speedBytesPerSec > 0)
        AnalyticsProp.downloadSpeed: speedBytesPerSec,
    });
  }

  @override
  void downloadFailed({
    required String downloadId,
    String? platform,
    String? mediaType,
    String? errorMessage,
    int retryCount = 0,
  }) {
    _analytics.setDownloadContext(downloadState: 'failed');
    _analytics.track(AnalyticsEvent.downloadFailed, {
      ..._base(
        downloadId: downloadId,
        platform: platform,
        mediaType: mediaType,
      ),
      AnalyticsProp.downloadStatus: 'failed',
      AnalyticsProp.retryCount: retryCount,
      AnalyticsProp.errorCategory: ErrorCategory.fromMessage(
        errorMessage,
      ).wireValue,
    });
    _analytics.logger.error(
      'Download failed',
      fields: {
        AnalyticsProp.downloadId: downloadId,
        AnalyticsProp.errorCategory: ErrorCategory.fromMessage(
          errorMessage,
        ).wireValue,
      },
    );
  }

  @override
  void downloadCancelled({required String downloadId, String? platform}) {
    _analytics.track(
      AnalyticsEvent.downloadCancelled,
      _base(downloadId: downloadId, platform: platform),
    );
  }

  @override
  void resolveStarted({required String platform, String? mediaType}) {
    _analytics.setLastAction('Resolve');
    _analytics.track(AnalyticsEvent.resolveStarted, {
      AnalyticsProp.platform: AnalyticsPlatform.fromSocialName(platform),
      AnalyticsProp.resolverVersion: kResolverVersion,
      if (mediaType != null) AnalyticsProp.mediaType: mediaType,
    });
  }

  @override
  void resolveSuccess({
    required String platform,
    String? mediaType,
    int? durationMs,
  }) {
    _analytics.track(AnalyticsEvent.resolveSuccess, {
      AnalyticsProp.platform: AnalyticsPlatform.fromSocialName(platform),
      AnalyticsProp.resolverVersion: kResolverVersion,
      if (mediaType != null)
        AnalyticsProp.mediaType: mediaTypeFromKind(null, mimeType: mediaType),
      if (durationMs != null) AnalyticsProp.downloadDuration: durationMs,
    });
  }

  @override
  void resolveFailed({
    required String platform,
    String? mediaType,
    String? errorMessage,
  }) {
    _analytics.track(AnalyticsEvent.resolveFailed, {
      AnalyticsProp.platform: AnalyticsPlatform.fromSocialName(platform),
      AnalyticsProp.resolverVersion: kResolverVersion,
      AnalyticsProp.errorCategory: ErrorCategory.fromMessage(
        errorMessage,
      ).wireValue,
      if (mediaType != null) AnalyticsProp.mediaType: mediaType,
    });
  }

  @override
  void log({
    required String level,
    required String message,
    Map<String, Object?> fields = const {},
  }) {
    final mapped = switch (level) {
      'debug' => LogLevel.debug,
      'warning' => LogLevel.warning,
      'error' => LogLevel.error,
      'fatal' => LogLevel.fatal,
      _ => LogLevel.info,
    };
    _analytics.logger.log(mapped, message, fields: fields);
  }
}
