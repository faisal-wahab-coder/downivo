enum SearchHitKind { file, download }

class SearchHit {
  const SearchHit({
    required this.id,
    required this.kind,
    required this.title,
    this.subtitle,
    this.thumbnailUrl,
    this.path,
    this.downloadId,
  });

  final String id;
  final SearchHitKind kind;
  final String title;
  final String? subtitle;
  final String? thumbnailUrl;
  final String? path;
  final String? downloadId;
}
