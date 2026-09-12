import 'dart:async';

import 'package:dio/dio.dart';
import 'package:shared_types/shared_types.dart';
import 'package:storage/storage.dart';

import 'speed_limiter.dart';

/// Callback providing per-segment progress updates.
typedef SegmentProgressCallback = void Function(
  int segmentId,
  int downloadedBytes,
  int speed,
  SegmentStatus status,
);

/// Downloads a single byte-range segment to a temporary file.
class SegmentDownloadWorker {
  SegmentDownloadWorker({
    required this.segment,
    required this.url,
    required this.headers,
    required this.dio,
    required this.fileStore,
    required this.segmentFilePath,
    this.speedLimiter,
    this.onProgress,
  });

  final DownloadSegment segment;
  final String url;
  final Map<String, String> headers;
  final Dio dio;
  final FileStore fileStore;
  final String segmentFilePath;
  final SpeedLimiter? speedLimiter;
  final SegmentProgressCallback? onProgress;

  CancelToken? _cancelToken;
  bool _cancelled = false;

  /// Begins downloading this segment. Returns total bytes downloaded.
  Future<int> start() async {
    if (_cancelled) return 0;
    _cancelToken = CancelToken();

    var existingBytes = 0;
    if (await fileStore.exists(segmentFilePath)) {
      existingBytes = await fileStore.length(segmentFilePath);
      if (existingBytes >= segment.totalBytes) {
        onProgress?.call(
          segment.id,
          segment.totalBytes,
          0,
          SegmentStatus.completed,
        );
        return segment.totalBytes;
      }
    }

    final startByte = segment.startByte + existingBytes;
    final rangeHeader = 'bytes=$startByte-${segment.endByte}';
    final requestHeaders = {
      ...headers,
      'Range': rangeHeader,
    };

    final response = await dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        headers: requestHeaders,
        validateStatus: (status) =>
            status != null && (status == 200 || status == 206),
      ),
      cancelToken: _cancelToken,
    );

    final sink = fileStore.openWrite(segmentFilePath, append: existingBytes > 0);
    var downloaded = existingBytes;
    var lastTick = DateTime.now();
    var lastBytes = downloaded;

    try {
      await for (final chunk in response.data!.stream) {
        if (_cancelled) break;

        // Apply speed limiting if configured.
        if (speedLimiter != null) {
          await speedLimiter!.throttle(chunk.length);
        }

        sink.add(chunk);
        downloaded += chunk.length;

        final now = DateTime.now();
        final elapsed = now.difference(lastTick).inMilliseconds;
        var speed = 0;
        if (elapsed >= 500) {
          speed = ((downloaded - lastBytes) * 1000 / elapsed).round();
          lastTick = now;
          lastBytes = downloaded;
        }

        onProgress?.call(
          segment.id,
          downloaded,
          speed,
          downloaded >= segment.totalBytes
              ? SegmentStatus.completed
              : SegmentStatus.downloading,
        );
      }
    } finally {
      await sink.flush();
      await sink.close();
    }

    if (downloaded >= segment.totalBytes) {
      onProgress?.call(
        segment.id,
        segment.totalBytes,
        0,
        SegmentStatus.completed,
      );
    }

    return downloaded;
  }

  void cancel() {
    _cancelled = true;
    _cancelToken?.cancel('segment_cancelled');
  }
}

/// Merges multiple segment temp files into a single output file.
Future<void> mergeSegmentFiles({
  required FileStore fileStore,
  required String outputPath,
  required List<String> segmentPaths,
}) async {
  final sink = fileStore.openWrite(outputPath);
  try {
    for (final segPath in segmentPaths) {
      if (await fileStore.exists(segPath)) {
        final bytes = await fileStore.readBytes(segPath);
        sink.add(bytes);
      }
    }
  } finally {
    await sink.flush();
    await sink.close();
  }

  // Clean up temp segment files.
  for (final segPath in segmentPaths) {
    try {
      if (await fileStore.exists(segPath)) {
        await fileStore.delete(segPath);
      }
    } on Object {
      // Best-effort cleanup.
    }
  }
}

/// Checks whether the server supports Range requests via a HEAD probe.
Future<bool> probeRangeSupport(Dio dio, String url) async {
  try {
    final response = await dio.head<void>(
      url,
      options: Options(
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final acceptRanges = response.headers.value('accept-ranges');
    return acceptRanges != null && acceptRanges.toLowerCase() != 'none';
  } on Object {
    return false;
  }
}

/// Returns the total content length from a HEAD request, or null.
Future<int?> probeContentLength(Dio dio, String url) async {
  try {
    final response = await dio.head<void>(
      url,
      options: Options(
        followRedirects: true,
        validateStatus: (status) => status != null && status < 400,
      ),
    );
    final cl = response.headers.value('content-length');
    return cl != null ? int.tryParse(cl) : null;
  } on Object {
    return null;
  }
}
