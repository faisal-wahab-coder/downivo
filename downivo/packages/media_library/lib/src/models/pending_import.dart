/// A file discovered in managed storage since the last library sync.
class PendingImport {
  const PendingImport({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    this.suggestedCategory,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final DateTime modifiedAt;
  final String? suggestedCategory;
}
