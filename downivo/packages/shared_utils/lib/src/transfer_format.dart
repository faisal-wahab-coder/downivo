/// Formats byte counts and transfer rates for download UI.
class TransferFormat {
  const TransferFormat._();

  static String bytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  static String speed(int bytesPerSec) {
    if (bytesPerSec <= 0) return '—';
    return '${bytes(bytesPerSec)}/s';
  }

  static String eta({
    required int bytesRemaining,
    required int bytesPerSec,
  }) {
    if (bytesPerSec <= 0 || bytesRemaining <= 0) return '—';
    final seconds = (bytesRemaining / bytesPerSec).ceil();
    if (seconds < 60) return '${seconds}s left';
    if (seconds < 3600) return '${(seconds / 60).ceil()}m left';
    return '${(seconds / 3600).toStringAsFixed(1)}h left';
  }
}
