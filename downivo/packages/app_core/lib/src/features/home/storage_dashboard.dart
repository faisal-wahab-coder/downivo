import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_utils/shared_utils.dart';
import 'package:storage/storage.dart';

class StorageDashboard extends StatelessWidget {
  const StorageDashboard({
    super.key,
    required this.managedStats,
    required this.summaries,
    this.volume,
    this.onOpenFiles,
  });

  final AsyncValue<(int, int)> managedStats;
  final AsyncValue<List<CategorySummary>> summaries;
  final AsyncValue<StorageInfo>? volume;
  final VoidCallback? onOpenFiles;

  static const _featured = {
    StorageCategory.videos,
    StorageCategory.images,
    StorageCategory.audio,
    StorageCategory.documents,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(UdmSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.folder_outlined),
                  title: const Text('Storage'),
                  subtitle: managedStats.when(
                    data: (value) => Text(
                      'Used ${TransferFormat.bytes(value.$2)} · ${value.$1} files',
                    ),
                    loading: () => const Text('Scanning storage…'),
                    error: (_, __) => const Text('Storage unavailable'),
                  ),
                  trailing: onOpenFiles == null
                      ? null
                      : const Icon(Icons.chevron_right),
                  onTap: onOpenFiles,
                ),
                if (volume != null)
                  volume!.maybeWhen(
                    data: (info) {
                      if (!info.hasVolumeStats) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: UdmSpacing.sm),
                        child: Text(
                          'Available ${TransferFormat.bytes(info.freeBytes)}'
                          ' · Total ${TransferFormat.bytes(info.totalBytes)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                    orElse: () => const SizedBox.shrink(),
                  ),
              ],
            ),
          ),
        ),
        summaries.maybeWhen(
          data: (items) {
            final visible = items
                .where(
                  (item) =>
                      _featured.contains(item.category) && item.fileCount > 0,
                )
                .toList();
            if (visible.isEmpty) return const SizedBox.shrink();
            final managedBytes = visible.fold<int>(
              0,
              (sum, item) => sum + item.totalBytes,
            );
            return Padding(
              padding: const EdgeInsets.only(top: UdmSpacing.md),
              child: Column(
                children: [
                  for (final item in visible)
                    Padding(
                      padding: const EdgeInsets.only(bottom: UdmSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(item.category.folderName)),
                              Text(
                                '${item.fileCount} · ${TransferFormat.bytes(item.totalBytes)}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: managedBytes <= 0
                                ? 0
                                : (item.totalBytes / managedBytes).clamp(0, 1),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
          orElse: () => const UdmSkeleton(height: 72),
        ),
      ],
    );
  }
}
