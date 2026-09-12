import 'package:shared_types/shared_types.dart';

/// Active download task exposed to UI and services.
class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.url,
    required this.fileName,
    required this.status,
    required this.progress,
    required this.createdAt,
    required this.updatedAt,
    this.filePath,
    this.fileSize,
    this.mimeType,
    this.bytesReceived = 0,
    this.speedBytesPerSec = 0,
    this.errorMessage,
    this.priority = DownloadPriority.normal,
    this.thumbnailUrl,
    this.platform,
    this.title,
    this.connectionCount = 1,
    this.segments = const [],
    this.isStuck = false,
    this.isSlow = false,
    this.stuckDurationSecs = 0,
    this.reloadCount = 0,
    this.checksumSha256,
    this.checksumMd5,
  });

  final String id;
  final String url;
  final String fileName;
  final String? filePath;
  final int? fileSize;
  final String? mimeType;
  final DownloadStatus status;
  final double progress;
  final int bytesReceived;
  final int speedBytesPerSec;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? errorMessage;
  final DownloadPriority priority;
  final String? thumbnailUrl;
  final String? platform;
  final String? title;

  /// Number of parallel connections for this download.
  final int connectionCount;

  /// Per-segment progress state (empty for single-connection downloads).
  final List<DownloadSegment> segments;

  /// Whether the download is currently stalled at 0 speed.
  final bool isStuck;

  /// Whether the download speed is below the slow threshold.
  final bool isSlow;

  /// How many seconds the download has been stuck at 0 speed.
  final int stuckDurationSecs;

  /// How many times connections have been reloaded.
  final int reloadCount;

  /// SHA-256 checksum computed after completion.
  final String? checksumSha256;

  /// MD5 checksum computed after completion.
  final String? checksumMd5;

  int get bytesRemaining {
    final total = fileSize;
    if (total == null || total <= 0) return 0;
    return (total - bytesReceived).clamp(0, total);
  }

  Duration get eta {
    if (speedBytesPerSec <= 0) return Duration.zero;
    return Duration(seconds: (bytesRemaining / speedBytesPerSec).ceil());
  }

  bool get isActive =>
      status == DownloadStatus.downloading ||
      status == DownloadStatus.preparing ||
      status == DownloadStatus.queued ||
      status == DownloadStatus.verifying;

  bool get hasManagedFile => filePath != null && filePath!.trim().isNotEmpty;

  /// Completed download whose library file was deleted in Files.
  bool get isRemovedFromLibrary =>
      status == DownloadStatus.completed && !hasManagedFile;

  /// Whether the server supports multi-segment (Range) downloads.
  bool get supportsMultiSegment => connectionCount > 1 && segments.isNotEmpty;

  DownloadTask copyWith({
    String? fileName,
    DownloadStatus? status,
    double? progress,
    String? filePath,
    bool clearFilePath = false,
    int? fileSize,
    String? mimeType,
    int? bytesReceived,
    int? speedBytesPerSec,
    String? errorMessage,
    DownloadPriority? priority,
    DateTime? updatedAt,
    String? thumbnailUrl,
    String? platform,
    String? title,
    int? connectionCount,
    List<DownloadSegment>? segments,
    bool? isStuck,
    bool? isSlow,
    int? stuckDurationSecs,
    int? reloadCount,
    String? checksumSha256,
    String? checksumMd5,
  }) {
    return DownloadTask(
      id: id,
      url: url,
      fileName: fileName ?? this.fileName,
      filePath: clearFilePath ? null : (filePath ?? this.filePath),
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      speedBytesPerSec: speedBytesPerSec ?? this.speedBytesPerSec,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      priority: priority ?? this.priority,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      platform: platform ?? this.platform,
      title: title ?? this.title,
      connectionCount: connectionCount ?? this.connectionCount,
      segments: segments ?? this.segments,
      isStuck: isStuck ?? this.isStuck,
      isSlow: isSlow ?? this.isSlow,
      stuckDurationSecs: stuckDurationSecs ?? this.stuckDurationSecs,
      reloadCount: reloadCount ?? this.reloadCount,
      checksumSha256: checksumSha256 ?? this.checksumSha256,
      checksumMd5: checksumMd5 ?? this.checksumMd5,
    );
  }
}
