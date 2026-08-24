import 'storage_info.dart';
import 'storage_paths.dart';
import 'storage_info_load_stub.dart'
    if (dart.library.io) 'storage_info_load_io.dart'
    if (dart.library.html) 'storage_info_load_web.dart';

Future<StorageInfo> loadStorageInfo(StoragePaths paths) {
  return loadStorageInfoForPlatform(paths);
}
