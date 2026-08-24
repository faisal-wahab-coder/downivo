import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:notifications/notifications.dart';
import 'package:shared_types/shared_types.dart';

import 'foreground_factory.dart';

/// Keeps active downloads alive in the background and surfaces notification updates.
class BackgroundDownloadCoordinator {
  BackgroundDownloadCoordinator({
    required DownloadManager downloadManager,
    DownloadNotificationService? notifications,
    Connectivity? connectivity,
    ForegroundHost? foregroundHost,
  })  : _downloadManager = downloadManager,
        _notifications = notifications ?? DownloadNotificationService(),
        _connectivity = connectivity ?? Connectivity(),
        _foreground = foregroundHost ?? createForegroundHost();

  final DownloadManager _downloadManager;
  final DownloadNotificationService _notifications;
  final Connectivity _connectivity;
  final ForegroundHost _foreground;

  StreamSubscription<List<DownloadTask>>? _subscription;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  final _previousStatus = <String, DownloadStatus>{};
  var _initialized = false;
  var _wasOffline = false;
  var _connectivityInitialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    if (!kIsWeb) {
      await _notifications.initialize();
      DownloadNotificationActions.handler = _onNotificationAction;
      await _foreground.initialize();
    }

    _subscription = _downloadManager.tasksStream.listen(_handleTasks);
    _connectivitySub = _connectivity.onConnectivityChanged.listen(
      _handleConnectivity,
    );
    _handleTasks(_downloadManager.tasks);
    _initialized = true;
  }

  void _onNotificationAction(String actionId, String? taskId) {
    if (taskId == null) return;
    switch (actionId) {
      case DownloadNotificationActions.pauseAction:
        unawaited(_downloadManager.pause(taskId));
      case DownloadNotificationActions.cancelAction:
        unawaited(_downloadManager.cancel(taskId));
    }
  }

  Future<void> _handleConnectivity(List<ConnectivityResult> results) async {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (!_connectivityInitialized) {
      _connectivityInitialized = true;
      _wasOffline = !online;
      return;
    }
    if (!online) {
      _wasOffline = true;
      await _downloadManager.pauseAll();
      return;
    }
    if (_wasOffline) {
      _wasOffline = false;
      await _downloadManager.resumeAll();
    }
  }

  void _handleTasks(List<DownloadTask> tasks) {
    _notifyTerminalTransitions(tasks);

    final active = tasks.where((task) => task.isActive).toList();
    if (active.isEmpty) {
      unawaited(_foreground.stop());
      unawaited(_notifications.dismissProgress());
      return;
    }

    final primary = _downloadManager.primaryActiveTask ?? active.first;
    final progressPercent = (primary.progress * 100).round();

    unawaited(
      _notifications.showProgress(
        activeCount: active.length,
        primaryFileName: primary.fileName,
        progressPercent: progressPercent,
        primaryTaskId: primary.id,
      ),
    );
    unawaited(
      _foreground.start(
        title: active.length > 1
            ? 'Downloading ${active.length} files'
            : 'Downloading file…',
        text: '${primary.fileName} — $progressPercent%',
      ),
    );
  }

  void _notifyTerminalTransitions(List<DownloadTask> tasks) {
    for (final task in tasks) {
      final previous = _previousStatus[task.id];
      _previousStatus[task.id] = task.status;

      if (previous == null || previous == task.status) continue;

      final notificationId = _notificationIdFor(task.id);

      if (task.status == DownloadStatus.completed) {
        unawaited(
          _notifications.showCompleted(
            fileName: task.fileName,
            notificationId: notificationId,
          ),
        );
      } else if (task.status == DownloadStatus.failed) {
        unawaited(
          _notifications.showFailed(
            fileName: task.fileName,
            notificationId: notificationId,
            reason: task.errorMessage,
          ),
        );
      }
    }
  }

  int _notificationIdFor(String taskId) =>
      taskId.hashCode.abs().clamp(2000, 999999);

  Future<void> dispose() async {
    DownloadNotificationActions.handler = null;
    await _subscription?.cancel();
    await _connectivitySub?.cancel();
    await _foreground.stop();
  }
}
