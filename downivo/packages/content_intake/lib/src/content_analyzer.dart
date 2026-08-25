import 'package:download_engine/download_engine.dart';

import 'models/detected_content.dart';

/// Extracts downloadable URLs from text — docs/19, docs/20
class ContentAnalyzer {
  ContentAnalyzer({UrlValidator? validator})
      : _validator = validator ?? UrlValidator();

  final UrlValidator _validator;

  static final _urlPattern = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  DetectedContent analyzeText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const DetectedContent(rawText: '', urls: []);
    }

    final trimmed = text.trim();
    final urls = _extractUrls(trimmed);
    return DetectedContent(rawText: trimmed, urls: urls);
  }

  DetectedContent analyzeShare({
    String? text,
    List<String> filePaths = const [],
  }) {
    final detected = analyzeText(text);
    return DetectedContent(
      rawText: detected.rawText,
      urls: detected.urls,
      filePaths: filePaths,
    );
  }

  List<String> _extractUrls(String text) {
    final seen = <String>{};
    final urls = <String>[];

    for (final match in _urlPattern.allMatches(text)) {
      final candidate = _normalizeTrailingPunctuation(match.group(0)!);
      final result = _validator.validate(candidate);
      if (result.isValid && seen.add(result.uri!.toString())) {
        urls.add(result.uri!.toString());
      }
    }

    if (urls.isEmpty) {
      final direct = _validator.validate(text);
      if (direct.isValid && seen.add(direct.uri!.toString())) {
        urls.add(direct.uri!.toString());
      }
    }

    return urls;
  }

  String _normalizeTrailingPunctuation(String url) {
    var value = url;
    while (value.isNotEmpty && ',.;)]}'.contains(value[value.length - 1])) {
      value = value.substring(0, value.length - 1);
    }
    return value;
  }
}
