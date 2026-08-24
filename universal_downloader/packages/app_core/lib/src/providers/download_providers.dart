import 'package:download_engine/download_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_types/shared_types.dart';

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
  final registry = ref.read(contentProviderRegistryProvider);
  final uri = Uri.tryParse(url);
  if (uri == null) return const [];
  return registry.discoverAll(uri);
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
