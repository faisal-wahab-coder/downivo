import 'package:analytics/analytics.dart';
import 'package:design_system/design_system.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';
import 'package:shared_utils/shared_utils.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/download_providers.dart';
import '../files/open_managed_media.dart';

class DownloadProgressDetails extends StatelessWidget {
  const DownloadProgressDetails({super.key, required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final pct = (task.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final showDeterminate =
        task.progress > 0 &&
        task.status != DownloadStatus.preparing &&
        task.status != DownloadStatus.verifying &&
        task.status != DownloadStatus.queued;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: UdmSpacing.xs),
        LinearProgressIndicator(
          value: showDeterminate ? task.progress : null,
          color: _progressColor(task.status),
        ),
        const SizedBox(height: UdmSpacing.xs),
        Text(_statusLabel(task, pct), style: style),
        if (task.status == DownloadStatus.downloading) ...[
          const SizedBox(height: 2),
          Text(
            '${TransferFormat.bytes(task.bytesReceived)}'
            '${task.fileSize != null ? ' / ${TransferFormat.bytes(task.fileSize!)}' : ''}'
            ' · ${TransferFormat.speed(task.speedBytesPerSec)}'
            ' · ${TransferFormat.eta(bytesRemaining: task.bytesRemaining, bytesPerSec: task.speedBytesPerSec)}',
            style: style,
          ),
        ],
        if (task.errorMessage != null)
          Text(
            DownloadErrorFormatter.fromObject(task.errorMessage!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
      ],
    );
  }

  Color? _progressColor(DownloadStatus status) => switch (status) {
    DownloadStatus.paused || DownloadStatus.verifying => UdmColors.cautionAmber,
    DownloadStatus.failed => UdmColors.faultCoral,
    DownloadStatus.completed => UdmColors.successMoss,
    _ => null,
  };

  String _statusLabel(DownloadTask task, String pct) {
    final connLabel = task.connectionCount > 1
        ? ' · ${task.connectionCount} connections'
        : '';
    final warnLabel = task.isStuck
        ? ' · ⚠ Stuck (${task.stuckDurationSecs}s)'
        : task.isSlow
            ? ' · Slow'
            : '';
    return switch (task.status) {
      DownloadStatus.queued => 'Queued',
      DownloadStatus.preparing => 'Preparing…',
      DownloadStatus.downloading => 'Downloading $pct%$connLabel$warnLabel',
      DownloadStatus.paused => 'Paused at $pct%',
      DownloadStatus.completed => 'Completed',
      DownloadStatus.failed => 'Failed',
      DownloadStatus.cancelled => 'Cancelled',
      DownloadStatus.verifying => 'Verifying…',
    };
  }
}

class DownloadTrailingActions extends StatelessWidget {
  const DownloadTrailingActions({
    super.key,
    required this.task,
    required this.ref,
  });

  final DownloadTask task;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    if (task.status == DownloadStatus.downloading) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.isStuck || task.isSlow)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reload connections',
              onPressed: () {
                final manager = ref.read(downloadManagerProvider);
                manager.reloadConnections(task.id);
              },
            ),
          IconButton(
            icon: const Icon(Icons.pause),
            tooltip: 'Pause',
            onPressed: () {
              ref.read(analyticsServiceProvider).track(AnalyticsEvent.pauseClicked);
              pauseDownload(ref, task.id);
            },
          ),
        ],
      );
    }
    if (task.status == DownloadStatus.paused) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow),
            tooltip: 'Resume',
            onPressed: () {
              ref.read(analyticsServiceProvider).track(AnalyticsEvent.resumeClicked);
              resumeDownload(ref, task.id);
            },
          ),
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Cancel',
            onPressed: () {
              ref.read(analyticsServiceProvider).track(AnalyticsEvent.cancelClicked);
              cancelDownload(ref, task.id);
            },
          ),
        ],
      );
    }
    if (task.status == DownloadStatus.failed) {
      return IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Retry',
        onPressed: () => retryDownload(ref, task.id),
      );
    }
    if (task.isActive) {
      return IconButton(
        icon: const Icon(Icons.close),
        tooltip: 'Cancel',
            onPressed: () {
              ref.read(analyticsServiceProvider).track(AnalyticsEvent.cancelClicked);
              cancelDownload(ref, task.id);
            },
      );
    }
    if (task.status == DownloadStatus.completed && task.hasManagedFile) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (task.checksumSha256 != null)
            IconButton(
              icon: const Icon(Icons.verified_user_outlined),
              tooltip: 'Verify checksum',
              onPressed: () => ChecksumDialog.show(
                context,
                fileName: task.fileName,
                sha256: task.checksumSha256!,
                md5: task.checksumMd5 ?? '',
              ),
            ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Share',
            onPressed: () {
              ref.read(analyticsServiceProvider).track(AnalyticsEvent.shareClicked);
              shareManagedMedia(context, ref, path: task.filePath!);
            },
          ),
          if (canSaveManagedMediaToGallery(task.filePath!, task.mimeType))
            IconButton(
              icon: const Icon(Icons.photo_library_outlined),
              tooltip: 'Save to Gallery',
              onPressed: () =>
                  saveManagedMediaToGallery(context, ref, path: task.filePath!),
            ),
        ],
      );
    }
    return const SizedBox.shrink();
  }
}

