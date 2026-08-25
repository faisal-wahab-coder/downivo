import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'storage_paths.dart';

Future<StoragePaths> resolvePlatformStoragePaths() async {
  final baseDir = await getApplicationDocumentsDirectory();
  final root = p.join(
    baseDir.path,
    StoragePaths.downloadsSegment,
    StoragePaths.appFolderName,
  );
  return StoragePaths(rootPath: root);
}
