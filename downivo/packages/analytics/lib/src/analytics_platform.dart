/// Analytics `platform` values. Keep SocialPlatform unchanged; map at emit time.
abstract final class AnalyticsPlatform {
  static const youtube = 'youtube';
  static const youtubeShorts = 'youtube_shorts';
  static const tiktok = 'tiktok';
  static const instagram = 'instagram';
  static const facebook = 'facebook';
  static const x = 'x';
  static const reddit = 'reddit';
  static const pinterest = 'pinterest';
  static const linkedin = 'linkedin';
  static const threads = 'threads';
  static const soundcloud = 'soundcloud';
  static const vimeo = 'vimeo';
  static const twitch = 'twitch';
  static const telegram = 'telegram';
  static const snapchat = 'snapchat';
  static const whatsapp = 'whatsapp';
  static const dailymotion = 'dailymotion';
  static const directUrl = 'direct_url';
  static const unknown = 'unknown';

  static const all = <String>{
    youtube,
    youtubeShorts,
    tiktok,
    instagram,
    facebook,
    x,
    reddit,
    pinterest,
    linkedin,
    threads,
    soundcloud,
    vimeo,
    twitch,
    telegram,
    snapchat,
    whatsapp,
    dailymotion,
    directUrl,
    unknown,
  };

  /// Maps engine `SocialPlatform.name` (+ optional URI for Shorts) to analytics.
  static String fromSocialName(String? name, {String? uri}) {
    if (name == null || name.isEmpty) {
      return uri == null || uri.isEmpty ? unknown : directUrl;
    }
    if (name == 'twitter') return x;
    if (name == 'youtube' && _isYouTubeShorts(uri)) return youtubeShorts;
    if (all.contains(name) || name == 'youtube') return name;
    return name;
  }

  static bool _isYouTubeShorts(String? uri) {
    if (uri == null || uri.isEmpty) return false;
    final parsed = Uri.tryParse(uri);
    if (parsed == null) return false;
    return parsed.path.toLowerCase().contains('/shorts/');
  }
}

String mediaTypeFromKind(String? kind, {String? mimeType}) {
  final k = kind?.toLowerCase();
  if (k == 'video' || k == 'audio' || k == 'image' || k == 'document') {
    return k!;
  }
  final mime = mimeType?.toLowerCase() ?? '';
  if (mime.startsWith('video/')) return 'video';
  if (mime.startsWith('audio/')) return 'audio';
  if (mime.startsWith('image/')) return 'image';
  if (mime.isNotEmpty) return 'document';
  return 'unknown';
}
