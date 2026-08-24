import 'storage_info.dart';
import 'storage_paths.dart';

Future<StorageInfo> loadStorageInfoForPlatform(StoragePaths paths) async {
  return StorageInfo(
    rootPath: paths.rootPath,
    freeBytes: 0,
    totalBytes: 0,
  );
}
