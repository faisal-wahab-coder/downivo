import 'package:path/path.dart' as p;

import 'storage_category.dart';
import 'storage_paths_resolve.dart';

/// Resolves paths under `Downloads/Downivo/` per product spec.
class StoragePaths {
  StoragePaths({required this.rootPath});

  final String rootPath;

  static const appFolderName = 'Downivo';
  static const downloadsSegment = 'Downloads';

  /// App-specific download root (scoped storage safe on Android 10+).
  static Future<StoragePaths> resolve() => resolveStoragePaths();

  String categoryPath(StorageCategory category) =>
      p.join(rootPath, category.folderName);

  List<String> allCategoryPaths() =>
      StorageCategory.values.map(categoryPath).toList();
}
