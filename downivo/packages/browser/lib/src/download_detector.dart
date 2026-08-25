import 'package:download_engine/download_engine.dart';

import 'models/detected_download.dart';

/// Detects directly downloadable URLs — docs/18 §12–13
class DownloadDetector {
  const DownloadDetector._();

  static const downloadableExtensions = {
    '.zip', '.rar', '.7z', '.tar', '.gz',
    '.pdf', '.doc', '.docx', '.txt', '.epub',
    '.mp4', '.mkv', '.webm', '.mov', '.avi',
    '.mp3', '.wav', '.aac', '.flac', '.ogg',
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg',
    '.apk', '.xapk',
    '.iso', '.bin', '.dmg',
  };

  static bool isDirectDownloadUrl(String url) {
    if (!_isHttpUrl(url)) return false;

    final uri = Uri.tryParse(url);
    if (uri == null) return false;

    if (isSocialCdnUrl(uri)) return true;

    final path = uri.path.toLowerCase();
    if (downloadableExtensions.any(path.endsWith)) return true;

    final validator = UrlValidator();
    return validator.validate(url).isValid &&
        uri.pathSegments.isNotEmpty &&
        uri.pathSegments.last.contains('.');
  }

  /// Recognizes CDN URLs emitted by social players after a page loads in the browser.
  static bool isSocialCdnUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host.contains('googlevideo.com') ||
        host.contains('tiktokcdn.com') ||
        host.contains('tiktokv.com') ||
        host.contains('fbcdn.net') ||
        host.contains('cdninstagram.com') ||
        host.contains('video.twimg.com') ||
        host.contains('v.redd.it') ||
        host.contains('pinimg.com');
  }

  static DetectedDownload? fromNavigationUrl(String url) {
    if (!isDirectDownloadUrl(url)) return null;
    return DetectedDownload(
      url: url,
      label: _labelFromUrl(url),
      source: DetectedDownloadSource.navigation,
    );
  }

  static List<DetectedDownload> fromLinkUrls(Iterable<String> urls) {
    final seen = <String>{};
    final results = <DetectedDownload>[];
    for (final url in urls) {
      if (!isDirectDownloadUrl(url) || seen.contains(url)) continue;
      seen.add(url);
      results.add(
        DetectedDownload(
          url: url,
          label: _labelFromUrl(url),
          source: DetectedDownloadSource.pageLink,
        ),
      );
    }
    return results;
  }

  static String _labelFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : url;
    return segment.isEmpty ? url : segment;
  }

  static bool _isHttpUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }
}
