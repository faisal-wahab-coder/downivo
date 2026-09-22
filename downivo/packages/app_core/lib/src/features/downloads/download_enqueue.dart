import 'package:analytics/analytics.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_types/shared_types.dart';

import '../../providers/analytics_providers.dart';
import '../../providers/download_providers.dart';
import '../../providers/settings_provider.dart';
import 'apply_preferred_format.dart';
import 'format_picker_sheet.dart';
import 'media_selection_sheet.dart';

/// Omitted format argument. Distinct from null, which means Any for this download.
const _formatUnset = Object();

/// Shared enqueue path used by Home, Downloads, browser, and intake.
///
/// Social links show a Preparing row immediately. Finding the file URL
/// continues after the Downloads tab is open.
Future<void> enqueueUrlFlow(
  BuildContext context,
  WidgetRef ref,
  String url, {
  String? fileName,
  DownloadPriority priority = DownloadPriority.normal,
  bool goToDownloads = true,
  MediaFormat? formatOverride,
  List<DiscoveredResource>? resolvedResources,
  Object? preferredFormat = _formatUnset,
}) async {
  final analytics = ref.read(analyticsServiceProvider);
  analytics.setLastAction('StartDownload');
  analytics.track(AnalyticsEvent.downloadButtonClicked);
  final uri = Uri.tryParse(url);
  final socialName = uri == null ? null : SocialPlatform.fromUri(uri)?.name;
  final platform = AnalyticsPlatform.fromSocialName(socialName, uri: url);
  analytics.track(AnalyticsEvent.urlPasted, {
    AnalyticsProp.platform: platform,
  });
  if (uri != null && SocialPlatform.fromUri(uri) != null) {
    analytics.track(AnalyticsEvent.platformDetected, {
      AnalyticsProp.platform: platform,
    });
  }

  final known = resolvedResources;
  if (known != null && known.isNotEmpty) {
    await _enqueueKnownResources(
      context,
      ref,
      url,
      known,
      priority: priority,
      goToDownloads: goToDownloads,
      formatOverride: formatOverride,
      preferredFormat: preferredFormat,
    );
    return;
  }

  if (uri != null && ContentProviderRegistry.canHandle(uri)) {
    await _enqueueSocialImmediately(
      context,
      ref,
      uri,
      fileName: fileName,
      priority: priority,
      goToDownloads: goToDownloads,
      formatOverride: formatOverride,
      preferredFormat: preferredFormat,
    );
    return;
  }

  try {
    await enqueueDownload(ref, url, fileName: fileName, priority: priority);
    if (!context.mounted) return;
    _openDownloads(context, goToDownloads, 'Download queued');
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, DownloadErrorFormatter.fromObject(error));
  }
}

Future<void> _enqueueSocialImmediately(
  BuildContext context,
  WidgetRef ref,
  Uri uri, {
  String? fileName,
  required DownloadPriority priority,
  required bool goToDownloads,
  MediaFormat? formatOverride,
  Object? preferredFormat = _formatUnset,
}) async {
  final manager = ref.read(downloadManagerProvider);
  final platform = SocialPlatform.fromUri(uri);
  final placeholder = fileName?.trim().isNotEmpty == true
      ? fileName!.trim()
      : platform == null
          ? 'download_pending'
          : '${platform.label} video';
  final task = await manager.enqueue(
    uri.toString(),
    fileName: placeholder,
    platform: platform?.label,
    title: platform?.label,
    priority: priority,
    initialStatus: DownloadStatus.preparing,
  );
  if (!context.mounted) return;
  final router = GoRouter.of(context);
  _openDownloads(context, goToDownloads, 'Finding video…');

  try {
    final effective = _settingsForEnqueue(ref, preferredFormat);
    ref.read(analyticsServiceProvider).screen(AnalyticsScreen.resolution);
    var resources = await discoverAllResources(ref, uri.toString());
    if (_preparedWasClosed(manager, task.id)) return;

    final sheetContext = _routerContext(router);
    var picked = formatOverride;
    if (resources.length == 1 &&
        picked == null &&
        AudioDownloadOption.shouldAutoPrompt(resources.first.formats) &&
        sheetContext != null) {
      final resource = resources.first;
      final skipPicker =
          !TikTokResolver.isWatermarkChoice(resource.formats) &&
          explicitPreferredFormat(resource, effective) != null;
      if (!skipPicker && sheetContext.mounted) {
        picked = await FormatPickerSheet.show(
          sheetContext,
          formats: resource.formats,
          selectedUrl: resource.directUrl,
        );
        if (picked == null) {
          await manager.cancel(task.id);
          return;
        }
        ref.read(analyticsServiceProvider).track(AnalyticsEvent.qualityChanged, {
          AnalyticsProp.quality: picked.label,
        });
      }
    }
    if (_preparedWasClosed(manager, task.id)) return;
    resources = applyPreferredFormats(resources, effective, override: picked);
    if (resources.isEmpty) {
      await manager.failDownload(
        task.id,
        'Could not find a downloadable file for this link.',
      );
      return;
    }

    if (resources.length > 1) {
      var selected = resources;
      final chooser = _routerContext(router);
      if (chooser != null && chooser.mounted) {
        ref.read(analyticsServiceProvider).screen(AnalyticsScreen.mediaSelection);
        final choice = await MediaSelectionSheet.show(
          chooser,
          resources: resources,
          url: uri.toString(),
        );
        if (choice == null || choice.isEmpty) {
          await manager.cancel(task.id);
          return;
        }
        selected = choice;
      }
      if (_preparedWasClosed(manager, task.id)) return;
      await manager.startPreparedDownload(
        task.id,
        url: selected.first.directUrl,
        fileName: selected.first.fileName,
        thumbnailUrl: selected.first.thumbnailUrl,
        platform: selected.first.platform,
        title: selected.first.title,
        mimeType: selected.first.mimeType,
        requestHeaders: selected.first.requestHeaders,
      );
      for (final extra in selected.skip(1)) {
        await _enqueueResource(ref, extra, priority: priority);
      }
      return;
    }

    final resource = resources.first;
    await manager.startPreparedDownload(
      task.id,
      url: resource.directUrl,
      fileName: resource.fileName,
      thumbnailUrl: resource.thumbnailUrl,
      platform: resource.platform,
      title: resource.title,
      mimeType: resource.mimeType,
      requestHeaders: resource.requestHeaders,
    );
  } catch (error) {
    if (_preparedWasClosed(manager, task.id)) return;
    await manager.failDownload(
      task.id,
      DownloadErrorFormatter.fromObject(error),
    );
  }
}

