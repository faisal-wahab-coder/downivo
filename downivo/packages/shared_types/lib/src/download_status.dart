/// Download lifecycle status — docs/13.6_Download_Database_Schema.md §9
enum DownloadStatus {
  queued('QUEUED'),
  preparing('PREPARING'),
  downloading('DOWNLOADING'),
  paused('PAUSED'),
  completed('COMPLETED'),
  failed('FAILED'),
  cancelled('CANCELLED'),
  verifying('VERIFYING');

  const DownloadStatus(this.storageValue);

  final String storageValue;

  static DownloadStatus fromStorage(String value) {
    return DownloadStatus.values.firstWhere(
      (s) => s.storageValue == value,
      orElse: () => DownloadStatus.queued,
    );
  }
}

enum DownloadPriority {
  low('LOW'),
  normal('NORMAL'),
  high('HIGH'),
  urgent('URGENT');

  const DownloadPriority(this.storageValue);

  final String storageValue;
}
