/// Canonical event names — documentation/31_Observability_Analytics.md
abstract final class AnalyticsEvent {
  static const appOpened = 'app_opened';
  static const urlPasted = 'url_pasted';
  static const platformDetected = 'platform_detected';
  static const resolveStarted = 'resolve_started';
  static const resolveSuccess = 'resolve_success';
  static const resolveFailed = 'resolve_failed';
  static const downloadStarted = 'download_started';
  static const downloadPaused = 'download_paused';
  static const downloadResumed = 'download_resumed';
  static const downloadCompleted = 'download_completed';
  static const downloadFailed = 'download_failed';
  static const downloadCancelled = 'download_cancelled';
  static const downloadDeleted = 'download_deleted';
  static const downloadOpened = 'download_opened';
  static const downloadShared = 'download_shared';
  static const settingsOpened = 'settings_opened';
  static const permissionRequested = 'permission_requested';
  static const permissionGranted = 'permission_granted';
  static const permissionDenied = 'permission_denied';
  static const storageWarning = 'storage_warning';
  static const screenViewed = 'screen_viewed';
  static const pasteButtonClicked = 'paste_button_clicked';
  static const downloadButtonClicked = 'download_button_clicked';
  static const qualityChanged = 'quality_changed';
  static const formatChanged = 'format_changed';
  static const pauseClicked = 'pause_clicked';
  static const resumeClicked = 'resume_clicked';
  static const cancelClicked = 'cancel_clicked';
  static const shareClicked = 'share_clicked';
  static const openFileClicked = 'open_file_clicked';
  static const deleteClicked = 'delete_clicked';
}

abstract final class AnalyticsScreen {
  static const home = 'home';
  static const urlInput = 'url_input';
  static const resolution = 'resolution';
  static const mediaSelection = 'media_selection';
  static const downloads = 'downloads';
  static const downloadDetails = 'download_details';
  static const settings = 'settings';
  static const history = 'history';
  static const browser = 'browser';
  static const files = 'files';
  static const search = 'search';
  static const onboarding = 'onboarding';
}

abstract final class AnalyticsProp {
  static const platform = 'platform';
  static const mediaType = 'media_type';
  static const resolution = 'resolution';
  static const downloadId = 'download_id';
  static const downloadStatus = 'download_status';
  static const downloadDuration = 'download_duration';
  static const downloadSpeed = 'download_speed';
  static const fileSize = 'file_size';
  static const retryCount = 'retry_count';
  static const networkType = 'network_type';
  static const errorCategory = 'error_category';
  static const resolverVersion = 'resolver_version';
  static const screen = 'screen';
  static const permission = 'permission';
  static const format = 'format';
  static const quality = 'quality';
}

const kResolverVersion = '1';
