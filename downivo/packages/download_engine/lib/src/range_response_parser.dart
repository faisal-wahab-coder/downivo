/// Parses HTTP Content-Range headers for resume support.
class RangeResponseParser {
  const RangeResponseParser._();

  /// Returns total entity size from `bytes 100-999/1000` or null if unknown.
  static int? totalBytesFromContentRange(String? contentRange) {
    if (contentRange == null) return null;
    final match = RegExp(r'bytes \d+-\d+/(\d+|\*)').firstMatch(contentRange);
    if (match == null) return null;
    final total = match.group(1);
    if (total == null || total == '*') return null;
    return int.tryParse(total);
  }

  /// Builds a Range request header for the given start byte.
  static String rangeHeaderFor(int startByte) => 'bytes=$startByte-';
}