class DownloadTaskCard extends StatelessWidget {
  const DownloadTaskCard({
    super.key,
    required this.task,
    required this.ref,
    this.leading,
    this.onTap,
  });

  final DownloadTask task;
  final WidgetRef ref;
  final Widget? leading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final platformLabel = task.platform?.trim().isNotEmpty == true
        ? task.platform!
        : SocialPlatform.fromUri(Uri.tryParse(task.url) ?? Uri())?.label;
    final pct = (task.progress * 100).clamp(0, 100).toStringAsFixed(0);
    final title = task.title?.trim().isNotEmpty == true
        ? task.title!
        : task.fileName;
    final canOpen =
        task.status == DownloadStatus.completed && task.hasManagedFile;

    return Semantics(
      label: '$title, ${_chipLabel(task, pct)}',
      button: canOpen || task.isRemovedFromLibrary || onTap != null,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap != null || canOpen || task.isRemovedFromLibrary
              ? () => _handleTap(context)
              : null,
          onLongPress: () => _showContextMenu(context),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              UdmSpacing.md,
              UdmSpacing.sm,
              UdmSpacing.xs,
              UdmSpacing.md,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leading != null) ...[
                  leading!,
                  const SizedBox(width: UdmSpacing.sm),
                ] else ...[
                  _TaskThumb(task: task),
                  const SizedBox(width: UdmSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: UdmSpacing.sm,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (platformLabel != null)
                            PlatformBadge(label: platformLabel),
                          DownloadStatusBadge(
                            status: task.status,
                            isStuck: task.isStuck,
                            isSlow: task.isSlow,
                          ),
                          if (task.connectionCount > 1)
                            UdmStatusChip(
                              label: '${task.connectionCount}×',
                              tone: UdmStatusTone.info,
                            ),
                          if (task.isRemovedFromLibrary)
                            const UdmStatusChip(
                              label: 'Removed from Files',
                              tone: UdmStatusTone.caution,
                            ),
                        ],
                      ),
                      DownloadProgressDetails(task: task),
                    ],
                  ),
                ),
                DownloadTrailingActions(task: task, ref: ref),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context) {
    onTap?.call();
    if (task.status == DownloadStatus.completed && task.hasManagedFile) {
      ref.read(analyticsServiceProvider).track(AnalyticsEvent.openFileClicked);
      openManagedMedia(
        context,
        ref,
        path: task.filePath!,
        title: task.title?.trim().isNotEmpty == true
            ? task.title!
            : task.fileName,
        mimeType: task.mimeType,
      );
      return;
    }
    if (task.isRemovedFromLibrary && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This file was deleted in Files')),
      );
    }
  }

  void _showContextMenu(BuildContext context) {
    final manager = ref.read(downloadManagerProvider);
    final items = <PopupMenuEntry<String>>[];

    if (task.status == DownloadStatus.downloading) {
      items.add(const PopupMenuItem(value: 'pause', child: Text('Pause')));
      if (task.isStuck || task.isSlow) {
        items.add(const PopupMenuItem(
          value: 'reload',
          child: Text('Reload connections'),
        ));
      }
    }
    if (task.status == DownloadStatus.paused) {
      items.add(const PopupMenuItem(value: 'resume', child: Text('Resume')));
    }
    if (task.status == DownloadStatus.failed) {
      items.add(const PopupMenuItem(value: 'retry', child: Text('Retry')));
    }
    if (task.isActive) {
      items.add(const PopupMenuItem(value: 'cancel', child: Text('Cancel')));
    }
    if (task.status == DownloadStatus.completed && task.hasManagedFile) {
      items.add(const PopupMenuItem(value: 'open', child: Text('Open file')));
      items.add(const PopupMenuItem(value: 'share', child: Text('Share')));
      if (task.checksumSha256 != null) {
        items.add(const PopupMenuItem(
          value: 'checksum',
          child: Text('Verify checksum'),
        ));
      }
    }

    if (items.isEmpty) return;

    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final renderBox = context.findRenderObject()! as RenderBox;
    final position = RelativeRect.fromRect(
      renderBox.localToGlobal(Offset.zero) & renderBox.size,
      Offset.zero & overlay.size,
    );

    showMenu<String>(
      context: context,
      position: position,
      items: items,
    ).then((value) {
      if (value == null || !context.mounted) return;
      switch (value) {
        case 'pause':
          pauseDownload(ref, task.id);
        case 'resume':
          resumeDownload(ref, task.id);
        case 'retry':
          retryDownload(ref, task.id);
        case 'cancel':
          cancelDownload(ref, task.id);
        case 'reload':
          manager.reloadConnections(task.id);
        case 'open':
          _handleTap(context);
        case 'share':
          shareManagedMedia(context, ref, path: task.filePath!);
        case 'checksum':
          ChecksumDialog.show(
            context,
            fileName: task.fileName,
            sha256: task.checksumSha256!,
            md5: task.checksumMd5 ?? '',
          );
      }
    });
  }

  String _chipLabel(DownloadTask task, String pct) => switch (task.status) {
    DownloadStatus.queued => 'Queued',
    DownloadStatus.preparing => 'Preparing',
    DownloadStatus.downloading => 'Downloading',
    DownloadStatus.paused => 'Paused',
    DownloadStatus.completed => 'Completed',
    DownloadStatus.failed => 'Failed',
    DownloadStatus.cancelled => 'Cancelled',
    DownloadStatus.verifying => 'Verifying',
  };
}

