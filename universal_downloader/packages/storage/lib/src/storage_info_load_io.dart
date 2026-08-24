import 'dart:io';

import 'package:flutter/services.dart';

import 'storage_info.dart';
import 'storage_paths.dart';

const _channel = MethodChannel('com.universaldownloader.storage/disk');

Future<StorageInfo> loadStorageInfoForPlatform(StoragePaths paths) async {
  if (Platform.isAndroid) {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'volumeStats',
        {'path': paths.rootPath},
      );
      if (result != null) {
        final free = (result['freeBytes'] as num?)?.toInt() ?? 0;
        final total = (result['totalBytes'] as num?)?.toInt() ?? 0;
        if (total > 0) {
          return StorageInfo(
            rootPath: paths.rootPath,
            freeBytes: free,
            totalBytes: total,
          );
        }
      }
    } on PlatformException {
      // Fall through to df.
    }
  }

  final fromDf = await _fromDf(paths.rootPath);
  if (fromDf != null) return fromDf;

  return StorageInfo(
    rootPath: paths.rootPath,
    freeBytes: 0,
    totalBytes: 0,
  );
}

Future<StorageInfo?> _fromDf(String path) async {
  try {
    Directory(path).createSync(recursive: true);
    final result = await Process.run('df', ['-k', path]);
    if (result.exitCode != 0) return null;
    final lines = result.stdout.toString().trim().split('\n');
    if (lines.length < 2) return null;
    final parts = lines.last.trim().split(RegExp(r'\s+'));
    if (parts.length < 4) return null;
    // Filesystem 1024-blocks Used Available Capacity Mounted
    final totalK = int.tryParse(parts[1]);
    final availK = int.tryParse(parts[3]);
    if (totalK == null || availK == null || totalK <= 0) return null;
    return StorageInfo(
      rootPath: path,
      freeBytes: availK * 1024,
      totalBytes: totalK * 1024,
    );
  } on Object {
    return null;
  }
}
