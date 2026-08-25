import 'package:analytics/analytics.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_utils/shared_utils.dart';
import 'package:storage/storage.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/library_providers.dart';
import 'image_gallery_screen.dart';
import 'open_managed_media.dart';

Future<void> showFileActionsSheet({
  required BuildContext context,
  required WidgetRef ref,
  required LibraryFile file,
  required Future<void> Function() onChanged,
  VoidCallback? onDeleted,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => FileActionsSheet(
      file: file,
      hostContext: context,
      hostRef: ref,
      onChanged: onChanged,
      onDeleted: onDeleted,
    ),
  );
}

Future<bool> confirmAndDeleteLibraryFile({
  required BuildContext context,
  required WidgetRef ref,
  required LibraryFile file,
  required Future<void> Function() onChanged,
  BuildContext? messengerContext,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete file?'),
      content: Text('Delete "${file.name}" permanently?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirmed != true || !context.mounted) return false;

  ref.read(analyticsServiceProvider).track(AnalyticsEvent.downloadDeleted);
  await ref.read(mediaLibraryServiceProvider).delete(file);
  await onChanged();
  final messenger = messengerContext ?? context;
  if (messenger.mounted) {
    ScaffoldMessenger.of(
      messenger,
    ).showSnackBar(const SnackBar(content: Text('File deleted')));
  }
  return true;
}

class FileActionsSheet extends StatelessWidget {
  const FileActionsSheet({
    super.key,
    required this.file,
    required this.hostContext,
    required this.hostRef,
    required this.onChanged,
    this.onDeleted,
  });

  final LibraryFile file;
  final BuildContext hostContext;
  final WidgetRef hostRef;
  final Future<void> Function() onChanged;
  final VoidCallback? onDeleted;

  @override
  Widget build(BuildContext context) {
    final service = hostRef.read(mediaLibraryServiceProvider);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(UdmSpacing.lg),
        children: [
          Text(file.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: UdmSpacing.sm),
          Text(
            '${file.category.folderName} · ${TransferFormat.bytes(file.sizeBytes)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: UdmSpacing.lg),
          _ActionTile(
            icon: Icons.open_in_new,
            label: kIsWeb ? 'Save to disk' : 'Open',
            onTap: () async {
              Navigator.pop(context);
              if (hostContext.mounted) {
                if (file.isGalleryImage) {
                  await openImageGallery(
                    hostContext,
                    images: [file],
                    initial: file,
                  );
                } else {
                  await openLibraryFile(hostContext, hostRef, file);
                }
              }
            },
          ),
          _ActionTile(
            icon: Icons.share_outlined,
            label: 'Share',
            onTap: () async {
              Navigator.pop(context);
              hostRef.read(analyticsServiceProvider).track(AnalyticsEvent.shareClicked);
              await service.share(file);
            },
          ),
          if (!kIsWeb && file.canSaveToGallery)
            _ActionTile(
              icon: Icons.photo_library_outlined,
              label: 'Save to Gallery',
              onTap: () async {
                Navigator.pop(context);
                if (hostContext.mounted) {
                  await saveLibraryFileToGalleryUi(hostContext, hostRef, file);
                }
              },
            ),
          _ActionTile(
            icon: file.isFavorite ? Icons.star : Icons.star_border,
            label: file.isFavorite ? 'Remove favorite' : 'Add to favorites',
            onTap: () async {
              await service.toggleFavorite(file);
              await onChanged();
              if (context.mounted) Navigator.pop(context);
            },
          ),
          _ActionTile(
            icon: Icons.drive_file_rename_outline,
            label: 'Rename',
            onTap: () async {
              await _rename(context, service);
            },
          ),
          _ActionTile(
            icon: Icons.drive_file_move_outline,
            label: 'Move to category',
            onTap: () async {
              await _move(context, service);
            },
          ),
          _ActionTile(
            icon: Icons.delete_outline,
            label: 'Delete',
            destructive: true,
            onTap: () async {
              hostRef.read(analyticsServiceProvider).track(AnalyticsEvent.deleteClicked);
              final deleted = await confirmAndDeleteLibraryFile(
                context: context,
                ref: hostRef,
                file: file,
                onChanged: onChanged,
                messengerContext: hostContext,
              );
              if (deleted && context.mounted) Navigator.pop(context);
              if (deleted) onDeleted?.call();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rename(
    BuildContext sheetContext,
    MediaLibraryService service,
  ) async {
    final controller = TextEditingController(text: file.name);
    try {
      final newName = await showDialog<String>(
        context: sheetContext,
        builder: (context) => AlertDialog(
          title: const Text('Rename file'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'File name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (newName == null || !sheetContext.mounted) return;

      try {
        await service.rename(file, newName);
        await onChanged();
        if (sheetContext.mounted) Navigator.pop(sheetContext);
        if (hostContext.mounted) {
          ScaffoldMessenger.of(
            hostContext,
          ).showSnackBar(const SnackBar(content: Text('File renamed')));
        }
      } on ArgumentError catch (error) {
        if (sheetContext.mounted) {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Rename failed')),
          );
        }
      }
    } finally {
      controller.dispose();
    }
  }

  Future<void> _move(
    BuildContext sheetContext,
    MediaLibraryService service,
  ) async {
    final target = await showDialog<StorageCategory>(
      context: sheetContext,
      builder: (context) => SimpleDialog(
        title: const Text('Move to category'),
        children: MediaLibraryService.browsableCategories
            .where((c) => c != file.category)
            .map(
              (category) => SimpleDialogOption(
                onPressed: () => Navigator.pop(context, category),
                child: Text(category.folderName),
              ),
            )
            .toList(),
      ),
    );

    if (target == null || !sheetContext.mounted) return;

    await service.move(file, target);
    await onChanged();
    if (sheetContext.mounted) Navigator.pop(sheetContext);
    if (hostContext.mounted) {
      ScaffoldMessenger.of(
        hostContext,
      ).showSnackBar(SnackBar(content: Text('Moved to ${target.folderName}')));
    }
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? Theme.of(context).colorScheme.error : null;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }
}
