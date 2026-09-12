import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:performance/performance.dart';
import 'package:shared_types/shared_types.dart';
import 'package:storage/storage.dart';
import 'package:uuid/uuid.dart';

import 'content_providers/content_provider_registry.dart';
import 'content_providers/dailymotion_cdn_http.dart';
import 'content_providers/dailymotion_resolver.dart';
import 'content_providers/dailymotion_uri.dart';
import 'content_providers/facebook_resolver.dart';
import 'content_providers/hls_fmp4_stitcher.dart';
import 'content_providers/instagram_graphql_resolver.dart';
import 'content_providers/social_http_headers.dart';
import 'content_providers/social_platform.dart';
import 'content_providers/social_url_utils.dart';
import 'content_providers/snapchat_resolver.dart';
import 'content_providers/telegram_resolver.dart';
import 'content_providers/threads_resolver.dart';
import 'content_providers/whatsapp_resolver.dart';
import 'content_providers/twitch_resolver.dart';
import 'download_engine_telemetry.dart';
import 'download_error_formatter.dart';
import 'download_repository.dart';
import 'filename_resolver.dart';
import 'models/download_task.dart';
import 'range_response_parser.dart';
import 'speed_limiter.dart';
import 'stall_detector.dart';
import 'web_request_proxy.dart';

typedef DownloadProgressCallback = void Function(DownloadTask task);

/// Default number of parallel connections for multi-segment downloads.
const kDefaultConnectionCount = 4;

/// Minimum file size (in bytes) to use multi-segment downloads (1 MB).
const kMinSegmentFileSize = 1024 * 1024;

