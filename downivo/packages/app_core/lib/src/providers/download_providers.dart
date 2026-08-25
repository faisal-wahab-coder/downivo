import 'package:analytics/analytics.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';

import 'analytics_providers.dart';

final downloadManagerProvider = Provider<DownloadManager>((ref) {
  throw UnimplementedError('downloadManagerProvider must be overridden');
});

final contentProviderRegistryProvider = Provider<ContentProviderRegistry>((ref) {
  return ContentProviderRegistry();
});

final downloadTasksProvider = StreamProvider<List<DownloadTask>>((ref) {
  final manager = ref.watch(downloadManagerProvider);
  return manager.tasksStream;
});

final downloadListProvider = Provider<List<DownloadTask>>((ref) {
  final asyncTasks = ref.watch(downloadTasksProvider);
  return asyncTasks.maybeWhen(
    data: (tasks) => tasks,
    orElse: () => ref.read(downloadManagerProvider).tasks,
  );
});

Future<void> enqueueDownload(
  WidgetRef ref,
  String url, {
  String? fileName,
  DownloadPriority priority = DownloadPriority.normal,
}) async {
  final manager = ref.read(downloadManagerProvider);
  await manager.enqueue(url, fileName: fileName, priority: priority);
}

/// Discovers all downloadable resources for the given URL.
/// Returns multiple items for carousel/multi-media posts.
Future<List<DiscoveredResource>> discoverAllResources(
  WidgetRef ref,
  String url,
) async {
  final analytics = ref.read(analyticsServiceProvider);
  final registry = ref.read(contentProviderRegistryProvider);
  final uri = Uri.tryParse(url);
  if (uri == null) return const [];
  final social = SocialPlatform.fromUri(uri);
  final platform = AnalyticsPlatform.fromSocialName(social?.name, uri: url);
  if (social != null && !_resolverAllowed(analytics.remote, platform)) {
    analytics.track(AnalyticsEvent.resolveFailed, {
      AnalyticsProp.platform: platform,
      AnalyticsProp.resolverVersion: kResolverVersion,
      AnalyticsProp.errorCategory: ErrorCategory.unsupportedPlatform.wireValue,
    });
    throw StateError(
      RemoteConfigClient.disabledResolverMessage(platform) ??
          'This source is temporarily unavailable. Try again later.',
    );
  }

  analytics.setLastAction('Resolve');
  analytics.track(AnalyticsEvent.resolveStarted, {
    AnalyticsProp.platform: platform,
    AnalyticsProp.resolverVersion: kResolverVersion,
  });
  final trace = await analytics.traces.start('resolver');
  final watch = Stopwatch()..start();
  try {
    final resources = await registry.discoverAll(uri);
    watch.stop();
    if (resources.isEmpty) {
      analytics.track(AnalyticsEvent.resolveFailed, {
        AnalyticsProp.platform: platform,
        AnalyticsProp.resolverVersion: kResolverVersion,
        AnalyticsProp.errorCategory: ErrorCategory.mediaUnavailable.wireValue,
      });
    } else {
      analytics.track(AnalyticsEvent.resolveSuccess, {
        AnalyticsProp.platform: platform,
        AnalyticsProp.mediaType: mediaTypeFromKind(
          resources.first.resolvedKind.name,
          mimeType: resources.first.mimeType,
        ),
        AnalyticsProp.resolverVersion: kResolverVersion,
        AnalyticsProp.downloadDuration: watch.elapsedMilliseconds,
      });
    }
    return resources;
  } catch (error) {
    analytics.track(AnalyticsEvent.resolveFailed, {
      AnalyticsProp.platform: platform,
      AnalyticsProp.resolverVersion: kResolverVersion,
      AnalyticsProp.errorCategory: ErrorCategory.fromMessage(
        error.toString(),
      ).wireValue,
    });
    rethrow;
  } finally {
    await trace.stop();
  }
}

bool _resolverAllowed(RemoteAppConfig remote, String platform) {
  if (platform == AnalyticsPlatform.youtubeShorts) {
    return remote.isResolverEnabled(AnalyticsPlatform.youtubeShorts) &&
        remote.isResolverEnabled(AnalyticsPlatform.youtube);
  }
  if (platform == AnalyticsPlatform.x) {
    return remote.isResolverEnabled(AnalyticsPlatform.x);
  }
  return remote.isResolverEnabled(platform);
}

/// Enqueues multiple resources as individual download tasks.
Future<void> enqueueMultipleDownloads(
  WidgetRef ref,
  List<DiscoveredResource> resources, {
  DownloadPriority priority = DownloadPriority.normal,
}) async {
  final manager = ref.read(downloadManagerProvider);
  for (final resource in resources) {
    await manager.enqueue(
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
}

Future<void> pauseDownload(WidgetRef ref, String id) =>
    ref.read(downloadManagerProvider).pause(id);

Future<void> cancelDownload(WidgetRef ref, String id) =>
    ref.read(downloadManagerProvider).cancel(id);

Future<void> retryDownload(WidgetRef ref, String id) =>
    ref.read(downloadManagerProvider).retry(id);

Future<void> resumeDownload(WidgetRef ref, String id) =>
    ref.read(downloadManagerProvider).resume(id);

Future<void> pauseAllDownloads(WidgetRef ref) =>
    ref.read(downloadManagerProvider).pauseAll();

Future<void> resumeAllDownloads(WidgetRef ref) =>
    ref.read(downloadManagerProvider).resumeAll();

Future<void> reorderQueue(WidgetRef ref, List<String> orderedIds) =>
    ref.read(downloadManagerProvider).reorderQueue(orderedIds);

Future<int> clearDownloadHistory(WidgetRef ref) =>
    ref.read(downloadManagerProvider).clearHistory();

/// Finished downloads for the history screen (FR-049).
final downloadHistoryProvider = Provider<List<DownloadTask>>((ref) {
  final tasks = ref.watch(downloadListProvider);
  const historyStatuses = {
    DownloadStatus.completed,
    DownloadStatus.failed,
    DownloadStatus.cancelled,
  };
  return tasks
      .where((task) => historyStatuses.contains(task.status))
      .toList()
    ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
});
