import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_utils/shared_utils.dart';

import '../../providers/library_providers.dart';
import 'file_actions_sheet.dart';
import 'file_thumbnail.dart';

class FileDetailScreen extends ConsumerWidget {
  const FileDetailScreen({super.key, required this.filePath});

  final String filePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fileAsync = ref.watch(libraryFileProvider(filePath));

    return fileAsync.when(
      loading: () => const UdmScaffold(
        title: 'File details',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => UdmScaffold(
        title: 'File details',
        body: EmptyState(
          icon: Icons.error_outline,
          title: 'Could not load file',
          subtitle: error.toString(),
        ),
      ),
      data: (file) {
        if (file == null) {
          return const UdmScaffold(
            title: 'File details',
            body: EmptyState(
              icon: Icons.folder_off_outlined,
              title: 'File not found',
              subtitle: 'This file may have been moved or deleted.',
            ),
          );
        }

        return UdmScaffold(
          title: file.name,
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert),
              tooltip: 'More actions',
              onPressed: () => _openActions(context, ref, file),
            ),
          ],
          body: ListView(
            padding: const EdgeInsets.all(UdmSpacing.lg),
            children: [
              Center(child: FileThumbnail(file: file, size: 160)),
              const SizedBox(height: UdmSpacing.xl),
              _DetailRow(label: 'Name', value: file.name),
              _DetailRow(label: 'Source', value: file.source.label),
              _DetailRow(label: 'Category', value: file.category.folderName),
              _DetailRow(
                label: 'Size',
                value: TransferFormat.bytes(file.sizeBytes),
              ),
              _DetailRow(
                label: 'Modified',
                value: _formatDateTime(file.modifiedAt),
              ),
              _DetailRow(label: 'Type', value: file.mimeType ?? file.extension),
              _DetailRow(label: 'Location', value: file.path),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openActions(
    BuildContext context,
    WidgetRef ref,
    LibraryFile file,
  ) async {
    await showFileActionsSheet(
      context: context,
      ref: ref,
      file: file,
      onChanged: () async {
        invalidateLibrary(ref);
        ref.invalidate(libraryFileProvider(filePath));
      },
      onDeleted: () {
        if (context.mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  String _formatDateTime(DateTime date) {
    final local = date.toLocal();
    final datePart =
        '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
    final timePart =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    return '$datePart $timePart';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: UdmSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: UdmSpacing.xs),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
