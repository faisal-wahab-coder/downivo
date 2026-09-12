import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;

import 'package:storage/storage.dart';

/// Computes SHA-256 and MD5 checksums for a completed download file.
class ChecksumCalculator {
  const ChecksumCalculator._();

  /// Returns `(sha256Hex, md5Hex)` for the file at [filePath].
  static Future<(String sha256, String md5)> computeForFile(
    FileStore fileStore,
    String filePath,
  ) async {
    final bytes = await fileStore.readBytes(filePath);
    return computeForBytes(bytes);
  }

  /// Returns `(sha256Hex, md5Hex)` for in-memory bytes.
  static (String sha256, String md5) computeForBytes(Uint8List bytes) {
    final sha256Digest = crypto.sha256.convert(bytes);
    final md5Digest = crypto.md5.convert(bytes);
    return (sha256Digest.toString(), md5Digest.toString());
  }
}
