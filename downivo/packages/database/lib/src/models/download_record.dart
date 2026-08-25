/// Download row model — maps to docs/13.6_Download_Database_Schema.md
class DownloadRecord {
  const DownloadRecord({
    required this.id,
    required this.url,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.domain,
    this.fileName = '',
    this.filePath,
    this.fileSize,
    this.mimeType,
    this.priority = 'NORMAL',
    this.progress = 0,
    this.startedAt,
    this.completedAt,
    this.thumbnailUrl,
    this.platform,
    this.title,
  });

  final String id;
  final String url;
  final String? domain;
  final String fileName;
  final String? filePath;
  final int? fileSize;
  final String? mimeType;
  final String status;
  final String priority;
  final double progress;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime updatedAt;
  final String? thumbnailUrl;
  final String? platform;
  final String? title;

  Map<String, Object?> toMap() => {
    'id': id,
    'url': url,
    'domain': domain,
    'file_name': fileName,
    'file_path': filePath,
    'file_size': fileSize,
    'mime_type': mimeType,
    'status': status,
    'priority': priority,
    'progress': progress,
    'created_at': createdAt.toIso8601String(),
    'started_at': startedAt?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'thumbnail_url': thumbnailUrl,
    'platform': platform,
    'title': title,
  };

  factory DownloadRecord.fromMap(Map<String, Object?> map) {
    return DownloadRecord(
      id: map['id']! as String,
      url: map['url']! as String,
      domain: map['domain'] as String?,
      fileName: map['file_name'] as String? ?? '',
      filePath: map['file_path'] as String?,
      fileSize: map['file_size'] as int?,
      mimeType: map['mime_type'] as String?,
      status: map['status']! as String,
      priority: map['priority'] as String? ?? 'NORMAL',
      progress: (map['progress'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.parse(map['created_at']! as String),
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at']! as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at']! as String)
          : null,
      updatedAt: DateTime.parse(map['updated_at']! as String),
      thumbnailUrl: map['thumbnail_url'] as String?,
      platform: map['platform'] as String?,
      title: map['title'] as String?,
    );
  }
}
