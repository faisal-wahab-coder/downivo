import 'package:analytics/analytics.dart';
import 'package:content_intake/content_intake.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_types/shared_types.dart';
import 'package:storage/storage.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/browser_providers.dart';
import '../../providers/settings_provider.dart';
import '../../providers/intake_providers.dart';
import '../../providers/library_providers.dart';
import '../downloads/download_enqueue.dart';
import '../downloads/download_wizard_dialog.dart';

/// Executes intake actions from clipboard, share, and QR flows.
class IntakeActionHandler {
  const IntakeActionHandler._();

  static Future<void> handle(
    BuildContext context,
    WidgetRef ref,
    IntakeAction action,
  ) async {
    switch (action.type) {
      case IntakeActionType.download:
        if (action.url == null) return;
        ref.read(analyticsServiceProvider).screen(AnalyticsScreen.urlInput);
        final result = await DownloadWizardDialog.show(
          context,
          initialUrl: action.url,
          initialFormat: ref.read(settingsProvider).preferredFormat,
        );
        if (result == null || !context.mounted) return;
        await enqueueUrlFlow(
          context,
          ref,
          result.url,
          fileName: result.fileName,
          priority: result.priority,
          preferredFormat: result.format,
          goToDownloads: true,
        );
      case IntakeActionType.openInBrowser:
        if (action.url == null) return;
        ref.read(pendingBrowserUrlProvider.notifier).state = action.url;
        ref.read(browserSessionProvider.notifier).navigateActiveTab(action.url!);
        if (context.mounted) context.go(AppRoutes.browser);
      case IntakeActionType.importFiles:
        await _importFiles(context, ref, action.filePaths);
      case IntakeActionType.showText:
        if (!context.mounted || action.text == null) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Content'),
            content: SingleChildScrollView(child: Text(action.text!)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
    }
  }

  static Future<void> _importFiles(
    BuildContext context,
    WidgetRef ref,
    List<String> paths,
  ) async {
    if (paths.isEmpty) return;
    final service = ref.read(mediaLibraryServiceProvider);
    var imported = 0;

    for (final path in paths) {
      try {
        await service.importExternalFile(path, StorageCategory.qrDownloads);
        imported++;
      } on Object {
        continue;
      }
    }

    invalidateLibrary(ref);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            imported > 0
                ? 'Imported $imported file${imported == 1 ? '' : 's'}'
                : 'Could not import shared files',
          ),
        ),
      );
    }
  }
}
