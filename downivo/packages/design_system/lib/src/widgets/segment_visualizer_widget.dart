import 'package:flutter/material.dart';
import 'package:shared_types/shared_types.dart';

import '../spacing.dart';
import '../theme/udm_colors.dart';

/// Formats bytes into human-readable string.
String _formatBytes(int bytes, {int decimals = 1}) {
  if (bytes <= 0) return '0 B';
  const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
  final i = (bytes.bitLength - 1) ~/ 10;
  final idx = i.clamp(0, suffixes.length - 1);
  final value = bytes / (1 << (idx * 10));
  return '${value.toStringAsFixed(decimals)} ${suffixes[idx]}';
}

/// Formats speed (bytes/sec) as human-readable.
String _formatSpeed(int bytesPerSec) {
  if (bytesPerSec <= 0) return '0 KB/s';
  return '${_formatBytes(bytesPerSec)}/s';
}

/// IDM-style multi-connection segment visualizer.
///
/// Shows an aggregate overview bar plus individual segment cards
/// in a responsive grid layout.
class SegmentVisualizerWidget extends StatelessWidget {
  const SegmentVisualizerWidget({
    super.key,
    required this.segments,
    required this.fileName,
    required this.connectionCount,
    required this.totalBytes,
    required this.downloadedBytes,
    required this.speed,
    required this.etaSeconds,
    this.isDownloading = false,
  });

  final List<DownloadSegment> segments;
  final String fileName;
  final int connectionCount;
  final int totalBytes;
  final int downloadedBytes;
  final int speed;
  final int etaSeconds;
  final bool isDownloading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final percent = totalBytes > 0
        ? (downloadedBytes / totalBytes * 100).clamp(0.0, 100.0)
        : 0.0;

    if (segments.isEmpty) {
      return _EmptyState(isDark: isDark);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? UdmColors.raisedSlate : UdmColors.whiteSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? UdmColors.hairline : UdmColors.lightHairline,
          ),
        ),
      ),
      padding: const EdgeInsets.all(UdmSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: UdmColors.signalCyan.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: UdmColors.signalCyan.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(Icons.layers_rounded,
                    size: 14, color: UdmColors.signalCyan),
              ),
              const SizedBox(width: UdmSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '$connectionCount parallel connections · '
                      '${_formatBytes(downloadedBytes)} of ${_formatBytes(totalBytes)}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: UdmSpacing.sm),
              // Speed & ETA.
              Text(
                _formatSpeed(speed),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: UdmColors.signalCyan,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: UdmSpacing.md),
              Text(
                etaSeconds > 0 ? _formatEta(etaSeconds) : '--',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: UdmColors.successMoss,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: UdmSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? UdmColors.voidGraphite
                      : UdmColors.paper,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${percent.toStringAsFixed(1)}%',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: UdmSpacing.sm),

          // Aggregate bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 8,
              child: Row(
                children: segments.map((seg) {
                  final segPercent = seg.totalBytes > 0
                      ? (seg.downloadedBytes / seg.totalBytes).clamp(0.0, 1.0)
                      : 0.0;
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.only(right: 1),
                      decoration: BoxDecoration(
                        color: isDark ? UdmColors.voidGraphite : UdmColors.paper,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: segPercent,
                        child: Container(
                          color: segPercent >= 1.0
                              ? UdmColors.successMoss
                              : UdmColors.signalCyan,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: UdmSpacing.sm),

          // Segment cards grid.
          Wrap(
            spacing: UdmSpacing.xs,
            runSpacing: UdmSpacing.xs,
            children: segments.map((seg) {
              return _SegmentCard(
                segment: seg,
                isDark: isDark,
                isParentDownloading: isDownloading,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String _formatEta(int seconds) {
    if (seconds <= 0) return '--:--';
    if (seconds > 86400) return '> 1d';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.segment,
    required this.isDark,
    required this.isParentDownloading,
  });

  final DownloadSegment segment;
  final bool isDark;
  final bool isParentDownloading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = segment.progress;
    final isComplete = percent >= 1.0;

    return Container(
      width: 120,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark
            ? UdmColors.voidGraphite.withValues(alpha: 0.9)
            : UdmColors.paper,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isDark
              ? UdmColors.hairline.withValues(alpha: 0.5)
              : UdmColors.lightHairline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Conn #${segment.id + 1}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w500,
                  fontSize: 10,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: isComplete
                      ? UdmColors.successMoss.withValues(alpha: 0.2)
                      : isParentDownloading
                          ? UdmColors.signalCyan.withValues(alpha: 0.2)
                          : (isDark ? UdmColors.voidGraphite : UdmColors.paper),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  isComplete
                      ? 'DONE'
                      : '${(percent * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: isComplete
                        ? UdmColors.successMoss
                        : isParentDownloading
                            ? UdmColors.signalCyan
                            : (isDark ? UdmColors.fogSteel : UdmColors.slateMute),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Mini progress bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor:
                  isDark ? UdmColors.hairline : UdmColors.lightHairline,
              valueColor: AlwaysStoppedAnimation(
                isComplete ? UdmColors.successMoss : UdmColors.signalCyan,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatBytes(segment.downloadedBytes),
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
                ),
              ),
              Text(
                isParentDownloading ? _formatSpeed(segment.speed) : '--',
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? UdmColors.raisedSlate : UdmColors.whiteSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? UdmColors.hairline : UdmColors.lightHairline,
          ),
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.hub_outlined,
              size: 20,
              color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
            ),
            const SizedBox(height: 4),
            Text(
              'Select an active download to monitor segments',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
