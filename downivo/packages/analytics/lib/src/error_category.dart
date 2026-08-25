/// Normalized resolver/download failure categories. Never send raw exceptions.
enum ErrorCategory {
  invalidUrl,
  unsupportedPlatform,
  privateContent,
  contentNotFound,
  rateLimited,
  networkError,
  timeout,
  resolverError,
  mediaUnavailable,
  unknownError;

  String get wireValue => switch (this) {
        ErrorCategory.invalidUrl => 'invalid_url',
        ErrorCategory.unsupportedPlatform => 'unsupported_platform',
        ErrorCategory.privateContent => 'private_content',
        ErrorCategory.contentNotFound => 'content_not_found',
        ErrorCategory.rateLimited => 'rate_limited',
        ErrorCategory.networkError => 'network_error',
        ErrorCategory.timeout => 'timeout',
        ErrorCategory.resolverError => 'resolver_error',
        ErrorCategory.mediaUnavailable => 'media_unavailable',
        ErrorCategory.unknownError => 'unknown_error',
      };

  static ErrorCategory fromMessage(String? message) {
    final text = (message ?? '').toLowerCase();
    if (text.isEmpty) return ErrorCategory.unknownError;
    if (text.contains('invalid url') || text.contains('invalid download')) {
      return ErrorCategory.invalidUrl;
    }
    if (text.contains('unsupported') ||
        text.contains('no extractor') ||
        text.contains('temporarily unavailable')) {
      return ErrorCategory.unsupportedPlatform;
    }
    if (text.contains('private') ||
        text.contains('authentication') ||
        text.contains('login') ||
        text.contains('restricted') ||
        text.contains('403')) {
      return ErrorCategory.privateContent;
    }
    if (text.contains('404') ||
        text.contains('not found') ||
        text.contains('expired') ||
        text.contains('removed')) {
      return ErrorCategory.contentNotFound;
    }
    if (text.contains('429') || text.contains('too many requests')) {
      return ErrorCategory.rateLimited;
    }
    if (text.contains('timed out') || text.contains('timeout')) {
      return ErrorCategory.timeout;
    }
    if (text.contains('network') ||
        text.contains('connection') ||
        text.contains('cors') ||
        text.contains('proxy')) {
      return ErrorCategory.networkError;
    }
    if (text.contains('unavailable') ||
        text.contains('hls-only') ||
        text.contains('no downloadable')) {
      return ErrorCategory.mediaUnavailable;
    }
    if (text.contains('resolv')) {
      return ErrorCategory.resolverError;
    }
    return ErrorCategory.unknownError;
  }
}

String fileSizeBucket(int? bytes) {
  if (bytes == null || bytes < 0) return 'unknown';
  const mb = 1024 * 1024;
  if (bytes < 10 * mb) return '< 10 MB';
  if (bytes < 50 * mb) return '10–50 MB';
  if (bytes < 100 * mb) return '50–100 MB';
  if (bytes < 500 * mb) return '100–500 MB';
  if (bytes < 1024 * mb) return '500 MB–1 GB';
  return '> 1 GB';
}
