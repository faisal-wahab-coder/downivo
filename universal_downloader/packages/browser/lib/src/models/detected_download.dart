/// A downloadable resource found on a page or navigation.
class DetectedDownload {
  const DetectedDownload({
    required this.url,
    required this.label,
    this.source = DetectedDownloadSource.navigation,
  });

  final String url;
  final String label;
  final DetectedDownloadSource source;
}

enum DetectedDownloadSource {
  navigation,
  pageLink,
  currentPage,
}
