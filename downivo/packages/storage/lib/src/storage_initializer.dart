import 'file_store/file_store.dart';
import 'file_store/file_store_factory.dart';
import 'storage_category.dart';
import 'storage_paths.dart';

class StorageInitializer {
  StorageInitializer({FileStore? fileStore})
      : fileStore = fileStore ?? createFileStore();

  final FileStore fileStore;

  Future<StoragePaths> initialize() async {
    await fileStore.initialize();
    final paths = await StoragePaths.resolve();
    await fileStore.createDirectory(paths.rootPath);
    for (final category in StorageCategory.values) {
      await fileStore.createDirectory(paths.categoryPath(category));
    }
    return paths;
  }
}
