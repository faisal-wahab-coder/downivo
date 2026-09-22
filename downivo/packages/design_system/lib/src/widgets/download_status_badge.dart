import 'package:flutter/material.dart';
import 'package:shared_types/shared_types.dart';

import '../theme/udm_colors.dart';

/// Colored status badge for download items.
class DownloadStatusBadge extends StatelessWidget {
  const DownloadStatusBadge({
    super.key,
    required this.status,
    this.isStuck = false,
    this.isSlow = false,
  });

  final DownloadStatus status;
  final bool isStuck;
  final bool isSlow;

  @override
  Widget build(BuildContext context) {
    final (label, color, icon, pulsing) = _config;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pulsing)
            _PulsingDot(color: color)
          else
            Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, Color, IconData, bool) get _config {
    if (isStuck && status == DownloadStatus.downloading) {
      return ('Stuck', UdmColors.cautionAmber, Icons.warning_rounded, true);
    }
    if (isSlow && status == DownloadStatus.downloading) {
      return ('Slow', UdmColors.cautionAmber, Icons.speed_rounded, false);
    }

    return switch (status) {
      DownloadStatus.downloading => (
          'Downloading',
          UdmColors.signalCyan,
          Icons.download_rounded,
          true
        ),
      DownloadStatus.completed => (
          'Completed',
          UdmColors.successMoss,
          Icons.check_circle_rounded,
          false
        ),
      DownloadStatus.paused => (
          'Paused',
          UdmColors.cautionAmber,
          Icons.pause_circle_rounded,
          false
        ),
      DownloadStatus.queued => (
          'Queued',
          UdmColors.electricBlue,
          Icons.schedule_rounded,
          false
        ),
      DownloadStatus.failed => (
          'Failed',
          UdmColors.faultCoral,
          Icons.error_rounded,
          false
        ),
      DownloadStatus.cancelled => (
          'Cancelled',
          UdmColors.fogSteel,
          Icons.cancel_rounded,
          false
        ),
      DownloadStatus.preparing => (
          'Finding video',
          UdmColors.signalCyan,
          Icons.hourglass_top_rounded,
          true
        ),
      DownloadStatus.verifying => (
          'Verifying',
          UdmColors.successMoss,
          Icons.verified_rounded,
          true
        ),
    };
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(
              alpha: 0.5 + _controller.value * 0.5,
            ),
          ),
        );
      },
    );
  }
}
