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
    final tokens = ZfileTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onOpenFiles,
            borderRadius: BorderRadius.circular(UdmRadius.hero),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(UdmRadius.hero),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tokens.heroStart, tokens.heroEnd],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(UdmSpacing.cardPaddingLarge),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Storage',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: tokens.onGradientHeading,
                      ),
                    ),
                    const SizedBox(height: UdmSpacing.sm),
                    managedStats.when(
                      data: (value) => Text(
                        'Used ${TransferFormat.bytes(value.$2)} · ${value.$1} files',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: tokens.onGradientHeading,
                          fontFamily: 'Poppins',
                          package: 'design_system',
                        ),
                      ),
                      loading: () => Text(
                        'Scanning storage…',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.onGradientBody,
                        ),
                      ),
                      error: (_, _) => Text(
                        'Storage unavailable',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: tokens.onGradientBody,
                        ),
                      ),
                    ),
                    if (volume != null)
                      volume!.maybeWhen(
                        data: (info) {
                          if (!info.hasVolumeStats) {
                            return const SizedBox.shrink();
                          }
                          final fraction = info.totalBytes <= 0
                              ? 0.0
                              : (1 - (info.freeBytes / info.totalBytes))
                                  .clamp(0.0, 1.0);
                          return Padding(
                            padding: const EdgeInsets.only(top: UdmSpacing.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    UdmRadius.button,
                                  ),
                                  child: LinearProgressIndicator(
                                    value: fraction,
                                    minHeight: 8,
                                    color: tokens.chartFill,
                                    backgroundColor: tokens.onGradientHeading
                                        .withValues(alpha: 0.24),
                                  ),
                                ),
                                const SizedBox(height: UdmSpacing.sm),
                                Text(
                                  'Available ${TransferFormat.bytes(info.freeBytes)}'
                                  ' · Total ${TransferFormat.bytes(info.totalBytes)}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: tokens.onGradientBody,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      ),
                    if (onOpenFiles != null) ...[
                      const SizedBox(height: UdmSpacing.lg),
                      Align(
                        alignment: Alignment.centerRight,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: tokens.secondary,
                            borderRadius: BorderRadius.circular(UdmRadius.button),
                            boxShadow: tokens.buttonGlow,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Text(
                              'Manage',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: tokens.onAccent,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
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
                              Expanded(
                                child: Text(
                                  item.category.folderName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                '${item.fileCount} · ${TransferFormat.bytes(item.totalBytes)}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontFamily: 'Poppins',
                                  package: 'design_system',
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(UdmRadius.button),
                            child: LinearProgressIndicator(
                              value: managedBytes <= 0
                                  ? 0
                                  : (item.totalBytes / managedBytes).clamp(0, 1),
                              minHeight: 6,
                              color: tokens.swatch(_categoryKey(item.category)).icon,
                              backgroundColor: tokens
                                  .swatch(_categoryKey(item.category))
                                  .background,
                            ),
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

  String _categoryKey(StorageCategory category) => switch (category) {
    StorageCategory.videos => 'videos',
    StorageCategory.images => 'images',
    StorageCategory.audio => 'audio',
    StorageCategory.documents => 'documents',
    StorageCategory.apk => 'apps',
    _ => 'other',
  };
}
