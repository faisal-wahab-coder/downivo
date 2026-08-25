import 'storage_paths.dart';

Future<StoragePaths> resolvePlatformStoragePaths() async {
  return StoragePaths(
    rootPath: '/udm/${StoragePaths.downloadsSegment}/${StoragePaths.appFolderName}',
  );
}
