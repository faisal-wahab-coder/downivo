import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:storage/storage.dart';

import '../../providers/library_providers.dart';

Future<String?> promptFolderName(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => const _FolderNameDialog(),
  );
}

class _FolderNameDialog extends StatefulWidget {
  const _FolderNameDialog();

  @override
  State<_FolderNameDialog> createState() => _FolderNameDialogState();
}

class _FolderNameDialogState extends State<_FolderNameDialog> {
  late final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New folder'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(labelText: 'Folder name'),
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.pop(context, value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Create'),
        ),
      ],
    );
  }
}

/// Creates a folder in the current Files location.
Future<void> createFolderInCurrentLocation(
  BuildContext context,
  WidgetRef ref,
) async {
  final location = ref.read(libraryLocationProvider);
  if (location is! LibraryFolderLocation) return;
  final name = await promptFolderName(context);
  if (name == null || !context.mounted) return;
  try {
    await ref
        .read(mediaLibraryServiceProvider)
        .createFolder(
          category: location.category,
          name: name,
          parentRelativePath: location.relativeSubPath,
        );
    invalidateLibrary(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Created folder ${name.trim()}')));
    }
  } on ArgumentError catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Could not create folder')),
      );
    }
  }
}

Future<void> showMoveToFolderSheet({
  required BuildContext context,
  required WidgetRef ref,
  required List<LibraryFile> files,
  required Future<void> Function() onChanged,
}) {
  if (files.isEmpty) return Future.value();
  final categories = files.map((file) => file.category).toSet();
  if (categories.length != 1) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select files from one category to move them together.'),
      ),
    );
    return Future.value();
  }

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => _MoveToFolderSheet(
      files: files,
      category: categories.single,
      hostContext: context,
      hostRef: ref,
      onChanged: onChanged,
    ),
  );
}

class _MoveToFolderSheet extends ConsumerStatefulWidget {
  const _MoveToFolderSheet({
    required this.files,
    required this.category,
    required this.hostContext,
    required this.hostRef,
    required this.onChanged,
  });

  final List<LibraryFile> files;
  final StorageCategory category;
  final BuildContext hostContext;
  final WidgetRef hostRef;
  final Future<void> Function() onChanged;

  @override
  ConsumerState<_MoveToFolderSheet> createState() => _MoveToFolderSheetState();
}

class _MoveToFolderSheetState extends ConsumerState<_MoveToFolderSheet> {
  List<String>? _folders;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final folders = await widget.hostRef
          .read(mediaLibraryServiceProvider)
          .userFolderPaths(widget.category);
      if (mounted) setState(() => _folders = folders);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final folders = _folders;
    final title = widget.files.length == 1
        ? widget.files.single.name
        : '${widget.files.length} files';

    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          children: [
            ListTile(title: const Text('Move to'), subtitle: Text(title)),
            ListTile(
              leading: const Icon(Icons.create_new_folder_outlined),
              title: const Text('New folder'),
              onTap: _createAndMove,
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: Text(widget.category.folderName),
              subtitle: const Text('Category folder'),
              onTap: () => _move(relativeFolderPath: ''),
            ),
            if (_error != null)
              ListTile(title: Text('Could not load folders: $_error')),
            if (folders == null && _error == null)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (folders != null)
              for (final relative in folders)
                ListTile(
                  leading: const Icon(Icons.folder_outlined),
                  title: Text(_label(relative)),
                  onTap: () => _move(relativeFolderPath: relative),
                ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Other categories',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
            for (final category in MediaLibraryService.browsableCategories)
              if (category != widget.category)
                ListTile(
                  leading: const Icon(Icons.drive_file_move_outline),
                  title: Text(category.folderName),
                  onTap: () => _moveCategory(category),
                ),
          ],
        ),
      ),
    );
  }

  String _label(String relative) =>
      '${widget.category.folderName} / ${relative.replaceAll('/', ' / ')}';

  Future<void> _createAndMove() async {
    final name = await promptFolderName(context);
    if (name == null || !mounted) return;
    final location = widget.hostRef.read(libraryLocationProvider);
    final parent =
        location is LibraryFolderLocation &&
            location.category == widget.category
        ? location.relativeSubPath
        : '';
    try {
      final folder = await widget.hostRef
          .read(mediaLibraryServiceProvider)
          .createFolder(
            category: widget.category,
            name: name,
            parentRelativePath: parent,
          );
      await _move(relativeFolderPath: folder.location.relativeSubPath);
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Could not create folder')),
        );
      }
    }
  }

  Future<void> _move({required String relativeFolderPath}) async {
    final service = widget.hostRef.read(mediaLibraryServiceProvider);
    var moved = 0;
    try {
      for (final file in widget.files) {
        final result = await service.moveToFolder(
          file,
          category: widget.category,
          relativeFolderPath: relativeFolderPath,
        );
        if (result.path != file.path) moved++;
      }
    } on ArgumentError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message ?? 'Could not move files')),
        );
      }
      return;
    }
    await widget.onChanged();
    if (mounted) Navigator.pop(context);
    final host = widget.hostContext;
    if (host.mounted) {
      final destination = relativeFolderPath.isEmpty
          ? widget.category.folderName
          : _label(relativeFolderPath);
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(
          content: Text(
            moved == 0 ? 'Already in $destination' : 'Moved to $destination',
          ),
        ),
      );
    }
  }

  Future<void> _moveCategory(StorageCategory category) async {
    final service = widget.hostRef.read(mediaLibraryServiceProvider);
    for (final file in widget.files) {
      await service.move(file, category);
    }
    await widget.onChanged();
    if (mounted) Navigator.pop(context);
    final host = widget.hostContext;
    if (host.mounted) {
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(content: Text('Moved to ${category.folderName}')),
      );
    }
  }
}
