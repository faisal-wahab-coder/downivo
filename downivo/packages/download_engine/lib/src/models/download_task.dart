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

  int get bytesRemaining {
    final total = fileSize;
    if (total == null || total <= 0) return 0;
    return (total - bytesReceived).clamp(0, total);
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
    );
  }
}
