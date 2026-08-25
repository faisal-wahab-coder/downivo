import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_library/media_library.dart';
import 'package:storage/storage.dart';

import '../features/files/library_source_index.dart';
import 'app_providers.dart';
import 'download_providers.dart';
import 'performance_providers.dart';

final storagePathsProvider = Provider<StoragePaths>((ref) {
  return StoragePaths(rootPath: ref.watch(storagePathProvider));
});

final favoritesStoreProvider = Provider<FavoritesStore>((ref) {
  return FavoritesStore(ref.watch(sharedPreferencesProvider));
});

final importTrackerProvider = Provider<ImportTracker>((ref) {
  return ImportTracker(ref.watch(sharedPreferencesProvider));
});

final mediaLibraryServiceProvider = Provider<MediaLibraryService>((ref) {
  final performance = ref.watch(performanceManagerProvider);
  final initializer = ref.watch(appInitializerProvider);
  return MediaLibraryService(
    paths: ref.watch(storagePathsProvider),
    favorites: ref.watch(favoritesStoreProvider),
    fileStore: initializer.fileStore,
    importTracker: ref.watch(importTrackerProvider),
    sourceIndex: () => downloadLibrarySourceIndex(initializer.appDatabase),
    onPathMoved: (from, to) => initializer.appDatabase.updateDownloadFilePath(
      oldPath: from,
      newPath: to,
    ),
    onFileDeleted: (path) =>
        ref.read(downloadManagerProvider).detachLibraryFile(path),
    onScanCacheLookup: ({required hit}) => performance.recordScan(hit: hit),
  );
});

final libraryQueryProvider = StateProvider<LibraryQuery>(
  (ref) => const LibraryQuery(),
);

final libraryLocationProvider = StateProvider<LibraryLocation>(
  (ref) => const LibraryRootLocation(),
);

final libraryBrowseProvider = FutureProvider.autoDispose<LibraryBrowsePage>((
  ref,
) async {
  final service = ref.watch(mediaLibraryServiceProvider);
  final location = ref.watch(libraryLocationProvider);
  final query = ref.watch(libraryQueryProvider);
  return service.browse(location, query: query);
});

final libraryFilesProvider = FutureProvider.autoDispose<List<LibraryFile>>((
  ref,
) async {
  final service = ref.watch(mediaLibraryServiceProvider);
  final query = ref.watch(libraryQueryProvider);
  return service.listFiles(query);
});

final categorySummariesProvider = FutureProvider<List<CategorySummary>>((
  ref,
) async {
  final service = ref.watch(mediaLibraryServiceProvider);
  return service.categorySummaries();
});

final managedStorageStatsProvider = FutureProvider<(int files, int bytes)>((
  ref,
) async {
  final service = ref.watch(mediaLibraryServiceProvider);
  final files = await service.totalManagedFileCount();
  final bytes = await service.totalManagedBytes();
  return (files, bytes);
});

final volumeStatsProvider = FutureProvider<StorageInfo>((ref) async {
  return StorageInfo.load(ref.watch(storagePathsProvider));
});

final pendingImportsProvider = FutureProvider.autoDispose<List<PendingImport>>((
  ref,
) async {
  final service = ref.watch(mediaLibraryServiceProvider);
  return service.detectPendingImports();
});

final libraryFileProvider = FutureProvider.family<LibraryFile?, String>((
  ref,
  path,
) async {
  final service = ref.watch(mediaLibraryServiceProvider);
  return service.fileAt(path);
});

void invalidateLibrary(WidgetRef ref) {
  ref.read(mediaLibraryServiceProvider).invalidateScanCache();
  ref.invalidate(libraryBrowseProvider);
  ref.invalidate(libraryFilesProvider);
  ref.invalidate(categorySummariesProvider);
  ref.invalidate(managedStorageStatsProvider);
  ref.invalidate(pendingImportsProvider);
  ref.invalidate(volumeStatsProvider);
}
