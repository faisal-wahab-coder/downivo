/// Status of an individual download segment (connection thread).
enum SegmentStatus {
  idle('IDLE'),
  downloading('DOWNLOADING'),
  completed('COMPLETED'),
  failed('FAILED');

  const SegmentStatus(this.storageValue);
  final String storageValue;

  static SegmentStatus fromStorage(String value) {
    return SegmentStatus.values.firstWhere(
      (s) => s.storageValue == value,
      orElse: () => SegmentStatus.idle,
    );
  }
}

/// A single byte-range segment of a multi-connection download.
class DownloadSegment {
  const DownloadSegment({
    required this.id,
    required this.startByte,
    required this.endByte,
    this.downloadedBytes = 0,
    this.speed = 0,
    this.status = SegmentStatus.idle,
  });

  final int id;
  final int startByte;
  final int endByte;
  final int downloadedBytes;
  final int speed;
  final SegmentStatus status;

  int get totalBytes => endByte - startByte + 1;

  double get progress =>
      totalBytes > 0 ? (downloadedBytes / totalBytes).clamp(0.0, 1.0) : 0.0;

  bool get isCompleted => downloadedBytes >= totalBytes;

  DownloadSegment copyWith({
    int? downloadedBytes,
    int? speed,
    SegmentStatus? status,
  }) {
    return DownloadSegment(
      id: id,
      startByte: startByte,
      endByte: endByte,
      downloadedBytes: downloadedBytes ?? this.downloadedBytes,
      speed: speed ?? this.speed,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toMap() => {
        'id': id,
        'start_byte': startByte,
        'end_byte': endByte,
        'downloaded_bytes': downloadedBytes,
        'speed': speed,
        'status': status.storageValue,
      };

  factory DownloadSegment.fromMap(Map<String, Object?> map) {
    return DownloadSegment(
      id: map['id']! as int,
      startByte: map['start_byte']! as int,
      endByte: map['end_byte']! as int,
      downloadedBytes: (map['downloaded_bytes'] as int?) ?? 0,
      speed: (map['speed'] as int?) ?? 0,
      status: SegmentStatus.fromStorage(
        (map['status'] as String?) ?? 'IDLE',
      ),
    );
  }

  /// Creates N evenly-divided segments for a given file size.
  static List<DownloadSegment> createSegments(
    int totalBytes,
    int connectionCount,
  ) {
    if (totalBytes <= 0 || connectionCount <= 1) {
      return [
        DownloadSegment(
          id: 0,
          startByte: 0,
          endByte: totalBytes > 0 ? totalBytes - 1 : 0,
        ),
      ];
    }

    final chunkSize = (totalBytes / connectionCount).ceil();
    final segments = <DownloadSegment>[];

    for (var i = 0; i < connectionCount; i++) {
      final start = i * chunkSize;
      final end = (start + chunkSize - 1).clamp(0, totalBytes - 1);
      if (start >= totalBytes) break;
      segments.add(DownloadSegment(id: i, startByte: start, endByte: end));
    }

    return segments;
  }
}
