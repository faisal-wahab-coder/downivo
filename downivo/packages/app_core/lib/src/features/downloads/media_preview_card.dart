import 'package:design_system/design_system.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:shared_utils/shared_utils.dart';

class MediaPreviewCard extends StatelessWidget {
  const MediaPreviewCard({
    super.key,
    required this.resource,
    this.extraCount = 0,
    this.selectedFormat,
    this.onDownload,
    this.onMoreOptions,
  });

  final DiscoveredResource resource;
  final int extraCount;
  final MediaFormat? selectedFormat;
  final VoidCallback? onDownload;
  final VoidCallback? onMoreOptions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final format = selectedFormat ?? resource.recommendedFormat;
    final bits = <String>[
      resource.resolvedKind.label,
      if (resource.author != null && resource.author!.trim().isNotEmpty)
        resource.author!,
      if (format?.label != null) format!.label,
      if (resource.durationSeconds != null)
        _formatDuration(resource.durationSeconds!),
      if (format?.sizeBytes != null)
        TransferFormat.bytes(format!.sizeBytes!)
      else if (resource.contentLengthBytes != null)
        TransferFormat.bytes(resource.contentLengthBytes!),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UdmSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Thumb(url: resource.thumbnailUrl),
                const SizedBox(width: UdmSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PlatformBadge(label: resource.platform),
                      const SizedBox(height: UdmSpacing.xs),
                      Text(
                        resource.title?.trim().isNotEmpty == true
                            ? resource.title!
                            : resource.fileName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bits.join(' · '),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (extraCount > 0)
                        Text(
                          '+$extraCount more',
                          style: theme.textTheme.labelSmall,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (onDownload != null || onMoreOptions != null) ...[
              const SizedBox(height: UdmSpacing.md),
              Row(
                children: [
                  if (onMoreOptions != null)
                    TextButton(
                      onPressed: onMoreOptions,
                      child: const Text('More options'),
                    ),
                  const Spacer(),
                  if (onDownload != null)
                    FilledButton(
                      onPressed: onDownload,
                      child: Text(extraCount > 0 ? 'Select media' : 'Download'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatDuration(double seconds) {
    final total = seconds.round();
    final m = total ~/ 60;
    final s = total % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 88,
        height: 64,
        child: url == null
            ? ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Icon(Icons.movie_outlined),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                headers: const {'User-Agent': SocialHttpHeaders.userAgent},
                errorBuilder: (context, error, stack) => ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
      ),
    );
  }
}
