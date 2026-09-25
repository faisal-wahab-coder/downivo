import 'package:analytics/analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:media_library/media_library.dart';
import 'package:shared_types/shared_types.dart';
import 'package:universal_viewer/universal_viewer.dart';

import '../../providers/analytics_providers.dart';
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
  ref.read(analyticsServiceProvider).track(AnalyticsEvent.downloadOpened);
  ref.read(analyticsServiceProvider).setLastAction('OpenFile');
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
  ref.read(analyticsServiceProvider).track(AnalyticsEvent.downloadShared);
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

Future<void> openLibraryFileWithChooserUi(
  BuildContext context,
  WidgetRef ref,
  LibraryFile file,
) async {
  ref.read(analyticsServiceProvider).track(AnalyticsEvent.openFileClicked);
  final result = await ref.read(mediaLibraryServiceProvider).openWith(file);
  if (context.mounted && !result.success && result.message.isNotEmpty) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(result.message)));
  }
}

/// Opens the in-app Files folder that contains [file].
void revealLibraryFile(BuildContext context, WidgetRef ref, LibraryFile file) {
  final location = ref
      .read(mediaLibraryServiceProvider)
      .locationContaining(file);
  final query = ref.read(libraryQueryProvider);
  if (query.search.isNotEmpty) {
    ref.read(libraryQueryProvider.notifier).state = query.copyWith(search: '');
  }
  ref.read(libraryLocationProvider.notifier).state = location;

  final router = GoRouter.maybeOf(context);
  if (router == null) return;
  final path = router.state.uri.path;
  if (path.startsWith(AppRoutes.files)) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    return;
  }
  router.go(AppRoutes.files);
}
