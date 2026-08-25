/// Strips URLs, tokens, cookies, and other sensitive values before any sink.
class PrivacySanitizer {
  const PrivacySanitizer();

  static const _blockedKeys = {
    'url',
    'uri',
    'href',
    'link',
    'page_url',
    'direct_url',
    'thumbnail_url',
    'query',
    'query_parameters',
    'token',
    'access_token',
    'refresh_token',
    'authorization',
    'auth',
    'cookie',
    'cookies',
    'set-cookie',
    'password',
    'secret',
    'api_key',
    'apikey',
    'filename',
    'file_name',
    'path',
    'file_path',
  };

  static final _urlLike = RegExp(
    r'(https?:\/\/[^\s]+)|(www\.[^\s]+)|((tg|telegram|snapchat|whatsapp):\/\/[^\s]+)',
    caseSensitive: false,
  );

  static final _tokenLike = RegExp(
    r'(bearer\s+\S+)|(access_token=)|(refresh_token=)|(api[_-]?key=)|'
    r'(authorization:\s*\S+)|(cookie:\s*\S+)',
    caseSensitive: false,
  );

  Map<String, Object> sanitize(Map<String, Object?>? properties) {
    if (properties == null || properties.isEmpty) return const {};
    final out = <String, Object>{};
    for (final entry in properties.entries) {
      final key = entry.key.trim().toLowerCase().replaceAll('-', '_');
      if (_blockedKeys.contains(key)) continue;
      final value = _sanitizeValue(entry.value);
      if (value != null) out[entry.key] = value;
    }
    return out;
  }

  String sanitizeMessage(String message) {
    var text = message;
    text = text.replaceAll(_urlLike, '[redacted-url]');
    text = text.replaceAll(_tokenLike, '[redacted-secret]');
    return text;
  }

  Object? _sanitizeValue(Object? value) {
    if (value == null) return null;
    if (value is num || value is bool) return value;
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return null;
      if (_urlLike.hasMatch(trimmed) || _tokenLike.hasMatch(trimmed)) {
        return null;
      }
      return trimmed;
    }
    if (value is Iterable) {
      return value
          .map(_sanitizeValue)
          .whereType<Object>()
          .toList(growable: false);
    }
    return sanitizeMessage(value.toString());
  }
}
