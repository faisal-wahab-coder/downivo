import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:universal_viewer/universal_viewer.dart';

import '../../providers/library_providers.dart';

bool canSaveManagedMediaToGallery(String path, String? mimeType) {
  if (kIsWeb) return false;
  return isGallerySaveable(path: path, mimeType: mimeType);
}

Future<void> openManagedMedia(
  BuildContext context,
  WidgetRef ref, {
  required String path,
  required String title,
  String? mimeType,
}) async {
  if (UniversalViewerScreen.canPlay(path, mimeType)) {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            UniversalViewerScreen(path: path, title: title, mimeType: mimeType),
      ),
    );
    return;
  }

  final service = ref.read(mediaLibraryServiceProvider);
  final file = await service.fileAt(path);
  if (file == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found on disk.')));
    }
    return;
  }
  final result = await service.open(file);
  if (context.mounted && !result.success && result.message.isNotEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }
}

Future<void> shareManagedMedia(
  BuildContext context,
  WidgetRef ref, {
  required String path,
}) async {
  final service = ref.read(mediaLibraryServiceProvider);
  final file = await service.fileAt(path);
  if (file == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found on disk.')));
    }
    return;
  }
  await service.share(file);
}

Future<void> saveManagedMediaToGallery(
  BuildContext context,
  WidgetRef ref, {
  required String path,
}) async {
  final service = ref.read(mediaLibraryServiceProvider);
  final file = await service.fileAt(path);
  if (file == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found on disk.')));
    }
    return;
  }
  if (!context.mounted) return;
  await saveLibraryFileToGalleryUi(context, ref, file);
}

Future<void> saveLibraryFileToGalleryUi(
  BuildContext context,
  WidgetRef ref,
  LibraryFile file,
) async {
  final service = ref.read(mediaLibraryServiceProvider);
  final result = await service.saveToGallery(file);
  if (!context.mounted) return;
  final message = result.message.isNotEmpty
      ? result.message
      : (result.success ? 'Saved to Gallery' : 'Could not save to Gallery');
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> openLibraryFile(
  BuildContext context,
  WidgetRef ref,
  LibraryFile file,
) {
  return openManagedMedia(
    context,
    ref,
    path: file.path,
    title: file.name,
    mimeType: file.mimeType,
  );
}
