import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/udm_colors.dart';
import '../theme/zfile_tokens.dart';

/// Status bar footer showing live aggregate download stats.
class DownloadStatusBar extends StatelessWidget {
  const DownloadStatusBar({
    super.key,
    required this.totalItems,
    required this.activeCount,
    required this.totalSpeedBytesPerSec,
    this.completedCount = 0,
    this.queuedCount = 0,
  });

  final int totalItems;
  final int activeCount;
  final int totalSpeedBytesPerSec;
  final int completedCount;
  final int queuedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tokens = ZfileTokens.of(context);

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: UdmSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? UdmColors.raisedSlate : UdmColors.whiteSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? UdmColors.hairline : UdmColors.lightHairline,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(
                    label: 'Total',
                    value: '$totalItems',
                    isDark: isDark,
                  ),
                  _dot(isDark),
                  _StatusChip(
                    label: 'Active',
                    value: '$activeCount',
                    valueColor: tokens.secondary,
                    isDark: isDark,
                  ),
                  _dot(isDark),
                  _StatusChip(
                    label: 'Completed',
                    value: '$completedCount',
                    valueColor: tokens.secondaryDark,
                    isDark: isDark,
                  ),
                  if (queuedCount > 0) ...[
                    _dot(isDark),
                    _StatusChip(
                      label: 'Queued',
                      value: '$queuedCount',
                      isDark: isDark,
                    ),
                  ],
                  _dot(isDark),
                  _StatusChip(
                    label: 'Speed',
                    value: _formatSpeed(totalSpeedBytesPerSec),
                    valueColor: tokens.secondaryDark,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: UdmSpacing.sm),
          Text(
            'Downivo Engine v2',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              fontFamily: 'monospace',
              color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text(
        '·',
        style: TextStyle(
          fontSize: 10,
          color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
        ),
      ),
    );
  }

  static String _formatSpeed(int bytesPerSec) {
    if (bytesPerSec <= 0) return '0 KB/s';
    if (bytesPerSec < 1024) return '${bytesPerSec} B/s';
    if (bytesPerSec < 1024 * 1024) {
      return '${(bytesPerSec / 1024).toStringAsFixed(1)} KB/s';
    }
    return '${(bytesPerSec / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: valueColor ??
                (isDark ? UdmColors.porcelain : UdmColors.ink),
          ),
        ),
      ],
    );
  }
}
