import 'package:download_engine/download_engine.dart';

import 'models/browser_tab.dart';

/// Normalizes address bar input into a loadable URL or search query.
class BrowserUrlUtils {
  const BrowserUrlUtils._();

  static const defaultSearchEngine =
      'https://www.google.com/search?q={query}';

  static String normalizeInput(
    String input, {
    String searchEngine = defaultSearchEngine,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return BrowserTab.homeUrl;

    if (_looksLikeSearchQuery(trimmed)) {
      return searchEngine.replaceFirst(
        '{query}',
        Uri.encodeComponent(trimmed),
      );
    }

    final withScheme =
        trimmed.startsWith('http://') || trimmed.startsWith('https://')
            ? trimmed
            : 'https://$trimmed';

    final validator = UrlValidator();
    final result = validator.validate(withScheme);
    return result.isValid ? result.uri!.toString() : BrowserTab.homeUrl;
  }

  static bool _looksLikeSearchQuery(String input) {
    if (input.contains(' ')) return true;
    if (!input.contains('.')) return true;
    return false;
  }

  static String displayUrl(String url) {
    if (url == BrowserTab.homeUrl) return '';
    return url;
  }
}
