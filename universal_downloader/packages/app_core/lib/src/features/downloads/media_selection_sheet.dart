import 'package:design_system/design_system.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';

/// Bottom sheet that shows all discovered media items as a thumbnail grid.
/// All items are selected by default; user taps to deselect/reselect.
/// Returns the list of selected [DiscoveredResource] items, or null if cancelled.
class MediaSelectionSheet extends StatefulWidget {
  const MediaSelectionSheet({
    super.key,
    required this.resources,
    required this.url,
  });

  final List<DiscoveredResource> resources;
  final String url;

  static Future<List<DiscoveredResource>?> show(
    BuildContext context, {
    required List<DiscoveredResource> resources,
    required String url,
  }) {
    return showModalBottomSheet<List<DiscoveredResource>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => MediaSelectionSheet(resources: resources, url: url),
    );
  }

  @override
  State<MediaSelectionSheet> createState() => _MediaSelectionSheetState();
}

class _MediaSelectionSheetState extends State<MediaSelectionSheet> {
  late final List<bool> _selected;

  @override
  void initState() {
    super.initState();
    _selected = List.filled(widget.resources.length, true);
  }

  int get _selectedCount => _selected.where((s) => s).length;

  void _toggleAll() {
    final allSelected = _selected.every((s) => s);
    setState(() {
      for (var i = 0; i < _selected.length; i++) {
        _selected[i] = !allSelected;
      }
    });
  }

  void _submit() {
    final selected = <DiscoveredResource>[];
    for (var i = 0; i < widget.resources.length; i++) {
      if (_selected[i]) selected.add(widget.resources[i]);
    }
    Navigator.pop(context, selected);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
              child: Row(
                children: [
                  Icon(
                    Icons.photo_library_rounded,
                    color: colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select media',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${widget.resources.length} items · $_selectedCount selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _toggleAll,
                    icon: Icon(
                      _selected.every((s) => s)
                          ? Icons.deselect
                          : Icons.select_all,
                      size: 18,
                    ),
                    label: Text(_selected.every((s) => s) ? 'None' : 'All'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),

            // Thumbnail grid
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.85,
                ),
                itemCount: widget.resources.length,
                itemBuilder: (context, index) {
                  final resource = widget.resources[index];
                  final isVideo =
                      resource.mimeType?.startsWith('video') ?? false;
                  return _MediaThumbnailCard(
                    index: index + 1,
                    resource: resource,
                    isVideo: isVideo,
                    selected: _selected[index],
                    onToggle: () {
                      setState(() => _selected[index] = !_selected[index]);
                    },
                  );
                },
              ),
            ),

            // Action bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outlineVariant,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _selectedCount > 0 ? _submit : null,
                        icon: const Icon(Icons.download_rounded, size: 20),
                        label: Text(
                          _selectedCount == 1
                              ? 'Download 1 item'
                              : 'Download $_selectedCount items',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MediaThumbnailCard extends StatelessWidget {
  const _MediaThumbnailCard({
    required this.index,
    required this.resource,
    required this.isVideo,
    required this.selected,
    required this.onToggle,
  });

  final int index;
  final DiscoveredResource resource;
  final bool isVideo;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final thumbnailUrl = resource.thumbnailUrl ?? resource.directUrl;
    final isImageUrl = thumbnailUrl.startsWith('http');

    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: UdmMotion.of(context, const Duration(milliseconds: 200)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Thumbnail image
            if (isImageUrl && !resource.mimeType!.startsWith('video'))
              Image.network(
                thumbnailUrl,
                fit: BoxFit.cover,
                headers: const {'User-Agent': SocialHttpHeaders.userAgent},
                errorBuilder: (_, _, _) => _PlaceholderThumbnail(
                  isVideo: isVideo,
                  colorScheme: colorScheme,
                ),
              )
            else if (isImageUrl && resource.thumbnailUrl != null)
              Image.network(
                resource.thumbnailUrl!,
                fit: BoxFit.cover,
                headers: const {'User-Agent': SocialHttpHeaders.userAgent},
                errorBuilder: (_, _, _) => _PlaceholderThumbnail(
                  isVideo: isVideo,
                  colorScheme: colorScheme,
                ),
              )
            else
              _PlaceholderThumbnail(isVideo: isVideo, colorScheme: colorScheme),

            // Kind / duration overlay
            Positioned(
              top: 6,
              left: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  [
                    resource.resolvedKind.label,
                    if (resource.durationSeconds != null)
                      _formatDuration(resource.durationSeconds!),
                    if (resource.resolutionLabel != null)
                      resource.resolutionLabel!,
                  ].join(' · '),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Selection checkbox overlay
            Positioned(
              top: 6,
              right: 6,
              child: AnimatedContainer(
                duration: UdmMotion.of(
                  context,
                  const Duration(milliseconds: 150),
                ),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected
                      ? colorScheme.primary
                      : Colors.black.withValues(alpha: 0.5),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: selected
                    ? const Icon(Icons.check, color: Colors.white, size: 14)
                    : null,
              ),
            ),

            // Dim overlay when deselected
            if (!selected)
              Container(color: Colors.black.withValues(alpha: 0.4)),

            // Bottom label
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                  ),
                ),
                child: Text(
                  resource.title?.trim().isNotEmpty == true
                      ? resource.title!
                      : '${resource.resolvedKind.label} $index',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderThumbnail extends StatelessWidget {
  const _PlaceholderThumbnail({
    required this.isVideo,
    required this.colorScheme,
  });

  final bool isVideo;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isVideo
          ? colorScheme.tertiaryContainer
          : colorScheme.secondaryContainer,
      child: Center(
        child: Icon(
          isVideo ? Icons.videocam_rounded : Icons.image_rounded,
          size: 36,
          color: isVideo
              ? colorScheme.onTertiaryContainer
              : colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }
}

String _formatDuration(double seconds) {
  final total = seconds.round();
  final m = total ~/ 60;
  final s = total % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
