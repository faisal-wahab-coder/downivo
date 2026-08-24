import 'storage_paths.dart';
import 'storage_info_load.dart';

class StorageInfo {
  StorageInfo({
    required this.rootPath,
    required this.freeBytes,
    required this.totalBytes,
  });

  final String rootPath;
  final int freeBytes;
  final int totalBytes;

  String get formattedFreeSpace => _formatBytes(freeBytes);

  bool get hasVolumeStats => totalBytes > 0;

  int get usedBytes =>
      totalBytes <= 0 ? 0 : (totalBytes - freeBytes).clamp(0, totalBytes);

  static Future<StorageInfo> load(StoragePaths paths) {
    return loadStorageInfo(paths);
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return 'Calculating…';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit++;
    }
    return '${value.toStringAsFixed(value >= 10 ? 0 : 1)} ${units[unit]}';
  }
}
