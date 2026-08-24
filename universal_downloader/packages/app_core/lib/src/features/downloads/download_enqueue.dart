import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_types/shared_types.dart';

import '../../providers/download_providers.dart';
import '../../providers/settings_provider.dart';
import 'apply_preferred_format.dart';
import 'media_selection_sheet.dart';

/// Shared enqueue path used by Home, Downloads, and intake.
Future<void> enqueueUrlFlow(
  BuildContext context,
  WidgetRef ref,
  String url, {
  String? fileName,
  DownloadPriority priority = DownloadPriority.normal,
  bool goToDownloads = true,
  MediaFormat? formatOverride,
}) async {
  try {
    final uri = Uri.tryParse(url);
    if (uri != null && ContentProviderRegistry.canHandle(uri)) {
      final settings = ref.read(settingsProvider);
      var resources = applyPreferredFormats(
        await discoverAllResources(ref, url),
        settings,
        override: formatOverride,
      );
      if (resources.length > 1 && context.mounted) {
        final selected = await MediaSelectionSheet.show(
          context,
          resources: resources,
          url: url,
        );
        if (selected == null || selected.isEmpty || !context.mounted) return;
        await enqueueMultipleDownloads(ref, selected, priority: priority);
        if (!context.mounted) return;
        if (goToDownloads) context.go(AppRoutes.downloads);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selected.length} downloads queued')),
        );
        return;
      }
      if (resources.length == 1) {
        await enqueueMultipleDownloads(ref, resources, priority: priority);
        if (!context.mounted) return;
        if (goToDownloads) context.go(AppRoutes.downloads);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Download queued')));
        return;
      }
    }

    await enqueueDownload(ref, url, fileName: fileName, priority: priority);
    if (!context.mounted) return;
    if (goToDownloads) context.go(AppRoutes.downloads);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Download queued')));
  } catch (error) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(DownloadErrorFormatter.fromObject(error))),
    );
  }
}
