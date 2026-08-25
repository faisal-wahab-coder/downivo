import 'package:storage/storage.dart';

/// Aggregate stats for a storage category.
class CategorySummary {
  const CategorySummary({
    required this.category,
    required this.fileCount,
    required this.totalBytes,
  });

  final StorageCategory category;
  final int fileCount;
  final int totalBytes;
}