Future<void> _enqueueKnownResources(
  BuildContext context,
  WidgetRef ref,
  String url,
  List<DiscoveredResource> resources, {
  required DownloadPriority priority,
  required bool goToDownloads,
  MediaFormat? formatOverride,
  Object? preferredFormat = _formatUnset,
}) async {
  try {
    final effective = _settingsForEnqueue(ref, preferredFormat);
    var picked = formatOverride;
    if (resources.length == 1 &&
        picked == null &&
        AudioDownloadOption.shouldAutoPrompt(resources.first.formats) &&
        context.mounted) {
      final resource = resources.first;
      final skipPicker =
          !TikTokResolver.isWatermarkChoice(resource.formats) &&
          explicitPreferredFormat(resource, effective) != null;
      if (!skipPicker) {
        picked = await FormatPickerSheet.show(
          context,
          formats: resource.formats,
          selectedUrl: resource.directUrl,
        );
        if (picked == null || !context.mounted) return;
      }
    }
    final resolved = applyPreferredFormats(
      resources,
      effective,
      override: picked,
    );
    if (resolved.length > 1 && context.mounted) {
      final selected = await MediaSelectionSheet.show(
        context,
        resources: resolved,
        url: url,
      );
      if (selected == null || selected.isEmpty || !context.mounted) return;
      await enqueueMultipleDownloads(ref, selected, priority: priority);
      if (!context.mounted) return;
      _openDownloads(
        context,
        goToDownloads,
        '${selected.length} downloads queued',
      );
      return;
    }
    if (resolved.isEmpty) return;
    await enqueueMultipleDownloads(ref, resolved, priority: priority);
    if (!context.mounted) return;
    _openDownloads(context, goToDownloads, 'Download queued');
  } catch (error) {
    if (!context.mounted) return;
    _showMessage(context, DownloadErrorFormatter.fromObject(error));
  }
}

Future<void> _enqueueResource(
  WidgetRef ref,
  DiscoveredResource resource, {
  required DownloadPriority priority,
}) {
  return ref.read(downloadManagerProvider).enqueue(
    resource.directUrl,
    fileName: resource.fileName,
    priority: priority,
    thumbnailUrl: resource.thumbnailUrl,
    platform: resource.platform,
    title: resource.title,
    mimeType: resource.mimeType,
    requestHeaders: resource.requestHeaders,
  );
}

/// Settings for this enqueue. An explicit format, including null for Any,
/// replaces the saved preference without writing it.
AppSettings _settingsForEnqueue(WidgetRef ref, Object? preferredFormat) {
  final settings = ref.read(settingsProvider);
  final remote = ref.read(analyticsServiceProvider).remote;
  final withQuality = settings.copyWith(
    preferredQuality: settings.preferredQuality ?? remote.defaultQuality,
  );
  if (identical(preferredFormat, _formatUnset)) return withQuality;
  return withQuality.copyWith(preferredFormat: preferredFormat as String?);
}

bool _preparedWasClosed(DownloadManager manager, String id) {
  for (final task in manager.tasks) {
    if (task.id != id) continue;
    return task.status == DownloadStatus.cancelled ||
        task.status == DownloadStatus.paused;
  }
  return true;
}

BuildContext? _routerContext(GoRouter router) {
  final overlay = router.routerDelegate.navigatorKey.currentContext;
  if (overlay != null && overlay.mounted) return overlay;
  return null;
}

void _openDownloads(BuildContext context, bool goToDownloads, String message) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (goToDownloads) context.go(AppRoutes.downloads);
  messenger?.showSnackBar(SnackBar(content: Text(message)));
}

void _showMessage(BuildContext context, String message) {
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
