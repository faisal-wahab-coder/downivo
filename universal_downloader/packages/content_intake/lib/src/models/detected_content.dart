/// A detected clipboard or share item.
class DetectedContent {
  const DetectedContent({
    required this.rawText,
    required this.urls,
    this.filePaths = const [],
  });

  final String rawText;
  final List<String> urls;
  final List<String> filePaths;

  bool get hasUrls => urls.isNotEmpty;
  bool get hasFiles => filePaths.isNotEmpty;
  bool get isEmpty => !hasUrls && !hasFiles && rawText.trim().isEmpty;

  String? get primaryUrl => urls.isNotEmpty ? urls.first : null;
}