class _TaskThumb extends StatelessWidget {
  const _TaskThumb({required this.task});

  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    final url = task.thumbnailUrl;
    if (url == null || url.isEmpty) {
      return _MimeWell(fileName: task.fileName, mimeType: task.mimeType);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 56,
        height: 56,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          headers: const {'User-Agent': SocialHttpHeaders.userAgent},
          errorBuilder: (context, error, stack) =>
              _MimeWell(fileName: task.fileName, mimeType: task.mimeType),
        ),
      ),
    );
  }
}

class _MimeWell extends StatelessWidget {
  const _MimeWell({required this.fileName, this.mimeType});

  final String fileName;
  final String? mimeType;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Icon(_icon, color: Theme.of(context).colorScheme.primary),
    );
  }

  IconData get _icon {
    final mime = (mimeType ?? '').toLowerCase();
    final name = fileName.toLowerCase();
    if (mime.startsWith('video/') ||
        _hasExt(name, const ['.mp4', '.mkv', '.mov', '.webm'])) {
      return Icons.videocam_outlined;
    }
    if (mime.startsWith('audio/') ||
        _hasExt(name, const ['.mp3', '.m4a', '.wav', '.ogg', '.flac'])) {
      return Icons.audiotrack_outlined;
    }
    if (mime.startsWith('image/') ||
        _hasExt(name, const ['.jpg', '.jpeg', '.png', '.webp', '.gif'])) {
      return Icons.image_outlined;
    }
    if (_hasExt(name, const ['.zip', '.rar', '.7z', '.tar', '.gz'])) {
      return Icons.folder_zip_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }

  bool _hasExt(String name, List<String> exts) => exts.any(name.endsWith);
}
