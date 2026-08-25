import 'dart:convert';

import 'package:database/database.dart';
import 'package:shared_types/shared_types.dart';

import 'content_providers/social_url_utils.dart';
import 'filename_resolver.dart';
import 'models/download_task.dart';

class UrlValidationResult {
  const UrlValidationResult.valid(this.uri)
      : isValid = true,
        errorMessage = null;

  const UrlValidationResult.invalid(this.errorMessage)
      : isValid = false,
        uri = null;

  final bool isValid;
  final Uri? uri;
  final String? errorMessage;
}

class UrlValidator {
  static final _allowedSchemes = {'http', 'https'};

  UrlValidationResult validate(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return const UrlValidationResult.invalid('URL cannot be empty.');
    }

    Uri? uri;
    try {
      uri = Uri.parse(trimmed);
    } on Object {
      return const UrlValidationResult.invalid('Invalid URL format.');
    }

    if (TelegramUri.isTelegramScheme(uri)) {
      final normalized = TelegramUri.tryNormalizeDeepLink(uri);
      if (normalized == null) {
        return UrlValidationResult.invalid(
          TelegramUri.deepLinkRejectionMessage(uri),
        );
      }
      uri = normalized;
    }

    if (SnapchatUri.isSnapchatScheme(uri)) {
      final normalized = SnapchatUri.tryNormalizeDeepLink(uri);
      if (normalized == null) {
        return UrlValidationResult.invalid(
          SnapchatUri.deepLinkRejectionMessage(uri),
        );
      }
      uri = normalized;
    }

    if (WhatsAppUri.isWhatsAppScheme(uri)) {
      final normalized = WhatsAppUri.tryNormalizeDeepLink(uri);
      if (normalized == null) {
        return UrlValidationResult.invalid(
          WhatsAppUri.deepLinkRejectionMessage(uri),
        );
      }
      uri = normalized;
    }

    if (!_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return const UrlValidationResult.invalid(
        'Only HTTP and HTTPS URLs are supported.',
      );
    }
    if (!uri.hasAuthority) {
      return const UrlValidationResult.invalid('URL must include a host.');
    }

    return UrlValidationResult.valid(uri);
  }

  String fileNameFromUrl(Uri uri, {String? contentDisposition}) {
    final fromDisposition = FileNameResolver.parseContentDisposition(
      contentDisposition,
    );
    if (fromDisposition != null && fromDisposition.isNotEmpty) {
      return FileNameResolver.sanitize(fromDisposition);
    }

    final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : '';
    if (segment.isNotEmpty && segment.contains('.')) {
      return FileNameResolver.sanitize(segment);
    }
    return '';
  }

  String? domainFromUrl(Uri uri) => uri.host;
}

class DownloadRepository {
  DownloadRepository(this._database);

  final AppDatabase _database;

  Future<List<DownloadTask>> getAll() async {
    final records = await _database.getAllDownloads();
    return records.map(_mapRecord).toList();
  }

  Future<DownloadTask?> getById(String id) async {
    final record = await _database.getDownloadById(id);
    return record == null ? null : _mapRecord(record);
  }

  Future<void> save(DownloadTask task) {
    return _database.insertDownload(_mapTask(task));
  }

  Future<void> update(DownloadTask task) {
    return _database.updateDownload(_mapTask(task));
  }

  Future<int> clearFilePath(String path) {
    return _database.clearDownloadFilePath(path);
  }

  /// Clears finished download records (completed, failed, cancelled).
  Future<int> clearFinishedHistory() {
    return _database.deleteDownloadsWithStatuses([
      DownloadStatus.completed.storageValue,
      DownloadStatus.failed.storageValue,
      DownloadStatus.cancelled.storageValue,
    ]);
  }

  static const _queueOrderKey = 'download_queue_order';

  Future<List<String>> getQueueOrder() async {
    final raw = await _database.getMetadata(_queueOrderKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } on Object {
      return [];
    }
    return [];
  }

  Future<void> saveQueueOrder(List<String> ids) {
    return _database.setMetadata(_queueOrderKey, jsonEncode(ids));
  }

  DownloadTask _mapRecord(DownloadRecord record) {
    return DownloadTask(
      id: record.id,
      url: record.url,
      fileName: record.fileName,
      filePath: record.filePath,
      fileSize: record.fileSize,
      mimeType: record.mimeType,
      status: DownloadStatus.fromStorage(record.status),
      progress: record.progress,
      priority: _priorityFromStorage(record.priority),
      createdAt: record.createdAt,
      updatedAt: record.updatedAt,
      thumbnailUrl: record.thumbnailUrl,
      platform: record.platform,
      title: record.title,
    );
  }

  DownloadPriority _priorityFromStorage(String value) {
    return DownloadPriority.values.firstWhere(
      (p) => p.storageValue == value,
      orElse: () => DownloadPriority.normal,
    );
  }

  DownloadRecord _mapTask(DownloadTask task) {
    return DownloadRecord(
      id: task.id,
      url: task.url,
      domain: Uri.tryParse(task.url)?.host,
      fileName: task.fileName,
      filePath: task.filePath,
      fileSize: task.fileSize,
      mimeType: task.mimeType,
      status: task.status.storageValue,
      priority: task.priority.storageValue,
      progress: task.progress,
      createdAt: task.createdAt,
      startedAt: task.status == DownloadStatus.downloading ? task.updatedAt : null,
      completedAt: task.status == DownloadStatus.completed ? task.updatedAt : null,
      updatedAt: task.updatedAt,
      thumbnailUrl: task.thumbnailUrl,
      platform: task.platform,
      title: task.title,
    );
  }
}