/// Orchestrates validation, queueing, execution, and persistence.
class DownloadManager {
  DownloadManager({
    required DownloadRepository repository,
    required StoragePaths storagePaths,
    FileStore? fileStore,
    Dio? dio,
    ContentProviderRegistry? contentProviders,
    this.maxConcurrent = 3,
    this.maxRetries = 3,
    this.telemetry = const DownloadEngineTelemetry(),
    int defaultConnectionCount = kDefaultConnectionCount,
  }) : _repository = repository,
       _storagePaths = storagePaths,
       _fileStore = fileStore ?? createFileStore(),
       _dio = dio ?? Dio(),
       _uuid = const Uuid(),
       _defaultConnectionCount = defaultConnectionCount {
    attachWebRequestProxy(_dio);
    _contentProviders = contentProviders ?? ContentProviderRegistry(dio: _dio);
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 30);
  }

  final DownloadRepository _repository;
  final StoragePaths _storagePaths;
  final FileStore _fileStore;
  final Dio _dio;
  late final ContentProviderRegistry _contentProviders;
  final Uuid _uuid;
  int maxConcurrent;
  final int maxRetries;
  final DownloadEngineTelemetry telemetry;
  int _defaultConnectionCount;

  /// Speed limiter for bandwidth throttling.
  final speedLimiter = SpeedLimiter();

  /// Stall/slow-speed detector.
  final stallDetector = StallDetector();

  final _tasks = <String, DownloadTask>{};
  final _cancelTokens = <String, CancelToken>{};
  final _cancelledIds = <String>{};
  final _runningIds = <String>{};
  final _retryCounts = <String, int>{};
  final _queueOrder = <String>[];
  final _requestHeaders = <String, Map<String, String>>{};
  final _downloadStartedAt = <String, DateTime>{};
  final _progressController = StreamController<List<DownloadTask>>.broadcast();
  final _emitGate = ThrottleGate(interval: const Duration(milliseconds: 250));

  int get defaultConnectionCount => _defaultConnectionCount;
  set defaultConnectionCount(int value) {
    _defaultConnectionCount = value.clamp(1, 16);
  }

  Stream<List<DownloadTask>> get tasksStream => _progressController.stream;
  List<DownloadTask> get tasks {
    final list = _tasks.values.toList();
    list.sort((a, b) {
      final aQueued = a.status == DownloadStatus.queued;
      final bQueued = b.status == DownloadStatus.queued;
      if (aQueued && bQueued) {
        return _queueIndex(a.id).compareTo(_queueIndex(b.id));
      }
      return b.updatedAt.compareTo(a.updatedAt);
    });
    return list;
  }

  DownloadTask? get primaryActiveTask {
    final downloading = _tasks.values
        .where((t) => t.status == DownloadStatus.downloading)
        .toList();
    if (downloading.isNotEmpty) return downloading.first;
    final queued = _queuedTasksSorted();
    return queued.isEmpty ? null : queued.first;
  }

  Future<void> loadFromDatabase() async {
    final stored = await _repository.getAll();
    _tasks.clear();

    for (final task in stored) {
      var recovered = _recoverInterruptedTask(task);
      recovered = await _hydrateBytesFromDisk(recovered);
      _tasks[recovered.id] = recovered;
      if (recovered.status != task.status) {
        await _repository.update(recovered);
      }
    }

    _queueOrder
      ..clear()
      ..addAll(await _repository.getQueueOrder());
    _syncQueueOrderWithTasks();

    _emit();
    unawaited(_processQueue());
  }

  DownloadTask _recoverInterruptedTask(DownloadTask task) {
    if (task.status == DownloadStatus.downloading ||
        task.status == DownloadStatus.preparing ||
        task.status == DownloadStatus.verifying) {
      return task.copyWith(
        status: DownloadStatus.queued,
        updatedAt: DateTime.now(),
      );
    }
    if (task.status == DownloadStatus.paused) {
      return task;
    }
    return task;
  }

  Future<DownloadTask> enqueue(
    String url, {
    String? fileName,
    DownloadPriority priority = DownloadPriority.normal,
    String? thumbnailUrl,
    String? platform,
    String? title,
    String? mimeType,
    Map<String, String>? requestHeaders,
  }) async {
    final validator = UrlValidator();
    final result = validator.validate(url);
    if (!result.isValid || result.uri == null) {
      throw ArgumentError(result.errorMessage ?? 'Invalid URL');
    }

    final uri = result.uri!;
    final now = DateTime.now();
    final resolvedName = fileName?.trim().isNotEmpty == true
        ? FileNameResolver.sanitize(fileName!.trim())
        : validator.fileNameFromUrl(uri);
    final task = DownloadTask(
      id: _uuid.v4(),
      url: uri.toString(),
      fileName: resolvedName.isNotEmpty ? resolvedName : 'download_pending',
      status: DownloadStatus.queued,
      progress: 0,
      priority: priority,
      createdAt: now,
      updatedAt: now,
      thumbnailUrl: thumbnailUrl,
      platform: platform,
      title: title,
      mimeType: mimeType,
    );

    _tasks[task.id] = task;
    if (requestHeaders != null && requestHeaders.isNotEmpty) {
      _requestHeaders[task.id] = requestHeaders;
    }
    _queueOrder.add(task.id);
    await _repository.save(task);
    await _persistQueueOrder();
    _emit();
    unawaited(_processQueue());
    return task;
  }

  void setMaxConcurrent(int value) {
    maxConcurrent = value.clamp(1, 8);
    unawaited(_processQueue());
  }

  Future<void> reorderQueue(List<String> orderedQueuedIds) async {
    final queuedIds = _tasks.values
        .where((t) => t.status == DownloadStatus.queued)
        .map((t) => t.id)
        .toSet();
    if (orderedQueuedIds.length != queuedIds.length) return;
    if (!orderedQueuedIds.every(queuedIds.contains)) return;

    _queueOrder
      ..removeWhere(queuedIds.contains)
      ..insertAll(0, orderedQueuedIds);
    await _persistQueueOrder();
    _emit();
  }

  Future<void> setPriority(String id, DownloadPriority priority) async {
    final task = _tasks[id];
    if (task == null) return;
    await _updateTask(
      task.copyWith(priority: priority, updatedAt: DateTime.now()),
    );
    unawaited(_processQueue());
  }

  /// Drops the managed path after Files deletes the file. The download row stays.
  Future<void> detachLibraryFile(String path) async {
    if (path.isEmpty) return;
    final now = DateTime.now();
    var changed = false;
    for (final task in _tasks.values.toList()) {
      if (task.filePath != path) continue;
      _tasks[task.id] = task.copyWith(clearFilePath: true, updatedAt: now);
      changed = true;
    }
    await _repository.clearFilePath(path);
    if (changed) _emit();
  }

  Future<void> pauseAll() async {
    final downloading = _tasks.values
        .where((t) => t.status == DownloadStatus.downloading)
        .map((t) => t.id)
        .toList();
    for (final id in downloading) {
      await pause(id);
    }
  }

  Future<void> resumeAll() async {
    final paused = _tasks.values
        .where((t) => t.status == DownloadStatus.paused)
        .map((t) => t.id)
        .toList();
    for (final id in paused) {
      await resume(id);
    }
  }

  Future<void> pause(String id) async {
    final task = _tasks[id];
    if (task == null) return;
    _cancelTokens[id]?.cancel('paused');
    final bytesReceived = await _bytesOnDisk(task);
    final fileSize = task.fileSize;
    await _updateTask(
      task.copyWith(
        status: DownloadStatus.paused,
        bytesReceived: bytesReceived,
        progress: fileSize != null && fileSize > 0
            ? (bytesReceived / fileSize).clamp(0, 1)
            : task.progress,
        updatedAt: DateTime.now(),
      ),
    );
    telemetry.downloadPaused(downloadId: id, platform: task.platform);
    unawaited(_processQueue());
  }

  Future<void> resume(String id) async {
    final task = _tasks[id];
    if (task == null || task.status != DownloadStatus.paused) return;
    final bytesReceived = await _bytesOnDisk(task);
    final fileSize = task.fileSize;
    await _updateTask(
      task.copyWith(
        status: DownloadStatus.queued,
        bytesReceived: bytesReceived,
        progress: fileSize != null && fileSize > 0
            ? (bytesReceived / fileSize).clamp(0, 1)
            : task.progress,
        errorMessage: null,
        updatedAt: DateTime.now(),
      ),
    );
    telemetry.downloadResumed(downloadId: id, platform: task.platform);
    unawaited(_processQueue());
  }

  Future<void> cancel(String id) async {
    _cancelledIds.add(id);
    _retryCounts.remove(id);
    _cancelTokens[id]?.cancel('cancelled');
    final task = _tasks[id];
    if (task == null) {
      _emit();
      return;
    }

    final path = task.filePath;
    if (path != null) {
      try {
        if (await _fileStore.exists(path)) {
          await _fileStore.delete(path);
        }
      } on Object {
        // Cancel still succeeds if the partial file cannot be deleted.
      }
    }

    final cancelled = task.copyWith(
      status: DownloadStatus.cancelled,
      updatedAt: DateTime.now(),
    );
    _tasks.remove(id);
    _queueOrder.remove(id);
    _requestHeaders.remove(id);
    _downloadStartedAt.remove(id);
    await _repository.update(cancelled);
    await _persistQueueOrder();
    telemetry.downloadCancelled(downloadId: id, platform: task.platform);
    _emit();
    unawaited(_processQueue());
  }

  /// Reloads connections for a stuck/slow download without losing progress.
  /// Cancels the current transfer and re-queues to restart from the last byte.
  Future<void> reloadConnections(String id) async {
    final task = _tasks[id];
    if (task == null) return;
    if (task.status != DownloadStatus.downloading) return;

    _cancelTokens[id]?.cancel('reload');
    stallDetector.clear(id);

    final bytesReceived = await _bytesOnDisk(task);
    final fileSize = task.fileSize;
    await _updateTask(
      task.copyWith(
        status: DownloadStatus.queued,
        bytesReceived: bytesReceived,
        progress: fileSize != null && fileSize > 0
            ? (bytesReceived / fileSize).clamp(0, 1)
            : task.progress,
        isStuck: false,
        isSlow: false,
        stuckDurationSecs: 0,
        reloadCount: task.reloadCount + 1,
        errorMessage: null,
        updatedAt: DateTime.now(),
      ),
    );
    unawaited(_processQueue());
  }

  /// Reloads all currently stuck downloads.
  Future<void> reloadAllStuck() async {
    final stuckIds = _tasks.values
        .where((t) => t.status == DownloadStatus.downloading && t.isStuck)
        .map((t) => t.id)
        .toList();
    for (final id in stuckIds) {
      await reloadConnections(id);
    }
  }

  Future<void> retry(String id) async {
    _cancelledIds.remove(id);
    _retryCounts[id] = 0;
    final task = _tasks[id];
    if (task == null) return;
    final bytesReceived = await _bytesOnDisk(task);
    final fileSize = task.fileSize;
    await _updateTask(
      task.copyWith(
        status: DownloadStatus.queued,
        bytesReceived: bytesReceived,
        progress: fileSize != null && fileSize > 0
            ? (bytesReceived / fileSize).clamp(0, 1)
            : 0,
        errorMessage: null,
        updatedAt: DateTime.now(),
      ),
    );
    unawaited(_processQueue());
  }

  Future<void> _processQueue() async {
    final activeCount = _tasks.values
        .where((t) => t.status == DownloadStatus.downloading)
        .length;
    speedLimiter.setActiveDownloads(activeCount.clamp(1, 100));
    if (activeCount >= maxConcurrent) return;

    final next = _queuedTasksSorted();
    final slots = maxConcurrent - activeCount;
    var started = 0;
    for (final task in next) {
      if (started >= slots) break;
      if (_isAbandoned(task.id)) continue;
      if (_runningIds.contains(task.id)) continue;
      _runningIds.add(task.id);
      started++;
      unawaited(_runDownload(task));
    }
  }

  bool _isAbandoned(String id) {
    if (_cancelledIds.contains(id)) return true;
    final current = _tasks[id];
    if (current == null) return true;
    return current.status == DownloadStatus.cancelled ||
        current.status == DownloadStatus.paused;
  }

  Future<void> _runDownload(DownloadTask task) async {
    if (_isAbandoned(task.id)) {
      _runningIds.remove(task.id);
      return;
    }
    final cancelToken = CancelToken();
    _cancelTokens[task.id] = cancelToken;
    FileStoreSink? sink;

    try {
      await _updateTask(
        task.copyWith(
          status: DownloadStatus.downloading,
          updatedAt: DateTime.now(),
        ),
      );
      _downloadStartedAt.putIfAbsent(task.id, DateTime.now);
      telemetry.downloadStarted(
        downloadId: task.id,
        platform: task.platform,
        mediaType: task.mimeType,
      );
      if (_isAbandoned(task.id)) return;

      final uri = Uri.parse(task.url);
      var downloadUrl = task.url;
      var resolvedPreferredName = task.fileName == 'download_pending'
          ? null
          : task.fileName;
      Map<String, String> extraHeaders = Map<String, String>.from(
        _requestHeaders[task.id] ?? const {},
      );

      if (ContentProviderRegistry.canHandle(uri) &&
          !SnapchatUri.isDirectMediaHost(uri.host) &&
          !HlsFmp4Stitcher.isPlaylistUrl(task.url)) {
        final platformName = SocialPlatform.fromUri(uri)?.name ?? 'unknown';
        telemetry.resolveStarted(platform: platformName);
        final resolveWatch = Stopwatch()..start();
        try {
          final discovered = await _contentProviders.discover(uri);
          resolveWatch.stop();
          if (_isAbandoned(task.id)) return;
          if (discovered == null) {
            telemetry.resolveFailed(
              platform: platformName,
              errorMessage: _socialMediaErrorMessage(uri),
            );
            final errorMsg = _socialMediaErrorMessage(uri);
            await _handleFailure(
              task,
              errorMsg,
              retryable: !_isPermanentSocialFailure(uri, errorMsg),
            );
            return;
          }
          downloadUrl = discovered.directUrl;
          resolvedPreferredName = discovered.fileName;
          extraHeaders = {...extraHeaders, ...?discovered.requestHeaders};
          telemetry.resolveSuccess(
            platform: platformName,
            mediaType: discovered.mimeType,
            durationMs: resolveWatch.elapsedMilliseconds,
          );
          final latest = _tasks[task.id];
          if (latest == null || _isAbandoned(task.id)) return;
          await _updateTask(
            latest.copyWith(
              fileName: discovered.fileName,
              updatedAt: DateTime.now(),
            ),
          );
        } on ArgumentError catch (error) {
          telemetry.resolveFailed(
            platform: platformName,
            errorMessage: error.message?.toString(),
          );
          await _handleFailure(
            task,
            error.message?.toString() ?? 'Invalid download request.',
            retryable: false,
          );
          return;
        } on DioException catch (error) {
          telemetry.resolveFailed(
            platform: platformName,
            errorMessage: DownloadErrorFormatter.fromDio(error),
          );
          await _handleFailure(
            task,
            DownloadErrorFormatter.fromDio(error),
            retryable: !DownloadErrorFormatter.isPermanent(error),
          );
          return;
        }
      }

      var existingBytes = await _bytesOnDisk(task);
      final platform =
          SocialPlatform.fromUri(uri) ??
          (task.platform == SocialPlatform.dailymotion.label
              ? SocialPlatform.dailymotion
              : null);
      final headerPageUrl =
          platform == SocialPlatform.dailymotion &&
              !DailymotionUri.isHost(uri.host)
          ? Uri.parse('https://www.dailymotion.com/')
          : uri;
      var downloadHeaders = {
        ...SocialHttpHeaders.forMediaDownload(
          pageUrl: headerPageUrl,
          mediaUrl: downloadUrl,
          platform: platform,
        ),
        ...extraHeaders,
        if (existingBytes > 0 && !HlsFmp4Stitcher.isPlaylistUrl(downloadUrl))
          'Range': RangeResponseParser.rangeHeaderFor(existingBytes),
      };
      if (kIsWeb && !WebRequestProxy.isEnabled) {
        downloadHeaders = SocialHttpHeaders.withoutCorsUnsafeHeaders(
          downloadHeaders,
        );
      }

      telemetry.log(
        level: 'info',
        message: 'Download transfer started',
        fields: {
          'downloadId': task.id,
          'host': Uri.tryParse(downloadUrl)?.host,
          'platform': task.platform,
        },
      );
      if (_isAbandoned(task.id)) return;

      if (_shouldStitchDailymotionHls(task, uri, downloadUrl)) {
        await _downloadDailymotionHls(
          task: task,
          downloadUrl: downloadUrl,
          preferredName: resolvedPreferredName,
          headers: downloadHeaders,
          cancelToken: cancelToken,
        );
        return;
      }
      var response = await _dio.get<ResponseBody>(
        downloadUrl,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          headers: downloadHeaders,
          validateStatus: (status) =>
              status != null &&
              (status == 200 || status == 206 || status == 416),
        ),
        cancelToken: cancelToken,
      );

      // 416 = Range not satisfiable. Clear partial file and retry without Range.
      if (response.statusCode == 416) {
        final path = task.filePath;
        if (path != null) {
          if (await _fileStore.exists(path)) {
            await _fileStore.writeBytes(path, const []);
          }
        }
        existingBytes = 0;
        downloadHeaders.remove('Range');
        final retryResponse = await _dio.get<ResponseBody>(
          downloadUrl,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: true,
            headers: downloadHeaders,
            validateStatus: (status) =>
                status != null && (status == 200 || status == 206),
          ),
          cancelToken: cancelToken,
        );
        // Continue with retry response below.
        response = retryResponse;
      }

      final statusCode = response.statusCode ?? 200;
      final contentType = response.headers.value('content-type');
      final contentRange = response.headers.value('content-range');
      final fileName = FileNameResolver.resolve(
        uri: Uri.parse(downloadUrl),
        preferredName: resolvedPreferredName,
        contentDisposition: response.headers.value('content-disposition'),
        contentType: contentType,
      );
      final category = _categoryForMime(contentType, fileName);
      final dirPath = _storagePaths.categoryPath(category);
      if (!await _fileStore.directoryExists(dirPath)) {
        await _fileStore.createDirectory(dirPath);
      }

      final filePath = task.filePath ?? p.join(dirPath, fileName);

      if (statusCode == 206) {
        if (!await _fileStore.exists(filePath)) {
          await _fileStore.writeBytes(filePath, const []);
          existingBytes = 0;
        }
      } else if (existingBytes > 0) {
        // Server did not honor Range — restart from scratch.
        if (await _fileStore.exists(filePath)) {
          await _fileStore.writeBytes(filePath, const []);
        }
        existingBytes = 0;
      }

      final totalBytes = statusCode == 206
          ? RangeResponseParser.totalBytesFromContentRange(contentRange) ??
                task.fileSize ??
                _totalBytesFromHeaders(response, existingBytes)
          : _totalBytesFromHeaders(response, existingBytes);

      sink = _fileStore.openWrite(filePath, append: existingBytes > 0);

      var received = existingBytes;
      var lastTick = DateTime.now();
      var lastReceived = received;
      var workingTask = task.copyWith(
        status: DownloadStatus.downloading,
        fileName: fileName,
        filePath: filePath,
        fileSize: totalBytes,
        mimeType: contentType,
        bytesReceived: received,
        progress: totalBytes != null && totalBytes > 0
            ? received / totalBytes
            : task.progress,
      );

      await for (final chunk in response.data!.stream) {
        // Apply speed limiter throttling.
        await speedLimiter.throttle(chunk.length);

        sink.add(chunk);
        received += chunk.length;
        final now = DateTime.now();
        final elapsed = now.difference(lastTick).inMilliseconds;
        var speed = 0;
        if (elapsed >= 500) {
          speed = ((received - lastReceived) * 1000 / elapsed).round();
          lastTick = now;
          lastReceived = received;
        }
        final total = totalBytes ?? received;
        final progress = total > 0 ? received / total : 0.0;
        workingTask = workingTask.copyWith(
          progress: progress.clamp(0, 1),
          bytesReceived: received,
          speedBytesPerSec: speed,
          updatedAt: now,
        );
        // Evaluate stall/slow status.
        workingTask = stallDetector.evaluate(workingTask, speed);
        await _updateTask(workingTask, persist: false);
      }

      await sink.flush();
      await sink.close();
      sink = null;

      final verified = await _verifyDownload(workingTask, received);
      if (!verified) {
        await _handleFailure(workingTask, 'File integrity check failed');
        return;
      }

      _queueOrder.remove(task.id);
      _requestHeaders.remove(task.id);
      stallDetector.clear(task.id);
      await _persistQueueOrder();

      await _updateTask(
        workingTask.copyWith(
          status: DownloadStatus.completed,
          progress: 1,
          bytesReceived: received,
          fileSize: totalBytes ?? received,
          isStuck: false,
          isSlow: false,
          stuckDurationSecs: 0,
          updatedAt: DateTime.now(),
        ),
      );
      _emitDownloadCompleted(
        task,
        bytes: totalBytes ?? received,
        speed: workingTask.speedBytesPerSec,
      );
    } on DioException catch (error) {
      if (CancelToken.isCancel(error)) {
        return;
      }
      telemetry.log(
        level: 'error',
        message: 'Download DioException',
        fields: {
          'downloadId': task.id,
          'type': error.type.name,
          'status': error.response?.statusCode,
          'platform': task.platform,
        },
      );
      await _handleFailure(
        task,
        DownloadErrorFormatter.fromDio(error),
        retryable: !DownloadErrorFormatter.isPermanent(error),
      );
    } on Object catch (error) {
      telemetry.log(
        level: 'error',
        message: 'Download failed',
        fields: {
          'downloadId': task.id,
          'errorType': error.runtimeType.toString(),
          'platform': task.platform,
        },
      );
      await _handleFailure(task, DownloadErrorFormatter.fromObject(error));
    } finally {
      if (sink != null) {
        await sink.close();
      }
      _cancelTokens.remove(task.id);
      _runningIds.remove(task.id);
      unawaited(_processQueue());
    }
  }

  bool _shouldStitchDailymotionHls(
    DownloadTask task,
    Uri taskUri,
    String downloadUrl,
  ) {
    if (!HlsFmp4Stitcher.isPlaylistUrl(downloadUrl)) return false;
    if (task.platform == SocialPlatform.dailymotion.label) return true;
    if (SocialPlatform.fromUri(taskUri) == SocialPlatform.dailymotion) {
      return true;
    }
    final host = Uri.tryParse(downloadUrl)?.host ?? '';
    return DailymotionUri.isHost(host) || DailymotionUri.isCdnHost(host);
  }

  Future<void> _downloadDailymotionHls({
    required DownloadTask task,
    required String downloadUrl,
    required String? preferredName,
    required Map<String, String> headers,
    required CancelToken cancelToken,
  }) async {
    final stitchHeaders = DailymotionCdnHttp.withoutCookie(
      DailymotionResolver.streamHeaders(downloadUrl),
    );
    final stitchDio = Dio()
      ..options.connectTimeout = const Duration(seconds: 30)
      ..options.receiveTimeout = const Duration(minutes: 10);
    attachWebRequestProxy(stitchDio);
    final fileName = FileNameResolver.resolve(
      uri: Uri.parse(downloadUrl),
      preferredName: preferredName,
      contentType: 'video/mp4',
    );
    final mp4Name = fileName.toLowerCase().endsWith('.mp4')
        ? fileName
        : '${FileNameResolver.sanitize(fileName.replaceAll(RegExp(r'\.[^.]+$'), ''))}.mp4';
    final category = StorageCategory.videos;
    final dirPath = _storagePaths.categoryPath(category);
    if (!await _fileStore.directoryExists(dirPath)) {
      await _fileStore.createDirectory(dirPath);
    }
    final filePath = task.filePath ?? p.join(dirPath, mp4Name);
    if (await _fileStore.exists(filePath)) {
      await _fileStore.writeBytes(filePath, const []);
    }

    final sink = _fileStore.openWrite(filePath);
    var received = 0;
    var lastTick = DateTime.now();
    var lastReceived = 0;
    var workingTask = task.copyWith(
      status: DownloadStatus.downloading,
      fileName: mp4Name,
      filePath: filePath,
      mimeType: 'video/mp4',
      bytesReceived: 0,
      progress: 0,
      updatedAt: DateTime.now(),
    );
    await _updateTask(workingTask);

    try {
      received = await HlsFmp4Stitcher(dio: stitchDio).stitch(
        playlistUrl: downloadUrl,
        add: sink.add,
        headers: stitchHeaders,
        cancelToken: cancelToken,
        onProgress: (bytes, done, total) async {
          if (_isAbandoned(task.id)) return;
          final now = DateTime.now();
          final elapsed = now.difference(lastTick).inMilliseconds;
          var speed = 0;
          if (elapsed >= 500) {
            speed = ((bytes - lastReceived) * 1000 / elapsed).round();
            lastTick = now;
            lastReceived = bytes;
          }
          final progress = total > 0 ? done / total : 0.0;
          workingTask = workingTask.copyWith(
            progress: progress.clamp(0, 1),
            bytesReceived: bytes,
            speedBytesPerSec: speed,
            updatedAt: now,
          );
          await _updateTask(workingTask, persist: false);
        },
      );
    } finally {
      stitchDio.close(force: true);
      await sink.flush();
      await sink.close();
    }

    if (_isAbandoned(task.id)) return;

    workingTask = workingTask.copyWith(
      bytesReceived: received,
      fileSize: received,
      progress: 1,
      mimeType: 'video/mp4',
    );
    final verified = await _verifyDownload(workingTask, received);
    if (!verified) {
      await _handleFailure(workingTask, 'File integrity check failed');
      return;
    }

    _queueOrder.remove(task.id);
    _requestHeaders.remove(task.id);
    await _persistQueueOrder();
    await _updateTask(
      workingTask.copyWith(
        status: DownloadStatus.completed,
        progress: 1,
        bytesReceived: received,
        fileSize: received,
        updatedAt: DateTime.now(),
      ),
    );
    _emitDownloadCompleted(task, bytes: received, speed: workingTask.speedBytesPerSec);
  }

  int? _totalBytesFromHeaders(
    Response<ResponseBody> response,
    int existingBytes,
  ) {
    final contentLength = int.tryParse(
      response.headers.value('content-length') ?? '',
    );
    if (contentLength == null) return null;
    return existingBytes > 0 ? existingBytes + contentLength : contentLength;
  }

  Future<bool> _verifyDownload(DownloadTask task, int receivedBytes) async {
    await _updateTask(
      task.copyWith(
        status: DownloadStatus.verifying,
        updatedAt: DateTime.now(),
      ),
      persist: false,
    );

    final path = task.filePath;
    if (path == null) return true;
    if (!await _fileStore.exists(path)) return false;

    final size = await _fileStore.length(path);
    if (size != receivedBytes) return false;

    final expected = task.fileSize;
    if (expected != null && expected > 0 && size != expected) {
      return false;
    }
    return true;
  }

  List<DownloadTask> _queuedTasksSorted() {
    final queued = _tasks.values
        .where((t) => t.status == DownloadStatus.queued)
        .toList();
    queued.sort((a, b) {
      final orderCompare = _queueIndex(a.id).compareTo(_queueIndex(b.id));
      if (orderCompare != 0) return orderCompare;
      final priorityCompare = _priorityWeight(
        b.priority,
      ).compareTo(_priorityWeight(a.priority));
      if (priorityCompare != 0) return priorityCompare;
      return a.createdAt.compareTo(b.createdAt);
    });
    return queued;
  }

  int _queueIndex(String id) {
    final index = _queueOrder.indexOf(id);
    return index >= 0 ? index : _queueOrder.length;
  }

  int _priorityWeight(DownloadPriority priority) => switch (priority) {
    DownloadPriority.urgent => 4,
    DownloadPriority.high => 3,
    DownloadPriority.normal => 2,
    DownloadPriority.low => 1,
  };

  void _syncQueueOrderWithTasks() {
    final queuedIds = _tasks.values
        .where((t) => t.status == DownloadStatus.queued)
        .map((t) => t.id)
        .toSet();
    _queueOrder.removeWhere((id) => !queuedIds.contains(id));
    for (final id in queuedIds) {
      if (!_queueOrder.contains(id)) _queueOrder.add(id);
    }
  }

  Future<void> _persistQueueOrder() async {
    _syncQueueOrderWithTasks();
    await _repository.saveQueueOrder(List.unmodifiable(_queueOrder));
  }

  Future<int> _bytesOnDisk(DownloadTask task) async {
    final path = task.filePath;
    if (path == null) return task.bytesReceived;
    if (!await _fileStore.exists(path)) return 0;
    return _fileStore.length(path);
  }

  Future<DownloadTask> _hydrateBytesFromDisk(DownloadTask task) async {
    final bytes = await _bytesOnDisk(task);
    if (bytes <= 0) return task;
    final fileSize = task.fileSize;
    return task.copyWith(
      bytesReceived: bytes,
      progress: fileSize != null && fileSize > 0
          ? (bytes / fileSize).clamp(0, 1)
          : task.progress,
    );
  }

  bool _isPermanentSocialFailure(Uri uri, String message) {
    final platform = SocialPlatform.fromUri(uri);
    if (platform == SocialPlatform.telegram) {
      if (TelegramUri.isRestricted(uri) || !TelegramUri.isDownloadable(uri)) {
        return true;
      }
      final lower = message.toLowerCase();
      return lower.contains('restricted') ||
          lower.contains('authentication') ||
          lower.contains('unavailable') ||
          lower.contains('text-only');
    }
    if (platform == SocialPlatform.snapchat) {
      if (SnapchatUri.isRestricted(uri) ||
          SnapchatUri.requiresAuthentication(uri) ||
          !SnapchatUri.isDownloadable(uri)) {
        return true;
      }
      final lower = message.toLowerCase();
      return lower.contains('restricted') ||
          lower.contains('authentication') ||
          lower.contains('unavailable') ||
          lower.contains('expired') ||
          lower.contains('hls-only');
    }
    if (platform == SocialPlatform.threads) {
      if (ThreadsUri.requiresAuthentication(uri) ||
          !ThreadsUri.isDownloadable(uri)) {
        return true;
      }
      final lower = message.toLowerCase();
      return lower.contains('restricted') ||
          lower.contains('authentication') ||
          lower.contains('unavailable') ||
          lower.contains('no downloadable media') ||
          lower.contains('hls-only');
    }
    if (platform == SocialPlatform.whatsapp) {
      if (WhatsAppUri.isRestricted(uri) ||
          WhatsAppUri.requiresAuthentication(uri) ||
          !WhatsAppUri.isDownloadable(uri)) {
        return true;
      }
      final lower = message.toLowerCase();
      return lower.contains('restricted') ||
          lower.contains('authentication') ||
          lower.contains('unavailable') ||
          lower.contains('not a downloadable') ||
          lower.contains('group invitation') ||
          lower.contains('does not expose');
    }
    return false;
  }

  Future<void> _handleFailure(
    DownloadTask task,
    String message, {
    bool retryable = true,
  }) async {
    if (_isAbandoned(task.id)) return;
    if (!retryable) {
      await _updateTask(
        task.copyWith(
          status: DownloadStatus.failed,
          errorMessage: message,
          updatedAt: DateTime.now(),
        ),
      );
      _emitDownloadFailed(task, message);
      return;
    }

    final attempts = (_retryCounts[task.id] ?? 0) + 1;
    _retryCounts[task.id] = attempts;

    if (attempts <= maxRetries) {
      final bytesReceived = await _bytesOnDisk(task);
      final fileSize = task.fileSize;
      await _updateTask(
        task.copyWith(
          status: DownloadStatus.queued,
          bytesReceived: bytesReceived,
          progress: fileSize != null && fileSize > 0
              ? (bytesReceived / fileSize).clamp(0, 1)
              : task.progress,
          errorMessage: message,
          updatedAt: DateTime.now(),
        ),
      );
      unawaited(_processQueue());
      return;
    }

    await _updateTask(
      task.copyWith(
        status: DownloadStatus.failed,
        errorMessage: message,
        updatedAt: DateTime.now(),
      ),
    );
    _emitDownloadFailed(task, message);
  }

  void _emitDownloadCompleted(
    DownloadTask task, {
    required int bytes,
    required int speed,
  }) {
    final started = _downloadStartedAt.remove(task.id);
    telemetry.downloadCompleted(
      downloadId: task.id,
      platform: task.platform,
      mediaType: task.mimeType,
      durationMs: started == null
          ? null
          : DateTime.now().difference(started).inMilliseconds,
      fileSizeBytes: bytes,
      speedBytesPerSec: speed,
      retryCount: _retryCounts[task.id] ?? 0,
    );
  }

  void _emitDownloadFailed(DownloadTask task, String message) {
    _downloadStartedAt.remove(task.id);
    telemetry.downloadFailed(
      downloadId: task.id,
      platform: task.platform,
      mediaType: task.mimeType,
      errorMessage: message,
      retryCount: _retryCounts[task.id] ?? 0,
    );
  }

  String _socialMediaErrorMessage(Uri uri) {
    final platform = SocialPlatform.fromUri(uri);
    final label = ContentProviderRegistry.platformLabel(uri) ?? 'this page';

    if (platform == SocialPlatform.reddit) {
      final contentType = RedditUri.classifyUrl(uri);
      switch (contentType) {
        case RedditContentType.home:
          return 'This is the Reddit home page, not a downloadable post.';
        case RedditContentType.subreddit:
          return 'This is a subreddit page, not a single post. '
              'Open a specific post to download its media.';
        case RedditContentType.user:
        case RedditContentType.search:
        case RedditContentType.nonContent:
          return 'This Reddit URL is not a downloadable post.';
        case RedditContentType.post:
        case RedditContentType.comment:
        case RedditContentType.short:
        case RedditContentType.share:
        case RedditContentType.directMedia:
          return 'Could not find Reddit-hosted media on this post. '
              'Many posts (especially older ones) are links to YouTube or '
              'another site — paste that original video URL instead. '
              'If the post is public, try opening it in the in-app browser first.';
      }
    }

    if (platform == SocialPlatform.instagram) {
      final contentType = InstagramGraphqlResolver.classifyUrl(uri);
      switch (contentType) {
        case InstagramContentType.story:
          return 'Instagram Stories require you to be logged in. '
              'Open this Story in the browser, log into your Instagram account, '
              'then try downloading again.';
        case InstagramContentType.profile:
          return 'This is an Instagram profile page, not a downloadable post. '
              'Open a specific Reel, photo, or video post to download it.';
        case InstagramContentType.post:
        case InstagramContentType.unknown:
          return 'Instagram did not return a downloadable video file for this '
              'post. The Reel is likely public, but Instagram withheld the '
              'video URL. Open it in the in-app browser first, then try again.';
      }
    }

    if (platform == SocialPlatform.twitch) {
      final contentType = TwitchResolver.classifyUrl(uri);
      switch (contentType) {
        case TwitchContentType.home:
          return 'This is the Twitch home page, not a downloadable Clip.';
        case TwitchContentType.directory:
          return 'This is a Twitch directory page, not a downloadable Clip.';
        case TwitchContentType.channel:
          return 'This Twitch channel cannot be downloaded. '
              'If the channel is live, live recording is not supported. '
              'Open a public Clip to download it.';
        case TwitchContentType.vod:
          return 'Twitch VODs and Highlights are HLS-only and cannot be saved '
              'as a single file.';
        case TwitchContentType.clip:
          return 'This Twitch Clip is unavailable, deleted, or restricted.';
        case TwitchContentType.nonContent:
          return 'This Twitch URL is not a downloadable Clip.';
      }
    }

    if (platform == SocialPlatform.linkedin) {
      switch (LinkedInUri.classifyUrl(uri)) {
        case LinkedInContentType.home:
        case LinkedInContentType.feed:
          return 'This is the LinkedIn home or feed page, not a downloadable post.';
        case LinkedInContentType.profile:
          return 'This is a LinkedIn profile, not a downloadable post. '
              'Open a specific public image or video post to download it.';
        case LinkedInContentType.company:
        case LinkedInContentType.school:
        case LinkedInContentType.showcase:
          return 'This is a LinkedIn company or organization page, not a '
              'downloadable post.';
        case LinkedInContentType.article:
        case LinkedInContentType.newsletter:
          return 'LinkedIn articles are not downloaded as media files. '
              'Open a public image or video post instead.';
        case LinkedInContentType.jobs:
        case LinkedInContentType.learning:
        case LinkedInContentType.events:
        case LinkedInContentType.groups:
        case LinkedInContentType.search:
        case LinkedInContentType.messaging:
        case LinkedInContentType.nonContent:
          return 'This LinkedIn URL is not a downloadable post.';
        case LinkedInContentType.video:
          return 'This LinkedIn video is unavailable, restricted, or not '
              'exposed as a downloadable file.';
        case LinkedInContentType.post:
        case LinkedInContentType.embed:
        case LinkedInContentType.shortUrl:
        case LinkedInContentType.directMedia:
          return 'Could not find downloadable media on this LinkedIn post. '
              'It may be text-only, restricted, deleted, or LinkedIn did not '
              'expose a media file.';
      }
    }

    if (platform == SocialPlatform.facebook) {
      final contentType = FacebookResolver.classifyUrl(uri);
      switch (contentType) {
        case FacebookContentType.home:
          return 'This is the Facebook home page, not a downloadable post. '
              'Open a specific video, photo, or Reel to download it.';
        case FacebookContentType.page:
          return 'This is a Facebook Page, not a downloadable post. '
              'Open a specific video, photo, or Reel from this page to download it.';
        case FacebookContentType.video:
        case FacebookContentType.reel:
        case FacebookContentType.photo:
        case FacebookContentType.post:
        case FacebookContentType.unknown:
          return 'Could not find downloadable media on this Facebook post. '
              'The content may require login, be restricted, deleted, '
              'or Facebook did not expose a media file.';
      }
    }

    if (platform == SocialPlatform.telegram) {
      return TelegramResolver.userFacingError(uri);
    }

    if (platform == SocialPlatform.snapchat) {
      return SnapchatResolver.userFacingError(uri);
    }

    if (platform == SocialPlatform.threads) {
      return ThreadsResolver.userFacingError(uri);
    }

    if (platform == SocialPlatform.whatsapp) {
      return WhatsAppResolver.userFacingError(uri);
    }

    return 'Could not find downloadable media on $label. '
        'Make sure the post is public, then try again or open it in the browser first.';
  }

  StorageCategory _categoryForMime(String? mime, String fileName) {
    final lower = (mime ?? '').toLowerCase();
    if (lower.startsWith('video/')) return StorageCategory.videos;
    if (lower.startsWith('image/')) return StorageCategory.images;
    if (lower.startsWith('audio/')) return StorageCategory.audio;
    if (lower.contains('pdf') || lower.contains('document')) {
      return StorageCategory.documents;
    }
    final ext = p.extension(fileName).toLowerCase();
    return switch (ext) {
      '.mp4' || '.mkv' || '.webm' => StorageCategory.videos,
      '.jpg' ||
      '.jpeg' ||
      '.png' ||
      '.gif' ||
      '.webp' => StorageCategory.images,
      '.mp3' ||
      '.wav' ||
      '.aac' ||
      '.flac' ||
      '.ogg' ||
      '.oga' ||
      '.opus' ||
      '.m4a' => StorageCategory.audio,
      '.pdf' ||
      '.doc' ||
      '.docx' ||
      '.xls' ||
      '.xlsx' ||
      '.ppt' ||
      '.pptx' ||
      '.txt' ||
      '.csv' ||
      '.vcf' => StorageCategory.documents,
      '.zip' || '.rar' || '.7z' || '.tar' || '.gz' => StorageCategory.archives,
      '.apk' => StorageCategory.apk,
      _ => StorageCategory.documents,
    };
  }

  Future<void> _updateTask(DownloadTask task, {bool persist = true}) async {
    if (_cancelledIds.contains(task.id) &&
        task.status != DownloadStatus.cancelled) {
      return;
    }
    final current = _tasks[task.id];
    if (current == null && task.status != DownloadStatus.queued) {
      return;
    }
    if (current != null &&
        current.status == DownloadStatus.cancelled &&
        task.status != DownloadStatus.cancelled) {
      return;
    }
    if (current != null &&
        current.status == DownloadStatus.paused &&
        task.status != DownloadStatus.paused &&
        task.status != DownloadStatus.queued) {
      return;
    }
    _tasks[task.id] = task;
    if (persist) {
      await _repository.update(task);
      _emit();
      return;
    }

    if (_emitGate.shouldRun()) {
      _emit();
    }
  }

  void _emit() {
    if (!_progressController.isClosed) {
      _progressController.add(tasks);
    }
  }

  /// Removes finished download records from memory and database.
  /// Files on disk are kept (FR-050).
  Future<int> clearHistory() async {
    const clearable = {
      DownloadStatus.completed,
      DownloadStatus.failed,
      DownloadStatus.cancelled,
    };

    final idsToRemove = _tasks.entries
        .where((entry) => clearable.contains(entry.value.status))
        .map((entry) => entry.key)
        .toList();
    if (idsToRemove.isEmpty) return 0;

    for (final id in idsToRemove) {
      _tasks.remove(id);
      _queueOrder.remove(id);
      _cancelTokens.remove(id);
      _retryCounts.remove(id);
      _cancelledIds.remove(id);
      _runningIds.remove(id);
    }

    final removed = await _repository.clearFinishedHistory();
    await _persistQueueOrder();
    _emit();
    return removed;
  }

  Future<void> dispose() async {
    for (final token in _cancelTokens.values) {
      token.cancel('disposed');
    }
    await _progressController.close();
  }
}
