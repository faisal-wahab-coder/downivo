import 'package:dio/dio.dart';

/// Cookie and token helpers shared by platform resolvers.
class SocialSessionUtils {
  const SocialSessionUtils._();

  static Map<String, String> cookiesFromHeaders(Headers headers) {
    final cookies = <String, String>{};
    for (final entry in headers.map.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') continue;
      for (final line in entry.value) {
        final part = line.split(';').first.trim();
        final separator = part.indexOf('=');
        if (separator <= 0) continue;
        cookies[part.substring(0, separator)] = part.substring(separator + 1);
      }
    }
    return cookies;
  }

  static String cookieHeader(Map<String, String> cookies) =>
      cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  static String? firstMatch(String text, List<RegExp> patterns) {
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String decodeEmbeddedUrl(String raw) {
    var value = raw
        .replaceAll(r'\u0026', '&')
        .replaceAll(r'\u002F', '/')
        .replaceAll(r'\u0025', '%')
        .replaceAll(r'\/', '/')
        .replaceAll(r'\"', '"');
    if (value.contains('%3F') || value.contains('%26')) {
      value = Uri.decodeComponent(value);
    }
    return value.replaceAll('&amp;', '&');
  }
}
