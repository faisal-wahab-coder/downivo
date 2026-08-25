/// Dailymotion page URLs: `dailymotion.com/video/{id}` and `dai.ly/{id}`.
class DailymotionUri {
  const DailymotionUri._();

  static bool isHost(String host) {
    final h = host.toLowerCase();
    return h == 'dailymotion.com' ||
        h.endsWith('.dailymotion.com') ||
        h == 'dai.ly' ||
        h.endsWith('.dai.ly');
  }

  static bool isCdnHost(String host) {
    final h = host.toLowerCase();
    return h == 'dmcdn.net' || h.endsWith('.dmcdn.net');
  }

  static bool isDownloadable(Uri uri) {
    if (uri.path.toLowerCase().contains('.m3u8')) return false;
    return videoIdFromUri(uri) != null;
  }

  static Uri normalize(Uri uri) {
    final id = videoIdFromUri(uri);
    if (id == null) return uri;
    return Uri.parse('https://www.dailymotion.com/video/$id');
  }

  static List<Uri> fetchTargets(Uri uri) {
    final id = videoIdFromUri(uri);
    if (id == null) return [uri];
    return [
      Uri.parse('https://www.dailymotion.com/video/$id'),
      Uri.parse('https://www.dailymotion.com/embed/video/$id'),
    ];
  }

  static String? videoIdFromUri(Uri uri) {
    if (uri.scheme.toLowerCase() == 'dailymotion') {
      final host = uri.host.toLowerCase();
      if (host.isNotEmpty && host != 'video') return host;
    }
    final host = uri.host.toLowerCase();
    if (host == 'dai.ly' || host.endsWith('.dai.ly')) {
      final id = uri.pathSegments.where((s) => s.isNotEmpty).firstOrNull;
      return _validId(id);
    }
    if (!isHost(host)) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[0] == 'video') {
      return _validId(segments[1].split('?').first.split('_').first);
    }
    if (segments.length >= 3 &&
        segments[0] == 'embed' &&
        segments[1] == 'video') {
      return _validId(segments[2].split('?').first);
    }
    if (segments.length >= 4 &&
        segments[0] == 'cdn' &&
        segments[1] == 'manifest' &&
        segments[2] == 'video') {
      return _validId(segments[3].split('.').first.split('_').first);
    }
    return null;
  }

  static String? _validId(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final id = raw.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
    if (id.length < 4) return null;
    return id.toLowerCase();
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
