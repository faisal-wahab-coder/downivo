import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../spacing.dart';
import '../theme/udm_colors.dart';

/// Real-time download speed throughput graph.
///
/// Renders a rolling line chart with gradient fill showing
/// recent speed history. Optionally shows a speed limit indicator.
class SpeedGraphWidget extends StatelessWidget {
  const SpeedGraphWidget({
    super.key,
    required this.speedHistory,
    this.currentSpeed = 0,
    this.speedLimitBytesPerSec = 0,
    this.height = 64,
  });

  /// Rolling buffer of speed samples (bytes/sec). Newest last.
  final List<int> speedHistory;

  /// Current aggregate speed for the label overlay.
  final int currentSpeed;

  /// Active speed limit line (0 = no limit shown).
  final int speedLimitBytesPerSec;

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? UdmColors.insetWell : UdmColors.paper,
        border: Border(
          top: BorderSide(
            color: isDark ? UdmColors.hairline : UdmColors.lightHairline,
          ),
        ),
      ),
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _SpeedGraphPainter(
              history: speedHistory,
              speedLimit: speedLimitBytesPerSec,
              isDark: isDark,
            ),
          ),
          Positioned(
            top: UdmSpacing.xs,
            left: UdmSpacing.sm,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: UdmSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: (isDark ? UdmColors.voidGraphite : UdmColors.whiteSurface)
                    .withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? UdmColors.hairline : UdmColors.lightHairline,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.show_chart_rounded,
                    size: 12,
                    color: UdmColors.signalCyan,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Throughput: ',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? UdmColors.fogSteel : UdmColors.slateMute,
                    ),
                  ),
                  Text(
                    _formatSpeed(currentSpeed),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: UdmColors.signalCyan,
                    ),
                  ),
                  if (speedLimitBytesPerSec > 0) ...[
                    const SizedBox(width: 6),
                    Text(
                      '(Limit: ${_formatSpeed(speedLimitBytesPerSec)})',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: UdmColors.cautionAmber,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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

class _SpeedGraphPainter extends CustomPainter {
  _SpeedGraphPainter({
    required this.history,
    required this.speedLimit,
    required this.isDark,
  });

  final List<int> history;
  final int speedLimit;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (history.isEmpty) return;

    final w = size.width;
    final h = size.height;

    // Draw grid lines.
    final gridPaint = Paint()
      ..color = (isDark ? UdmColors.hairline : UdmColors.lightHairline)
          .withValues(alpha: 0.5)
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final y = h * i / 3;
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final maxVal = math.max(
      history.reduce(math.max).toDouble(),
      math.max(speedLimit.toDouble(), 1024 * 1024),
    );

    // Draw speed limit line.
    if (speedLimit > 0) {
      final limitY = h - (speedLimit / maxVal) * (h - 10) - 5;
      final limitPaint = Paint()
        ..color = UdmColors.cautionAmber.withValues(alpha: 0.6)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      final dashPath = Path()
        ..moveTo(0, limitY)
        ..lineTo(w, limitY);
      canvas.drawPath(
        _dashPath(dashPath, 4, 4),
        limitPaint,
      );
    }

    // Build data path.
    final step = w / math.max(history.length - 1, 1);
    final path = Path();
    for (var i = 0; i < history.length; i++) {
      final x = i * step;
      final y = h - (history[i] / maxVal) * (h - 12) - 4;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Gradient fill under the line.
    final fillPath = Path.from(path)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    final gradient = ui.Gradient.linear(
      Offset(0, 0),
      Offset(0, h),
      [
        UdmColors.signalCyan.withValues(alpha: 0.4),
        UdmColors.signalCyan.withValues(alpha: 0.0),
      ],
    );
    canvas.drawPath(fillPath, Paint()..shader = gradient);

    // Draw the line itself.
    canvas.drawPath(
      path,
      Paint()
        ..color = UdmColors.signalCyan
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  Path _dashPath(Path source, double dashLength, double gapLength) {
    final dest = Path();
    for (final metric in source.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dashLength, metric.length);
        dest.addPath(metric.extractPath(distance, end), Offset.zero);
        distance = end + gapLength;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_SpeedGraphPainter oldDelegate) {
    return oldDelegate.history != history ||
        oldDelegate.speedLimit != speedLimit;
  }
}
