import 'dailymotion_uri.dart';
import 'social_platform.dart';

/// Normalizes social page URLs and builds fallback fetch targets.
class SocialUrlUtils {
  const SocialUrlUtils._();

  static List<Uri> fetchTargets(Uri pageUrl, SocialPlatform platform) {
    final normalized = _normalize(pageUrl, platform);
    return switch (platform) {
      SocialPlatform.tiktok => _tiktokTargets(normalized),
      SocialPlatform.instagram => _instagramTargets(normalized),
      SocialPlatform.youtube => _youtubeTargets(normalized),
      SocialPlatform.twitter => _twitterTargets(normalized),
      SocialPlatform.reddit => _redditTargets(normalized),
      SocialPlatform.facebook => _facebookTargets(normalized),
      SocialPlatform.pinterest => _pinterestTargets(normalized),
      SocialPlatform.linkedin => _linkedinTargets(normalized),
      SocialPlatform.threads => ThreadsUri.fetchTargets(normalized),
      SocialPlatform.soundcloud => _soundcloudTargets(normalized),
      SocialPlatform.vimeo => _vimeoTargets(normalized),
      SocialPlatform.twitch => _twitchTargets(normalized),
      SocialPlatform.telegram => TelegramUri.fetchTargets(normalized),
      SocialPlatform.snapchat => SnapchatUri.fetchTargets(normalized),
      SocialPlatform.whatsapp => WhatsAppUri.fetchTargets(normalized),
      SocialPlatform.dailymotion => DailymotionUri.fetchTargets(normalized),
    };
  }

  static Uri _normalize(Uri uri, SocialPlatform platform) {
    return switch (platform) {
      SocialPlatform.youtube => _normalizeYouTube(uri),
      SocialPlatform.twitter => _normalizeTwitter(uri),
      SocialPlatform.facebook => FacebookUri.normalize(uri),
      SocialPlatform.soundcloud => SoundCloudUri.normalize(uri),
      SocialPlatform.reddit => RedditUri.normalize(uri),
      SocialPlatform.pinterest => PinterestUri.normalize(uri),
      SocialPlatform.vimeo => VimeoUri.normalize(uri),
      SocialPlatform.twitch => TwitchUri.normalize(uri),
      SocialPlatform.linkedin => LinkedInUri.normalize(uri),
      SocialPlatform.telegram => TelegramUri.normalize(uri),
      SocialPlatform.snapchat => SnapchatUri.normalize(uri),
      SocialPlatform.threads => ThreadsUri.normalize(uri),
      SocialPlatform.whatsapp => WhatsAppUri.normalize(uri),
      SocialPlatform.dailymotion => DailymotionUri.normalize(uri),
      _ => uri,
    };
  }

  static Uri _normalizeYouTube(Uri uri) {
    final videoId = YouTubeUri.videoIdFromUri(uri);
    if (videoId == null) return uri;
    return Uri.parse('https://www.youtube.com/watch?v=$videoId');
  }

  static Uri _normalizeTwitter(Uri uri) {
    final host = uri.host.toLowerCase();
    if (host == 'twitter.com' || host.endsWith('.twitter.com')) {
      return Uri.parse(
        uri.toString().replaceFirst('://twitter.com', '://x.com'),
      );
    }
    return uri;
  }

  static List<Uri> _tiktokTargets(Uri uri) {
    final targets = <Uri>[uri];
    final contentId = TikTokUri.videoIdFromUri(uri);
    if (contentId != null) {
      targets.add(Uri.parse('https://m.tiktok.com/v/$contentId.html'));
      if (!TikTokUri.isPhotoPost(uri)) {
        targets.add(Uri.parse('https://www.tiktok.com/@_/video/$contentId'));
      }
    }
    return targets.toSet().toList();
  }

  static List<Uri> _instagramTargets(Uri uri) {
    final embed = _instagramEmbedUri(uri);
    if (embed == null) return [uri];
    return [embed, uri];
  }

  static List<Uri> _youtubeTargets(Uri uri) {
    final videoId = YouTubeUri.videoIdFromUri(uri);
    if (videoId == null) return [uri];
    return [
      Uri.parse('https://www.youtube.com/watch?v=$videoId'),
      Uri.parse('https://m.youtube.com/watch?v=$videoId'),
      Uri.parse('https://www.youtube.com/embed/$videoId'),
    ];
  }

  static List<Uri> _twitterTargets(Uri uri) {
    final tweetId = TwitterUri.tweetIdFromUri(uri);
    if (tweetId == null) return [uri];
    return [
      uri,
      Uri.parse('https://platform.twitter.com/embed/Tweet.html?id=$tweetId'),
    ];
  }

  static List<Uri> _redditTargets(Uri uri) {
    final jsonEndpoint = RedditUri.jsonEndpoint(uri);
    return [
      uri,
      if (jsonEndpoint != null) jsonEndpoint,
      Uri.parse('${uri.scheme}://${uri.host}${uri.path}.json'),
    ].toSet().toList();
  }

  static List<Uri> _facebookTargets(Uri uri) {
    return [
      uri,
      Uri.parse(_swapHost(uri, 'm.facebook.com')),
      Uri.parse(_swapHost(uri, 'mbasic.facebook.com')),
    ].toSet().toList();
  }

  static List<Uri> _pinterestTargets(Uri uri) {
    final normalized = PinterestUri.normalize(uri);
    if (PinterestUri.isShortUrl(uri) || PinterestUri.isShortUrl(normalized)) {
      return [uri, normalized].toSet().toList();
    }
    final pinId = PinterestUri.pinIdFromUri(normalized);
    if (pinId != null) {
      return {
        uri,
        normalized,
        Uri.parse('https://www.pinterest.com/pin/$pinId/'),
        Uri.parse('https://m.pinterest.com/pin/$pinId/'),
      }.toList();
    }
    return {
      uri,
      normalized,
      if (!normalized.host.toLowerCase().contains('pinimg'))
        Uri.parse(_swapHost(normalized, 'www.pinterest.com')),
    }.toList();
  }

  static List<Uri> _linkedinTargets(Uri uri) {
    return LinkedInUri.fetchTargets(uri);
  }

  static List<Uri> _soundcloudTargets(Uri uri) {
    final normalized = SoundCloudUri.normalize(uri);
    return {uri, normalized}.toList();
  }

  static List<Uri> _vimeoTargets(Uri uri) {
    final normalized = VimeoUri.normalize(uri);
    final videoId = VimeoUri.videoIdFromUri(normalized);
    if (videoId == null) {
      return {uri, normalized}.toList();
    }
    final hash =
        VimeoUri.privacyHashFromUri(uri) ??
        VimeoUri.privacyHashFromUri(normalized);
    final player = hash == null
        ? Uri.parse('https://player.vimeo.com/video/$videoId')
        : Uri.parse('https://player.vimeo.com/video/$videoId?h=$hash');
    return {uri, normalized, player}.toList();
  }

  static List<Uri> _twitchTargets(Uri uri) {
    final normalized = TwitchUri.normalize(uri);
    return {uri, normalized}.toList();
  }

  static String _swapHost(Uri uri, String host) =>
      '${uri.scheme}://$host${uri.path.isEmpty ? '' : uri.path}';

  static Uri? _instagramEmbedUri(Uri uri) {
    final reel = RegExp(r'/reel/([^/]+)').firstMatch(uri.path);
    if (reel != null) {
      return Uri.parse(
        'https://www.instagram.com/reel/${reel.group(1)}/embed/',
      );
    }
    final post = RegExp(r'/(p|tv)/([^/]+)').firstMatch(uri.path);
    if (post != null) {
      return Uri.parse(
        'https://www.instagram.com/${post.group(1)}/${post.group(2)}/embed/',
      );
    }
    return null;
  }

}

/// YouTube URL helpers shared by fetch targets and resolvers.
class YouTubeUri {
  const YouTubeUri._();

  static String? videoIdFromUri(Uri uri) {
    final host = uri.host.toLowerCase();
    if (_isShortHost(host) && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first.split('?').first.trim();
      return id.isEmpty ? null : id;
    }
    final fromQuery = uri.queryParameters['v'];
    if (fromQuery != null && fromQuery.isNotEmpty) return fromQuery;

    final embedMatch = RegExp(
      r'/(embed|shorts|live)/([^/?#]+)',
    ).firstMatch(uri.path);
    return embedMatch?.group(2);
  }

  static bool _isShortHost(String host) =>
      host == 'youtu.be' || host.endsWith('.youtu.be');
}

class TikTokUri {
  const TikTokUri._();

  /// Extracts the numeric content ID from video or photo TikTok URLs.
  static String? videoIdFromUri(Uri uri) {
    final pathMatch = RegExp(r'/(?:video|photo)/(\d+)').firstMatch(uri.path);
    if (pathMatch != null) return pathMatch.group(1);
    final mobileMatch = RegExp(r'/v/(\d+)').firstMatch(uri.path);
    return mobileMatch?.group(1);
  }

  /// Returns true when the URL path indicates a photo/carousel post.
  static bool isPhotoPost(Uri uri) =>
      RegExp(r'/photo/(\d+)').hasMatch(uri.path);
}

class TwitterUri {
  const TwitterUri._();

  static String? tweetIdFromUri(Uri uri) {
    final match = RegExp(r'/status/(\d+)').firstMatch(uri.path);
    return match?.group(1);
  }
}

class FacebookUri {
  const FacebookUri._();

  /// Extracts a content ID from various Facebook URL patterns.
  ///
  /// Supported patterns:
  /// - `/watch/?v=<ID>` or `/watch?v=<ID>`
  /// - `/<page>/videos/<ID>/`
  /// - `/video.php?v=<ID>`
  /// - `/reel/<ID>`
  /// - `/photo/?fbid=<ID>` or `/photo.php?fbid=<ID>`
  /// - `/permalink.php?story_fbid=<ID>`
  /// - `fb.watch/<shortcode>`
  static String? contentIdFromUri(Uri uri) {
    final host = uri.host.toLowerCase();

    // fb.watch short links: the first path segment is the shortcode.
    if (host == 'fb.watch' && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first.trim();
      return id.isEmpty ? null : id;
    }

    // Query-param patterns.
    final vParam = uri.queryParameters['v'];
    if (vParam != null && vParam.isNotEmpty) return vParam;

    final fbid = uri.queryParameters['fbid'];
    if (fbid != null && fbid.isNotEmpty) return fbid;

    final storyFbid = uri.queryParameters['story_fbid'];
    if (storyFbid != null && storyFbid.isNotEmpty) return storyFbid;

    // Path-based patterns.
    final reelMatch = RegExp(r'/reels?/(\d+)').firstMatch(uri.path);
    if (reelMatch != null) return reelMatch.group(1);

    final videoMatch = RegExp(r'/videos?/(\d+)').firstMatch(uri.path);
    if (videoMatch != null) return videoMatch.group(1);

    final photoMatch = RegExp(r'/photos?/[^/]*/(\d+)').firstMatch(uri.path);
    if (photoMatch != null) return photoMatch.group(1);

    // pfbid-format post IDs (newer Facebook URL encoding for /posts/).
    final pfbidMatch = RegExp(r'/posts/(pfbid\w+)').firstMatch(uri.path);
    if (pfbidMatch != null) return pfbidMatch.group(1);

    // Generic numeric ID from last path segment.
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) {
      final last = segments.last;
      if (RegExp(r'^\d{5,}$').hasMatch(last)) return last;
    }

    return null;
  }

  /// Returns true when the URL path indicates a reel.
  static bool isReel(Uri uri) =>
      RegExp(r'/reels?/\d+').hasMatch(uri.path.toLowerCase());

  /// Returns true when the URL path indicates a photo post.
  static bool isPhoto(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.contains('/photo') ||
        path.contains('/photos/') ||
        uri.queryParameters.containsKey('fbid');
  }

  /// Returns true when the URL path indicates a video.
  static bool isVideo(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.contains('/watch') ||
        path.contains('/video') ||
        path == '/video.php' ||
        uri.queryParameters.containsKey('v') ||
        uri.host.toLowerCase() == 'fb.watch';
  }

  /// Normalizes a Facebook URL: strips tracking parameters, ensures canonical host.
  static Uri normalize(Uri uri) {
    final host = uri.host.toLowerCase();

    // For fb.watch, keep as-is (will be redirect-resolved).
    if (host == 'fb.watch') return uri;

    // Strip common tracking parameters.
    const trackingParams = {
      'mibextid',
      'ref',
      'sfnsn',
      'extid',
      'paipv',
      'eav',
      'share_id',
      'app',
      'wtsid',
      '__cft__',
      '__tn__',
      'notif_id',
      'notif_t',
      'acontext',
      'source',
    };

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((key, _) => trackingParams.contains(key.toLowerCase()));

    if (cleanedParams.isEmpty) {
      return Uri(
        scheme: 'https',
        host: host == 'facebook.com' ? 'www.facebook.com' : uri.host,
        path: uri.path,
      );
    }

    return uri.replace(
      scheme: 'https',
      host: host == 'facebook.com' ? 'www.facebook.com' : uri.host,
      queryParameters: cleanedParams,
    );
  }
}

class RedditUri {
  const RedditUri._();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
    'utm_term',
    'rdt',
    'share_id',
    'ref',
    'context',
    'si',
    'correlation_id',
  };

  static const _systemPages = {
    'popular',
    'best',
    'hot',
    'new',
    'rising',
    'top',
    'controversial',
    'news',
    'awards',
    'coins',
    'premium',
    'login',
    'register',
    'search',
    'explore',
    'ads',
    'wiki',
    'rules',
    'message',
    'mail',
    'settings',
    'subreddits',
    'domain',
    'submit',
    'notifications',
    'chat',
    'topics',
    'communities',
  };

  static const _directMediaHosts = {
    'i.redd.it',
    'v.redd.it',
    'preview.redd.it',
    'external-preview.redd.it',
    'b.thumbs.redditmedia.com',
    'a.thumbs.redditmedia.com',
  };

  /// Classifies a Reddit URL by content type.
  static RedditContentType classifyUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (_isDirectMediaHost(host)) {
      return RedditContentType.directMedia;
    }

    if (host == 'redd.it' || host == 'www.redd.it') {
      return segments.isEmpty
          ? RedditContentType.home
          : RedditContentType.short;
    }

    if (segments.isEmpty) return RedditContentType.home;

    final first = segments.first.toLowerCase();

    if (first == 'gallery' && segments.length >= 2) {
      return RedditContentType.post;
    }

    if (first == 'comments' && segments.length >= 2) {
      return RedditContentType.post;
    }

    if (first == 'r') {
      if (segments.length == 1) return RedditContentType.nonContent;
      if (segments.length >= 3 && segments[2].toLowerCase() == 's') {
        return RedditContentType.share;
      }
      if (segments.length >= 4 && segments[2].toLowerCase() == 'comments') {
        return segments.length >= 6
            ? RedditContentType.comment
            : RedditContentType.post;
      }
      return RedditContentType.subreddit;
    }

    if (first == 'user' || first == 'u') {
      return RedditContentType.user;
    }

    if (_systemPages.contains(first)) {
      return first == 'search'
          ? RedditContentType.search
          : RedditContentType.nonContent;
    }

    return RedditContentType.nonContent;
  }

  /// Extracts the post ID. Ignores the optional slug.
  static String? postIdFromUri(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    if (host == 'redd.it' || host == 'www.redd.it') {
      return _cleanId(segments.first);
    }

    if (_isDirectMediaHost(host)) {
      return _cleanId(segments.first);
    }

    if (segments.first.toLowerCase() == 'gallery' && segments.length >= 2) {
      return _cleanId(segments[1]);
    }

    if (segments.first.toLowerCase() == 'comments' && segments.length >= 2) {
      return _cleanId(segments[1]);
    }

    if (segments.length >= 4 &&
        segments.first.toLowerCase() == 'r' &&
        segments[2].toLowerCase() == 'comments') {
      return _cleanId(segments[3]);
    }

    return null;
  }

  /// Extracts the subreddit name from `/r/<name>/...`.
  static String? subredditFromUri(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    if (segments.first.toLowerCase() != 'r') return null;
    final name = segments[1];
    if (name.isEmpty) return null;
    return name;
  }

  /// True when the URL is a downloadable media/post page (not home/subreddit).
  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      RedditContentType.post ||
      RedditContentType.comment ||
      RedditContentType.short ||
      RedditContentType.share ||
      RedditContentType.directMedia => true,
      _ => false,
    };
  }

  static bool isDirectMedia(Uri uri) =>
      classifyUrl(uri) == RedditContentType.directMedia;

  static bool isShortUrl(Uri uri) =>
      classifyUrl(uri) == RedditContentType.short;

  static bool isShareUrl(Uri uri) =>
      classifyUrl(uri) == RedditContentType.share;

  /// Canonical identity used for duplicate detection. Post ID is primary.
  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    if (type == RedditContentType.directMedia) {
      final host = uri.host.toLowerCase();
      final path = uri.path;
      return 'reddit:media:$host$path';
    }
    final postId = postIdFromUri(uri);
    if (postId != null) return 'reddit:post:$postId';
    if (type == RedditContentType.subreddit) {
      final sub = subredditFromUri(uri);
      return sub == null ? null : 'reddit:subreddit:$sub';
    }
    return null;
  }

  /// Public JSON API endpoint for a post. Does not depend on the slug.
  static Uri? jsonEndpoint(Uri pageUrl) {
    final postId = postIdFromUri(pageUrl);
    if (postId == null) return null;
    final subreddit = subredditFromUri(pageUrl);
    if (subreddit != null) {
      return Uri.parse(
        'https://www.reddit.com/r/$subreddit/comments/$postId.json',
      );
    }
    return Uri.parse('https://www.reddit.com/comments/$postId.json');
  }

  /// Strips tracking params and canonicalizes reddit.com hosts.
  static Uri normalize(Uri uri) {
    final host = uri.host.toLowerCase();

    if (host == 'redd.it' ||
        host == 'www.redd.it' ||
        _isDirectMediaHost(host)) {
      return uri.replace(scheme: 'https');
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((key, _) => _trackingParams.contains(key.toLowerCase()));

    var canonicalHost = uri.host;
    if (host == 'reddit.com' ||
        host == 'old.reddit.com' ||
        host == 'new.reddit.com' ||
        host == 'np.reddit.com' ||
        host == 'm.reddit.com') {
      canonicalHost = 'www.reddit.com';
    } else if (host.endsWith('.reddit.com') && host != 'www.reddit.com') {
      canonicalHost = 'www.reddit.com';
    }

    final postId = postIdFromUri(uri);
    final subreddit = subredditFromUri(uri);
    if (postId != null && classifyUrl(uri) != RedditContentType.directMedia) {
      final path = subreddit != null
          ? '/r/$subreddit/comments/$postId/'
          : '/comments/$postId/';
      return Uri(
        scheme: 'https',
        host: 'www.reddit.com',
        path: path,
        queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
      );
    }

    return uri.replace(
      scheme: 'https',
      host: canonicalHost,
      query: cleanedParams.isEmpty
          ? ''
          : cleanedParams.entries
                .map(
                  (e) =>
                      '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                )
                .join('&'),
    );
  }

  static bool _isDirectMediaHost(String host) =>
      _directMediaHosts.contains(host);

  static String? _cleanId(String raw) {
    final id = raw.split('.').first.trim();
    if (id.isEmpty) return null;
    return id;
  }
}

/// Reddit URL content type classification.
enum RedditContentType {
  home,
  subreddit,
  post,
  comment,
  user,
  short,
  share,
  directMedia,
  search,
  nonContent,
}

/// SoundCloud URL helpers for track, playlist/set, and profile detection.
class SoundCloudUri {
  const SoundCloudUri._();

  /// Classifies the SoundCloud URL content type.
  static SoundCloudContentType classifyUrl(Uri uri) {
    if (isShortUrl(uri)) return SoundCloudContentType.shortUrl;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return SoundCloudContentType.home;
    if (_isSystemPage(segments[0])) return SoundCloudContentType.nonContent;
    if (segments.length == 1) return SoundCloudContentType.profile;
    if (segments[1] == 'sets') {
      if (segments.length >= 3 && segments[2].isNotEmpty) {
        return SoundCloudContentType.playlist;
      }
      return SoundCloudContentType.nonContent;
    }
    if (_isProfileSubpage(segments[1])) return SoundCloudContentType.nonContent;
    return SoundCloudContentType.track;
  }

  /// Extracts the artist (username) from a SoundCloud URL.
  static String? artistFromUri(Uri uri) {
    if (isShortUrl(uri)) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final artist = segments[0];
    if (_isSystemPage(artist)) return null;
    return artist;
  }

  /// Extracts the track slug from a SoundCloud track URL.
  static String? trackSlugFromUri(Uri uri) {
    if (classifyUrl(uri) != SoundCloudContentType.track) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return segments[1];
  }

  /// Extracts the playlist/set slug from a SoundCloud URL.
  static String? playlistSlugFromUri(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 3 || segments[1] != 'sets') return null;
    return segments[2];
  }

  /// Returns true when the URL represents a downloadable track.
  static bool isTrack(Uri uri) =>
      classifyUrl(uri) == SoundCloudContentType.track;

  /// Returns true when the URL represents a playlist/set (including albums).
  static bool isPlaylist(Uri uri) =>
      classifyUrl(uri) == SoundCloudContentType.playlist;

  /// Returns true when the URL represents a user profile.
  static bool isProfile(Uri uri) =>
      classifyUrl(uri) == SoundCloudContentType.profile;

  /// Short share links that must be resolved via HTTP redirect.
  static bool isShortUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'snd.sc' ||
        host == 'on.soundcloud.com' ||
        host.endsWith('.on.soundcloud.com');
  }

  /// Track or playlist/set that can produce downloadable audio.
  static bool isDownloadable(Uri uri) =>
      isTrack(uri) || isPlaylist(uri) || isShortUrl(uri);

  /// Normalizes a SoundCloud URL: strips tracking params, ensures canonical host.
  ///
  /// Short links (`snd.sc`, `on.soundcloud.com`) are left unchanged so the
  /// HTTP client can follow the redirect to the canonical page.
  /// `secret_token` is preserved — it is user-supplied access, not tracking.
  static Uri normalize(Uri uri) {
    if (isShortUrl(uri)) return uri;

    const trackingParams = {
      'utm_source',
      'utm_medium',
      'utm_campaign',
      'utm_content',
      'utm_term',
      'si',
      'ref',
      'in',
      'from',
      'share_id',
      'fbclid',
      'gclid',
      'igshid',
    };

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((key, _) => trackingParams.contains(key.toLowerCase()));

    return uri.replace(
      scheme: 'https',
      host: 'soundcloud.com',
      fragment: '',
      query: cleanedParams.isEmpty
          ? ''
          : cleanedParams.entries
                .map(
                  (e) =>
                      '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                )
                .join('&'),
    );
  }

  /// Builds the canonical content identity for deduplication.
  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    if (type == SoundCloudContentType.shortUrl) {
      final code = uri.pathSegments.where((s) => s.isNotEmpty).join('/');
      if (code.isEmpty) return null;
      return 'soundcloud:short:$code';
    }
    final artist = artistFromUri(uri);
    if (artist == null) return null;
    return switch (type) {
      SoundCloudContentType.track =>
        'soundcloud:track:$artist/${trackSlugFromUri(uri)}',
      SoundCloudContentType.playlist =>
        'soundcloud:playlist:$artist/${playlistSlugFromUri(uri)}',
      SoundCloudContentType.profile => 'soundcloud:profile:$artist',
      _ => null,
    };
  }

  /// Upgrades a SoundCloud artwork URL to the 500x500 variant when possible.
  static String? upgradeArtworkUrl(String? artwork) {
    if (artwork == null || artwork.isEmpty || artwork == 'null') return null;
    if (!artwork.startsWith('http')) return null;
    return artwork.replaceAll(
      RegExp(r'-(large|t\d+x\d+|small|tiny|badge|mini)\.'),
      '-t500x500.',
    );
  }

  static bool _isSystemPage(String segment) {
    const systemPages = {
      'discover',
      'stream',
      'library',
      'you',
      'search',
      'upload',
      'messages',
      'settings',
      'notifications',
      'pro',
      'charts',
      'pages',
      'terms-of-use',
      'privacy',
      'imprint',
      'creators',
      'popular',
      'people',
      'groups',
      'tags',
      'sets',
      'explore',
      'feed',
      'login',
      'signin',
      'logout',
      'mobile',
      'about',
      'jobs',
    };
    return systemPages.contains(segment.toLowerCase());
  }

  static bool _isProfileSubpage(String segment) {
    const subpages = {
      'likes',
      'tracks',
      'albums',
      'reposts',
      'followers',
      'following',
      'comments',
      'popular-tracks',
      'spotlight',
      'stats',
      'sets',
    };
    return subpages.contains(segment.toLowerCase());
  }
}

/// SoundCloud URL content type classification.
enum SoundCloudContentType {
  track,
  playlist,
  profile,
  home,
  shortUrl,
  nonContent,
}

/// Pinterest URL helpers for pins, idea pins, boards, profiles, and CDN media.
class PinterestUri {
  const PinterestUri._();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
    'utm_term',
    'fbclid',
    'gclid',
    'igshid',
    'e_t_s',
    'invite_code',
    'sender',
    'sfo',
    'nic_v2',
    'nic_v1',
    'rs',
    'ref_source',
    'source_id',
  };

  static const _systemPages = {
    'ideas',
    'today',
    'search',
    'categories',
    'news_hub',
    'business',
    'about',
    'settings',
    'login',
    'signup',
    'password',
    'pin-builder',
    'following',
    'homefeed',
    'videos',
    'shop',
    'shopping',
    'explore',
    'topics',
    'more-ideas',
    'privacy',
    'terms',
    'help',
    'blog',
    'press',
    'careers',
    'ads',
    'analytics',
    'convert',
    'create',
    'resource',
    'visual-search',
    'invitations',
    'holiday',
    'gift-guide',
    'pinterest-predicts',
    'collections',
    'boards',
    'pin',
  };

  static const _profileSubpages = {
    '_saved',
    '_created',
    'pins',
    'boards',
    'tries',
    'followers',
    '_shop',
    'more_ideas',
    'following',
  };

  static bool isPinterestHost(String host) =>
      SocialPlatform.isPinterestHost(host);

  static bool isDirectMediaHost(String host) {
    final h = host.toLowerCase();
    return h == 'pinimg.com' || h.endsWith('.pinimg.com');
  }

  static bool isShortUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'pin.it' || host.endsWith('.pin.it');
  }

  /// Classifies a Pinterest URL. Idea Pins share `/pin/{id}/` and are
  /// distinguished later from pin JSON (`story_pin_data`), not from the path.
  static PinterestContentType classifyUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    if (isDirectMediaHost(host)) {
      return PinterestContentType.directMedia;
    }

    if (isShortUrl(uri)) {
      return segments.isEmpty
          ? PinterestContentType.home
          : PinterestContentType.shortUrl;
    }

    if (segments.isEmpty) return PinterestContentType.home;

    final first = segments.first.toLowerCase();

    if (first == 'pin') {
      if (segments.length < 2 || segments[1].isEmpty) {
        return PinterestContentType.nonContent;
      }
      return PinterestContentType.pin;
    }

    if (first == 'search') return PinterestContentType.search;

    if (_systemPages.contains(first)) {
      return PinterestContentType.nonContent;
    }

    if (segments.length == 1) return PinterestContentType.profile;

    final second = segments[1].toLowerCase();
    if (second.startsWith('_') || _profileSubpages.contains(second)) {
      return PinterestContentType.profile;
    }

    return PinterestContentType.board;
  }

  /// Extracts the pin ID. Ignores the optional slug and `/sent/` share suffix.
  static String? pinIdFromUri(Uri uri) {
    if (isDirectMediaHost(uri.host)) return null;
    if (isShortUrl(uri)) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    if (segments.first.toLowerCase() != 'pin') return null;
    final id = segments[1].trim();
    if (id.isEmpty) return null;
    return id;
  }

  /// Short-link code from `pin.it/{code}`.
  static String? shortCodeFromUri(Uri uri) {
    if (!isShortUrl(uri)) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final code = segments.first.trim();
    return code.isEmpty ? null : code;
  }

  /// Profile username from profile or board URLs. Null for pins.
  static String? usernameFromUri(Uri uri) {
    final type = classifyUrl(uri);
    if (type != PinterestContentType.profile &&
        type != PinterestContentType.board) {
      return null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final name = segments.first;
    if (name.isEmpty || _systemPages.contains(name.toLowerCase())) return null;
    return name;
  }

  /// Board slug from `/{user}/{board}/`. Not a numeric board id.
  static String? boardSlugFromUri(Uri uri) {
    if (classifyUrl(uri) != PinterestContentType.board) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    final slug = segments[1];
    return slug.isEmpty ? null : slug;
  }

  static bool isPin(Uri uri) => classifyUrl(uri) == PinterestContentType.pin;

  static bool isBoard(Uri uri) =>
      classifyUrl(uri) == PinterestContentType.board;

  static bool isProfile(Uri uri) =>
      classifyUrl(uri) == PinterestContentType.profile;

  static bool isDirectMedia(Uri uri) =>
      classifyUrl(uri) == PinterestContentType.directMedia;

  /// Pins, short links, and direct CDN media can produce a download.
  /// Boards and profiles are collections — not a single media item.
  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      PinterestContentType.pin ||
      PinterestContentType.shortUrl ||
      PinterestContentType.directMedia => true,
      _ => false,
    };
  }

  /// Canonical identity for duplicate detection. Pin ID is primary.
  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    if (type == PinterestContentType.directMedia) {
      final path = uri.path;
      return 'pinterest:media:${uri.host.toLowerCase()}$path';
    }
    if (type == PinterestContentType.shortUrl) {
      final code = shortCodeFromUri(uri);
      return code == null ? null : 'pinterest:short:$code';
    }
    final pinId = pinIdFromUri(uri);
    if (pinId != null) return 'pinterest:pin:$pinId';
    if (type == PinterestContentType.board) {
      final user = usernameFromUri(uri);
      final board = boardSlugFromUri(uri);
      if (user == null || board == null) return null;
      return 'pinterest:board:$user/$board';
    }
    if (type == PinterestContentType.profile) {
      final user = usernameFromUri(uri);
      return user == null ? null : 'pinterest:profile:$user';
    }
    return null;
  }

  /// Strips tracking params, canonicalizes host, and drops the pin slug.
  /// Short links and direct CDN URLs are not rewritten.
  static Uri normalize(Uri uri) {
    final host = uri.host.toLowerCase();

    if (isShortUrl(uri) || isDirectMediaHost(host)) {
      return uri.replace(scheme: 'https', fragment: '');
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere(
        (key, _) =>
            _trackingParams.contains(key.toLowerCase()) ||
            key.toLowerCase().startsWith('utm_'),
      );

    final pinId = pinIdFromUri(uri);
    if (pinId != null) {
      return Uri(
        scheme: 'https',
        host: 'www.pinterest.com',
        path: '/pin/$pinId/',
        queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
      );
    }

    var canonicalHost = uri.host;
    if (isPinterestHost(host) && !isDirectMediaHost(host) && !isShortUrl(uri)) {
      canonicalHost = 'www.pinterest.com';
    }

    var path = uri.path;
    if (path.isEmpty) path = '/';
    if (!path.endsWith('/')) path = '$path/';

    return uri.replace(
      scheme: 'https',
      host: canonicalHost,
      path: path,
      fragment: '',
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  /// Rewrites a sized pinimg URL to the public `/originals/` variant.
  /// Does not invent pixels — it selects the source object on the CDN.
  static String upgradeImageUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || !isDirectMediaHost(uri.host)) return url;
    final path = uri.path;
    if (path.contains('/originals/')) return url;
    if (path.contains('/videos/')) return url;
    final upgraded = path.replaceFirst(
      RegExp(r'^/(?:\d+x\d*|\d+x)/'),
      '/originals/',
    );
    if (upgraded == path) return url;
    return Uri(scheme: uri.scheme, host: uri.host, path: upgraded).toString();
  }
}

/// Pinterest URL content type classification.
enum PinterestContentType {
  home,
  pin,
  board,
  profile,
  shortUrl,
  directMedia,
  search,
  nonContent,
}

/// Vimeo URL helpers shared by fetch targets and the Vimeo resolver.
class VimeoUri {
  const VimeoUri._();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
    'utm_term',
    'fbclid',
    'gclid',
    'igshid',
    'mc_cid',
    'mc_eid',
    'ref',
    'from',
    'share',
    'share_source',
    'autoplay',
    'muted',
    'loop',
    'autopause',
    'background',
    'byline',
    'portrait',
    'title',
    'color',
    'dnt',
    'app_id',
    'embedded',
    'fl',
    'untrusted',
  };

  static const _reservedFirstSegments = {
    'watch',
    'channels',
    'groups',
    'album',
    'showcase',
    'ondemand',
    'manage',
    'settings',
    'search',
    'upload',
    'stock',
    'plus',
    'about',
    'blog',
    'help',
    'join',
    'log_in',
    'login',
    'logout',
    'signin',
    'signup',
    'staffpicks',
    'categories',
    'features',
    'enterprise',
    'create',
    'videos',
    'user',
    'store',
    'professionals',
    'musicstore',
    'school',
    'tv',
    'live',
    'home',
    'explore',
    'upgrade',
    'sitemap',
    'site_map',
    'privacy',
    'terms',
    'cookie',
    'gdpr',
    'ott',
    'jobs',
    'press',
    'advertisers',
    'developers',
    'api',
    'oembed',
    'player',
    'embed',
    'share',
    'download',
    'likes',
    'watchlater',
    'collections',
    'folders',
    'inbox',
    'notifications',
    'stats',
    'analytics',
    'review',
    'page',
    'pages',
    'm',
    'mobile',
    'for',
    'solutions',
    'come',
    'purchases',
  };

  static const _hashReserved = {
    'comments',
    'download',
    'likes',
    'review',
    'videos',
    'about',
    'settings',
    'embed',
    'share',
  };

  static bool isVimeoHost(String host) => SocialPlatform.isVimeoHost(host);

  static bool isPlayerHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'player.vimeo.com' || host.endsWith('.player.vimeo.com');
  }

  static VimeoContentType classifyUrl(Uri uri) {
    if (!isVimeoHost(uri.host)) return VimeoContentType.nonContent;

    final segments = uri.pathSegments
        .where((s) => s.isNotEmpty)
        .map((s) => s.split('.').first)
        .toList();

    if (segments.isEmpty) return VimeoContentType.home;

    final clipId = uri.queryParameters['clip_id'];
    if (clipId != null && _isVideoId(clipId)) {
      return isPlayerHost(uri)
          ? VimeoContentType.player
          : VimeoContentType.video;
    }

    if (isPlayerHost(uri)) {
      if (segments.length >= 2 &&
          segments.first.toLowerCase() == 'video' &&
          _isVideoId(segments[1])) {
        return VimeoContentType.player;
      }
      return VimeoContentType.nonContent;
    }

    final first = segments.first.toLowerCase();

    if (first == 'ondemand') return VimeoContentType.onDemand;
    if (first == 'search') return VimeoContentType.search;
    if (first == 'watch') return VimeoContentType.watch;
    if (first == 'manage' || first == 'settings') {
      return VimeoContentType.manage;
    }
    if (first == 'stock') return VimeoContentType.stock;

    if (first == 'channels') {
      if (segments.length >= 3 && _isVideoId(segments[2])) {
        return VimeoContentType.channelVideo;
      }
      return VimeoContentType.channel;
    }

    if (first == 'groups') {
      if (segments.length >= 4 &&
          segments[2].toLowerCase() == 'videos' &&
          _isVideoId(segments[3])) {
        return VimeoContentType.groupVideo;
      }
      return VimeoContentType.group;
    }

    if (first == 'album' || first == 'showcase') {
      if (segments.length >= 4 &&
          segments[2].toLowerCase() == 'video' &&
          _isVideoId(segments[3])) {
        return VimeoContentType.showcaseVideo;
      }
      return VimeoContentType.showcase;
    }

    if (first == 'user' || first == 'm' || first == 'mobile') {
      if (segments.length >= 2 && _isVideoId(segments[1])) {
        return VimeoContentType.video;
      }
      if (first == 'user') return VimeoContentType.user;
      return VimeoContentType.nonContent;
    }

    if (_reservedFirstSegments.contains(first) && !_isVideoId(first)) {
      return VimeoContentType.nonContent;
    }

    if (_isVideoId(segments.first)) {
      return VimeoContentType.video;
    }

    return VimeoContentType.user;
  }

  static String? videoIdFromUri(Uri uri) {
    if (!isVimeoHost(uri.host)) return null;

    final clipId = uri.queryParameters['clip_id'];
    if (clipId != null && _isVideoId(clipId)) return clipId;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    if (isPlayerHost(uri)) {
      if (segments.length >= 2 && segments.first.toLowerCase() == 'video') {
        final id = segments[1].split('.').first;
        return _isVideoId(id) ? id : null;
      }
      return null;
    }

    final first = segments.first.toLowerCase();

    if (first == 'channels' && segments.length >= 3) {
      final id = segments[2].split('.').first;
      return _isVideoId(id) ? id : null;
    }
    if (first == 'groups' &&
        segments.length >= 4 &&
        segments[2].toLowerCase() == 'videos') {
      final id = segments[3].split('.').first;
      return _isVideoId(id) ? id : null;
    }
    if ((first == 'album' || first == 'showcase') &&
        segments.length >= 4 &&
        segments[2].toLowerCase() == 'video') {
      final id = segments[3].split('.').first;
      return _isVideoId(id) ? id : null;
    }
    if ((first == 'user' || first == 'm' || first == 'mobile') &&
        segments.length >= 2) {
      final id = segments[1].split('.').first;
      return _isVideoId(id) ? id : null;
    }

    final id = segments.first.split('.').first;
    return _isVideoId(id) ? id : null;
  }

  /// Unlisted/share hash from `h=` or `/{id}/{hash}`. Not the content identity.
  static String? privacyHashFromUri(Uri uri) {
    final fromQuery = uri.queryParameters['h'];
    if (fromQuery != null && fromQuery.isNotEmpty && _isHash(fromQuery)) {
      return fromQuery;
    }
    if (!isVimeoHost(uri.host) || isPlayerHost(uri)) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 &&
        _isVideoId(segments.first) &&
        _isHash(segments[1])) {
      return segments[1];
    }
    return null;
  }

  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      VimeoContentType.video ||
      VimeoContentType.player ||
      VimeoContentType.channelVideo ||
      VimeoContentType.groupVideo ||
      VimeoContentType.showcaseVideo => videoIdFromUri(uri) != null,
      _ => false,
    };
  }

  static Uri normalize(Uri uri) {
    if (!isVimeoHost(uri.host)) return uri;

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((key, _) => _trackingParams.contains(key.toLowerCase()));

    final videoId = videoIdFromUri(uri);
    final hash = privacyHashFromUri(uri);

    if (videoId != null) {
      if (hash != null) {
        cleanedParams['h'] = hash;
      }
      final query = cleanedParams.isEmpty
          ? ''
          : cleanedParams.entries
                .map(
                  (e) =>
                      '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                )
                .join('&');
      return Uri.parse(
        query.isEmpty
            ? 'https://vimeo.com/$videoId'
            : 'https://vimeo.com/$videoId?$query',
      );
    }

    return uri.replace(
      scheme: 'https',
      host: isPlayerHost(uri) ? 'player.vimeo.com' : 'vimeo.com',
      fragment: '',
      query: cleanedParams.isEmpty
          ? ''
          : cleanedParams.entries
                .map(
                  (e) =>
                      '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
                )
                .join('&'),
    );
  }

  /// Canonical identity for duplicate detection. Video ID is primary.
  static String? contentIdentity(Uri uri) {
    final videoId = videoIdFromUri(uri);
    if (videoId != null) return 'vimeo:video:$videoId';
    final type = classifyUrl(uri);
    return switch (type) {
      VimeoContentType.home => 'vimeo:home',
      VimeoContentType.user =>
        'vimeo:user:${uri.pathSegments.where((s) => s.isNotEmpty).first}',
      VimeoContentType.channel => 'vimeo:channel:${_secondSegment(uri)}',
      VimeoContentType.group => 'vimeo:group:${_secondSegment(uri)}',
      VimeoContentType.showcase => 'vimeo:showcase:${_secondSegment(uri)}',
      _ => null,
    };
  }

  static String? _secondSegment(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    return segments[1];
  }

  static bool _isVideoId(String value) => RegExp(r'^\d+$').hasMatch(value);

  static bool _isHash(String value) {
    if (_hashReserved.contains(value.toLowerCase())) return false;
    if (_isVideoId(value)) return false;
    return RegExp(r'^[a-zA-Z0-9]{6,16}$').hasMatch(value);
  }
}

/// Vimeo URL content type classification.
enum VimeoContentType {
  home,
  video,
  player,
  channelVideo,
  groupVideo,
  showcaseVideo,
  user,
  channel,
  group,
  showcase,
  onDemand,
  search,
  watch,
  manage,
  stock,
  nonContent,
}

class TwitchUri {
  const TwitchUri._();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
    'utm_term',
    'fbclid',
    'gclid',
    'igshid',
    'mc_cid',
    'mc_eid',
    'ref',
    'sr',
    'lang',
    'tt_medium',
    'tt_content',
    'tt_news',
    'muted',
    'parent',
    'autoplay',
    'allowfullscreen',
    't',
    'time',
    'from',
    'share',
    'feature',
  };

  static const _reservedFirstSegments = {
    'directory',
    'videos',
    'downloads',
    'jobs',
    'p',
    'turbo',
    'products',
    'search',
    'settings',
    'subscriptions',
    'inventory',
    'drops',
    'wallet',
    'bits',
    'store',
    'prime',
    'friends',
    'following',
    'browse',
    'popout',
    'embed',
    'team',
    'teams',
    'communities',
    'messages',
    'notifications',
    'login',
    'signup',
    'signin',
    'sign-in',
    'sign-up',
    'register',
    'activate',
    'privacy',
    'terms',
    'about',
    'help',
    'legal',
    'security',
    'partners',
    'advertise',
    'creators',
    'blog',
    'press',
    'support',
    'api',
    'developers',
    'year',
    'mod',
    'mods',
    'dashboard',
    'analytics',
    'chat',
    'manager',
    'stream-manager',
    'subs',
    'subscribe',
    'broadcast',
    'clips',
    'clip',
    'collections',
    'collection',
    'customer',
    'gift',
    'gifts',
  };

  static const _clipReserved = {
    'embed',
    'api',
    'clips',
    'clip',
    'home',
    'directory',
    'login',
    'signup',
  };

  static bool isTwitchHost(String host) => SocialPlatform.isTwitchHost(host);

  static bool isClipsHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'clips.twitch.tv' || host.endsWith('.clips.twitch.tv');
  }

  static bool isPlayerHost(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'player.twitch.tv' || host.endsWith('.player.twitch.tv');
  }

  static TwitchContentType classifyUrl(Uri uri) {
    if (!isTwitchHost(uri.host)) return TwitchContentType.nonContent;

    if (isClipsHost(uri)) {
      final slug = clipIdFromUri(uri);
      return slug == null
          ? TwitchContentType.nonContent
          : TwitchContentType.clip;
    }

    if (isPlayerHost(uri)) {
      if (clipIdFromUri(uri) != null) return TwitchContentType.clip;
      if (videoIdFromUri(uri) != null) return TwitchContentType.vod;
      if (channelLoginFromUri(uri) != null) return TwitchContentType.channel;
      return TwitchContentType.nonContent;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return TwitchContentType.home;

    final first = segments.first.toLowerCase();

    if (first == 'directory') return TwitchContentType.directory;

    if (first == 'videos') {
      if (segments.length >= 2 && _isVideoId(segments[1])) {
        return TwitchContentType.vod;
      }
      return TwitchContentType.nonContent;
    }

    if (first == 'clip' && segments.length >= 2 && _isClipSlug(segments[1])) {
      return TwitchContentType.clip;
    }

    if (_reservedFirstSegments.contains(first) && !_isChannelLogin(first)) {
      return TwitchContentType.nonContent;
    }
    if (_reservedFirstSegments.contains(first)) {
      return TwitchContentType.nonContent;
    }

    if (!_isChannelLogin(segments.first)) {
      return TwitchContentType.nonContent;
    }

    if (segments.length >= 3) {
      final second = segments[1].toLowerCase();
      if (second == 'clip' && _isClipSlug(segments[2])) {
        return TwitchContentType.clip;
      }
      if ((second == 'video' || second == 'videos' || second == 'v') &&
          _isVideoId(segments[2])) {
        return TwitchContentType.vod;
      }
    }

    if (segments.length >= 2) {
      final second = segments[1].toLowerCase();
      if (second == 'videos' ||
          second == 'clips' ||
          second == 'about' ||
          second == 'schedule' ||
          second == 'home' ||
          second == 'chat' ||
          second == 'followers' ||
          second == 'following') {
        return TwitchContentType.channel;
      }
    }

    return TwitchContentType.channel;
  }

  static String? videoIdFromUri(Uri uri) {
    if (!isTwitchHost(uri.host)) return null;

    final fromQuery =
        uri.queryParameters['video'] ??
        uri.queryParameters['vod'] ??
        uri.queryParameters['v'];
    if (fromQuery != null && _isVideoId(fromQuery)) {
      return _normalizeVideoId(fromQuery);
    }

    if (isClipsHost(uri) || isPlayerHost(uri)) {
      return fromQuery != null && _isVideoId(fromQuery)
          ? _normalizeVideoId(fromQuery)
          : null;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    if (segments.first.toLowerCase() == 'videos' && segments.length >= 2) {
      return _isVideoId(segments[1]) ? _normalizeVideoId(segments[1]) : null;
    }

    if (segments.length >= 3) {
      final second = segments[1].toLowerCase();
      if (second == 'video' || second == 'videos' || second == 'v') {
        return _isVideoId(segments[2]) ? _normalizeVideoId(segments[2]) : null;
      }
    }
    return null;
  }

  static String? clipIdFromUri(Uri uri) {
    if (!isTwitchHost(uri.host)) return null;

    final fromQuery =
        uri.queryParameters['clip'] ??
        uri.queryParameters['slug'] ??
        uri.queryParameters['clip_id'];
    if (fromQuery != null && _isClipSlug(fromQuery)) return fromQuery;

    if (isClipsHost(uri)) {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) return null;
      final first = segments.first;
      if (first.toLowerCase() == 'embed' && segments.length >= 2) {
        return _isClipSlug(segments[1]) ? segments[1] : null;
      }
      return _isClipSlug(first) ? first : null;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments.first.toLowerCase() == 'clip') {
      return _isClipSlug(segments[1]) ? segments[1] : null;
    }
    if (segments.length >= 3 && segments[1].toLowerCase() == 'clip') {
      return _isClipSlug(segments[2]) ? segments[2] : null;
    }
    return null;
  }

  static String? channelLoginFromUri(Uri uri) {
    if (!isTwitchHost(uri.host)) return null;

    final fromQuery =
        uri.queryParameters['channel'] ?? uri.queryParameters['login'];
    if (fromQuery != null && _isChannelLogin(fromQuery)) {
      return fromQuery.toLowerCase();
    }

    if (isClipsHost(uri) || isPlayerHost(uri)) {
      return fromQuery != null && _isChannelLogin(fromQuery)
          ? fromQuery.toLowerCase()
          : null;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final first = segments.first;
    if (_reservedFirstSegments.contains(first.toLowerCase())) return null;
    if (!_isChannelLogin(first)) return null;
    return first.toLowerCase();
  }

  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      TwitchContentType.clip => clipIdFromUri(uri) != null,
      _ => false,
    };
  }

  static Uri normalize(Uri uri) {
    if (!isTwitchHost(uri.host)) return uri;

    final type = classifyUrl(uri);
    final clipId = clipIdFromUri(uri);
    final videoId = videoIdFromUri(uri);
    final channel = channelLoginFromUri(uri);

    if (type == TwitchContentType.clip && clipId != null) {
      return Uri.parse('https://clips.twitch.tv/$clipId');
    }
    if (type == TwitchContentType.vod && videoId != null) {
      return Uri.parse('https://www.twitch.tv/videos/$videoId');
    }
    if (type == TwitchContentType.channel && channel != null) {
      return Uri.parse('https://www.twitch.tv/$channel');
    }
    if (type == TwitchContentType.home) {
      return Uri.parse('https://www.twitch.tv/');
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere((key, _) => _trackingParams.contains(key.toLowerCase()));
    return uri.replace(
      scheme: 'https',
      fragment: '',
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  /// Canonical identity for duplicate detection.
  static String? contentIdentity(Uri uri) {
    final clipId = clipIdFromUri(uri);
    if (clipId != null) return 'twitch:clip:$clipId';
    final videoId = videoIdFromUri(uri);
    if (videoId != null) return 'twitch:video:$videoId';
    final type = classifyUrl(uri);
    return switch (type) {
      TwitchContentType.home => 'twitch:home',
      TwitchContentType.channel =>
        channelLoginFromUri(uri) == null
            ? null
            : 'twitch:channel:${channelLoginFromUri(uri)}',
      _ => null,
    };
  }

  static bool _isVideoId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final withoutPrefix =
        trimmed.toLowerCase().startsWith('v') && trimmed.length > 1
        ? trimmed.substring(1)
        : trimmed;
    return RegExp(r'^\d+$').hasMatch(withoutPrefix);
  }

  static String _normalizeVideoId(String value) {
    final trimmed = value.trim();
    if (trimmed.toLowerCase().startsWith('v') &&
        trimmed.length > 1 &&
        RegExp(r'^\d+$').hasMatch(trimmed.substring(1))) {
      return trimmed.substring(1);
    }
    return trimmed;
  }

  static bool _isClipSlug(String value) {
    if (_clipReserved.contains(value.toLowerCase())) return false;
    if (_isVideoId(value)) return false;
    return RegExp(r'^[A-Za-z0-9_-]{2,128}$').hasMatch(value);
  }

  static bool _isChannelLogin(String value) {
    if (_reservedFirstSegments.contains(value.toLowerCase())) return false;
    return RegExp(r'^[A-Za-z0-9_]{1,25}$').hasMatch(value);
  }
}

/// Twitch URL content type classification.
enum TwitchContentType { home, channel, vod, clip, directory, nonContent }

/// Parses and classifies LinkedIn URLs. Identity is the activity / ugcPost /
/// share ID — never the post slug text.
class LinkedInUri {
  const LinkedInUri._();

  static const _trackingParams = {
    'trk',
    'trkInfo',
    'originalSubdomain',
    'lipi',
    'licu',
    'li_fat_id',
    'rcm',
    'refId',
    'trackingId',
    'midToken',
    'eid',
    'otpToken',
    'session_redirect',
    'fromEmail',
    'isInternal',
    'share_url',
    'commentUrn',
    'replyUrn',
    'ref',
    'source',
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_content',
    'utm_term',
    'si',
  };

  static const _systemPages = {
    'login',
    'signup',
    'uas',
    'authwall',
    'checkpoint',
    'legal',
    'help',
    'about',
    'accessibility',
    'premium',
    'sales',
    'talent',
    'advertising',
    'business',
    'mobile',
    'app',
    'guests',
    'oops',
    '404',
    'settings',
    'mypreferences',
    'notifications',
    'mynetwork',
    'messaging',
    'inbox',
  };

  static final _activityIdPattern = RegExp(
    r'(?:^|[_/-]|urn:li:|urn%3Ali%3A)activity[_:%-]+(\d{10,})',
    caseSensitive: false,
  );
  static final _ugcPostIdPattern = RegExp(
    r'(?:^|[_/-]|urn:li:|urn%3Ali%3A)ugcPost[_:%-]+(\d{10,})',
    caseSensitive: false,
  );
  static final _shareIdPattern = RegExp(
    r'(?:^|[_/-]|urn:li:|urn%3Ali%3A)share[_:%-]+(\d{10,})',
    caseSensitive: false,
  );

  static bool isLinkedInHost(String host) =>
      SocialPlatform.isLinkedInHost(host);

  static bool isShortUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'lnkd.in' || host.endsWith('.lnkd.in');
  }

  static bool isDirectMediaHost(String host) {
    final h = host.toLowerCase();
    if (h == 'licdn.com' || h.endsWith('.licdn.com')) {
      return !h.contains('static.licdn.com');
    }
    return false;
  }

  static bool isDirectMedia(Uri uri) =>
      classifyUrl(uri) == LinkedInContentType.directMedia;

  /// Classifies a LinkedIn URL. Post vs image vs video is refined from HTML.
  static LinkedInContentType classifyUrl(Uri uri) {
    final host = uri.host.toLowerCase();

    if (isShortUrl(uri)) return LinkedInContentType.shortUrl;
    if (isDirectMediaHost(host)) return LinkedInContentType.directMedia;
    if (!isLinkedInHost(host)) return LinkedInContentType.nonContent;

    var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return LinkedInContentType.home;

    if (segments.first.toLowerCase() == 'mwlite' && segments.length >= 2) {
      segments = segments.sublist(1);
    }

    final first = segments.first.toLowerCase();

    if (_systemPages.contains(first)) {
      return first == 'messaging' || first == 'inbox'
          ? LinkedInContentType.messaging
          : LinkedInContentType.nonContent;
    }

    if (first == 'feed') {
      if (segments.length >= 2 && segments[1].toLowerCase() == 'update') {
        return LinkedInContentType.post;
      }
      return LinkedInContentType.feed;
    }

    if (first == 'posts') {
      if (segments.length < 2) return LinkedInContentType.nonContent;
      return LinkedInContentType.post;
    }

    if (first == 'embed') return LinkedInContentType.embed;

    if (first == 'pulse') return LinkedInContentType.article;

    if (first == 'newsletters') return LinkedInContentType.newsletter;

    if (first == 'in' || first == 'pub') {
      return LinkedInContentType.profile;
    }

    if (first == 'company') return LinkedInContentType.company;
    if (first == 'school') return LinkedInContentType.school;
    if (first == 'showcase') return LinkedInContentType.showcase;

    if (first == 'video') return LinkedInContentType.video;

    if (first == 'jobs' || first == 'jobs-guest') {
      return LinkedInContentType.jobs;
    }
    if (first == 'learning') return LinkedInContentType.learning;
    if (first == 'events') return LinkedInContentType.events;
    if (first == 'groups') return LinkedInContentType.groups;
    if (first == 'search') return LinkedInContentType.search;
    if (first == 'sharing') return LinkedInContentType.nonContent;

    return LinkedInContentType.nonContent;
  }

  static String? activityIdFromUri(Uri uri) {
    return _firstId(uri, _activityIdPattern);
  }

  static String? ugcPostIdFromUri(Uri uri) {
    return _firstId(uri, _ugcPostIdPattern);
  }

  static String? shareIdFromUri(Uri uri) {
    return _firstId(uri, _shareIdPattern);
  }

  /// Best available content ID: activity, then ugcPost, then share.
  static String? contentIdFromUri(Uri uri) {
    return activityIdFromUri(uri) ??
        ugcPostIdFromUri(uri) ??
        shareIdFromUri(uri) ??
        _videoPathId(uri) ??
        (isShortUrl(uri) ? shortCodeFromUri(uri) : null);
  }

  static String? shortCodeFromUri(Uri uri) {
    if (!isShortUrl(uri)) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final code = segments.first.trim();
    return code.isEmpty ? null : code;
  }

  /// Author vanity from `/posts/{vanity}_...` or `/in/{vanity}`.
  static String? authorFromUri(Uri uri) {
    var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    if (segments.first.toLowerCase() == 'mwlite' && segments.length >= 2) {
      segments = segments.sublist(1);
    }
    if (segments.length < 2) return null;
    final first = segments.first.toLowerCase();
    if (first == 'in' || first == 'pub') {
      final slug = segments[1];
      return slug.isEmpty ? null : slug;
    }
    if (first == 'posts') {
      final slug = segments[1];
      final underscore = slug.indexOf('_');
      if (underscore <= 0) return null;
      return slug.substring(0, underscore);
    }
    return null;
  }

  static String? companyFromUri(Uri uri) {
    var segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    if (segments.first.toLowerCase() == 'mwlite' && segments.length >= 2) {
      segments = segments.sublist(1);
    }
    if (segments.length < 2) return null;
    final first = segments.first.toLowerCase();
    if (first != 'company' && first != 'school' && first != 'showcase') {
      return null;
    }
    final slug = segments[1];
    return slug.isEmpty ? null : slug;
  }

  static String? authorUrlFromUri(Uri uri) {
    final vanity = authorFromUri(uri);
    if (vanity == null) return null;
    final type = classifyUrl(uri);
    if (type == LinkedInContentType.profile ||
        type == LinkedInContentType.post) {
      return 'https://www.linkedin.com/in/$vanity/';
    }
    return null;
  }

  static String? companyUrlFromUri(Uri uri) {
    final slug = companyFromUri(uri);
    if (slug == null) return null;
    final type = classifyUrl(uri);
    return switch (type) {
      LinkedInContentType.company => 'https://www.linkedin.com/company/$slug/',
      LinkedInContentType.school => 'https://www.linkedin.com/school/$slug/',
      LinkedInContentType.showcase =>
        'https://www.linkedin.com/showcase/$slug/',
      _ => null,
    };
  }

  /// Posts, videos, embeds, short links, and direct CDN media can produce a
  /// download. Profiles, companies, articles, and home/feed cannot.
  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      LinkedInContentType.post ||
      LinkedInContentType.video ||
      LinkedInContentType.embed ||
      LinkedInContentType.shortUrl ||
      LinkedInContentType.directMedia => true,
      _ => false,
    };
  }

  /// Canonical identity for duplicate detection. Numeric IDs beat slugs.
  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    if (type == LinkedInContentType.directMedia) {
      return 'linkedin:media:${uri.host.toLowerCase()}${uri.path}';
    }
    if (type == LinkedInContentType.shortUrl) {
      final code = shortCodeFromUri(uri);
      return code == null ? null : 'linkedin:short:$code';
    }
    final activityId = activityIdFromUri(uri);
    if (activityId != null) return 'linkedin:activity:$activityId';
    final ugcId = ugcPostIdFromUri(uri);
    if (ugcId != null) return 'linkedin:ugcPost:$ugcId';
    final shareId = shareIdFromUri(uri);
    if (shareId != null) return 'linkedin:share:$shareId';
    final videoId = _videoPathId(uri);
    if (videoId != null) return 'linkedin:video:$videoId';
    if (type == LinkedInContentType.profile) {
      final slug = authorFromUri(uri);
      return slug == null ? null : 'linkedin:profile:$slug';
    }
    if (type == LinkedInContentType.company ||
        type == LinkedInContentType.school ||
        type == LinkedInContentType.showcase) {
      final slug = companyFromUri(uri);
      return slug == null ? null : 'linkedin:${type.name}:$slug';
    }
    if (type == LinkedInContentType.home) return 'linkedin:home';
    if (type == LinkedInContentType.feed) return 'linkedin:feed';
    return null;
  }

  /// HTTPS, www host, tracking stripped. Posts canonicalize to the activity URN
  /// when an ID is present so share/mobile/query variants share identity.
  static Uri normalize(Uri uri) {
    if (isShortUrl(uri) || isDirectMediaHost(uri.host)) {
      return uri.replace(
        scheme: uri.scheme.isEmpty ? 'https' : 'https',
        fragment: '',
      );
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere(
        (key, _) =>
            _trackingParams.contains(key) ||
            key.toLowerCase().startsWith('utm_'),
      );

    final activityId = activityIdFromUri(uri);
    if (activityId != null) {
      return Uri.parse(
        'https://www.linkedin.com/feed/update/urn:li:activity:$activityId/',
      );
    }
    final ugcId = ugcPostIdFromUri(uri);
    if (ugcId != null) {
      return Uri.parse(
        'https://www.linkedin.com/feed/update/urn:li:ugcPost:$ugcId/',
      );
    }
    final shareId = shareIdFromUri(uri);
    if (shareId != null) {
      return Uri.parse(
        'https://www.linkedin.com/feed/update/urn:li:share:$shareId/',
      );
    }

    var host = uri.host.toLowerCase();
    if (isLinkedInHost(host) && !isDirectMediaHost(host) && !isShortUrl(uri)) {
      host = 'www.linkedin.com';
    }

    var path = uri.path.isEmpty ? '/' : uri.path;
    if (!path.startsWith('/')) path = '/$path';

    return Uri(
      scheme: 'https',
      host: host,
      path: path,
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  static List<Uri> fetchTargets(Uri uri) {
    final normalized = normalize(uri);
    final targets = <Uri>{uri, normalized};

    if (!isShortUrl(uri) && !isDirectMediaHost(uri.host)) {
      targets.add(Uri.parse(_swapLinkedInHost(normalized, 'www.linkedin.com')));
    }

    final activityId = activityIdFromUri(uri) ?? activityIdFromUri(normalized);
    final ugcId = ugcPostIdFromUri(uri) ?? ugcPostIdFromUri(normalized);
    final shareId = shareIdFromUri(uri) ?? shareIdFromUri(normalized);

    if (activityId != null) {
      targets.add(
        Uri.parse(
          'https://www.linkedin.com/embed/feed/update/urn:li:activity:$activityId',
        ),
      );
      targets.add(
        Uri.parse(
          'https://www.linkedin.com/feed/update/urn:li:activity:$activityId/',
        ),
      );
    }
    if (ugcId != null) {
      targets.add(
        Uri.parse(
          'https://www.linkedin.com/embed/feed/update/urn:li:ugcPost:$ugcId',
        ),
      );
    }
    if (shareId != null) {
      targets.add(
        Uri.parse(
          'https://www.linkedin.com/embed/feed/update/urn:li:share:$shareId',
        ),
      );
    }

    return targets.toList();
  }

  static String _swapLinkedInHost(Uri uri, String host) {
    final path = uri.path.isEmpty ? '/' : uri.path;
    final query = uri.query.isEmpty ? '' : '?${uri.query}';
    return 'https://$host$path$query';
  }

  static String? _firstId(Uri uri, RegExp pattern) {
    final haystacks = <String>[uri.path, uri.query, uri.toString()];
    try {
      haystacks.add(Uri.decodeComponent(uri.path));
    } on Object {
      // Ignore malformed percent-encoding.
    }
    for (final haystack in haystacks) {
      final match = pattern.firstMatch(haystack);
      if (match != null) return match.group(1);
    }
    return null;
  }

  static String? _videoPathId(Uri uri) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length < 2) return null;
    if (segments.first.toLowerCase() != 'video') return null;
    for (final segment in segments.skip(1)) {
      if (RegExp(r'^\d{5,}$').hasMatch(segment)) return segment;
    }
    return null;
  }
}

/// LinkedIn URL content type classification.
enum LinkedInContentType {
  home,
  feed,
  post,
  video,
  article,
  profile,
  company,
  school,
  showcase,
  embed,
  shortUrl,
  directMedia,
  jobs,
  learning,
  events,
  groups,
  search,
  messaging,
  newsletter,
  nonContent,
}

/// Parses and normalizes public Telegram URLs (`t.me`, `telegram.me`, `tg://`).
///
/// Private `/c/` messages and invite links are classified but never treated as
/// downloadable. Deep links are normalized to `https://t.me/...` only when they
/// resolve to a public username (and optional message id).
class TelegramUri {
  const TelegramUri._();

  static const _reservedFirstSegments = {
    's',
    'c',
    'joinchat',
    'share',
    'addstickers',
    'addemoji',
    'addtheme',
    'proxy',
    'socks',
    'setlanguage',
    'iv',
    'login',
    'boost',
    'giftcode',
    'invoice',
    'confirmphone',
    'addlist',
  };

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'fbclid',
    'gclid',
    'mc_cid',
    'mc_eid',
  };

  static final _usernamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{4,31}$');
  static final _messageIdPattern = RegExp(r'^\d+$');
  static final _numericIdPattern = RegExp(r'^\d{5,}$');

  static bool isTelegramHost(String host) =>
      SocialPlatform.isTelegramHost(host);

  static bool isTelegramScheme(Uri uri) => SocialPlatform.isTelegramScheme(uri);

  static bool isDirectMediaHost(String host) {
    final h = host.toLowerCase();
    if (h == 'telesco.pe' || h.endsWith('.telesco.pe')) return true;
    if (h == 'telegram-cdn.org' || h.endsWith('.telegram-cdn.org')) return true;
    if (h == 'cdn.telegram.org' || h.endsWith('.cdn.telegram.org')) return true;
    return false;
  }

  static bool isWebHost(String host) {
    final h = host.toLowerCase();
    if (h == 't.me' || h.endsWith('.t.me')) return true;
    if (h == 'telegram.me' || h.endsWith('.telegram.me')) return true;
    if (h == 'telegram.dog' || h.endsWith('.telegram.dog')) return true;
    return false;
  }

  static TelegramContentType classifyUrl(Uri uri) {
    if (isTelegramScheme(uri)) {
      return _classifyDeepLink(uri);
    }

    final host = uri.host.toLowerCase();
    if (isDirectMediaHost(host)) return TelegramContentType.directMedia;
    if (host == 'telegram.org' || host.endsWith('.telegram.org')) {
      return TelegramContentType.home;
    }
    if (!isWebHost(host) && !isTelegramHost(host)) {
      return TelegramContentType.nonContent;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return TelegramContentType.home;

    final first = segments.first;
    if (first.startsWith('+')) return TelegramContentType.invite;

    final lowerFirst = first.toLowerCase();
    if (lowerFirst == 'joinchat') return TelegramContentType.invite;
    if (lowerFirst == 'share') return TelegramContentType.share;
    if (lowerFirst == 'iv') return TelegramContentType.instantView;
    if (lowerFirst == 'addstickers' ||
        lowerFirst == 'addemoji' ||
        lowerFirst == 'addtheme') {
      return TelegramContentType.stickers;
    }
    if (lowerFirst == 'c') return TelegramContentType.privateMessage;

    if (lowerFirst == 's') {
      if (segments.length < 2) return TelegramContentType.nonContent;
      final channel = segments[1];
      if (!_usernamePattern.hasMatch(channel)) {
        return TelegramContentType.nonContent;
      }
      if (segments.length >= 3 && _messageIdPattern.hasMatch(segments[2])) {
        return TelegramContentType.publicMessagePreview;
      }
      return TelegramContentType.publicChannelPreview;
    }

    if (_reservedFirstSegments.contains(lowerFirst)) {
      return TelegramContentType.nonContent;
    }

    if (!_usernamePattern.hasMatch(first)) {
      return TelegramContentType.nonContent;
    }

    if (segments.length >= 2) {
      if (_messageIdPattern.hasMatch(segments[1])) {
        return TelegramContentType.message;
      }
      return TelegramContentType.nonContent;
    }

    return TelegramContentType.channel;
  }

  static TelegramContentType _classifyDeepLink(Uri uri) {
    final action = uri.host.toLowerCase();
    final params = uri.queryParameters;
    if (action == 'resolve') {
      final domain = params['domain']?.trim() ?? '';
      final post = params['post']?.trim();
      if (!_usernamePattern.hasMatch(domain)) {
        return TelegramContentType.deepLink;
      }
      if (post != null && post.isNotEmpty) {
        return _messageIdPattern.hasMatch(post)
            ? TelegramContentType.message
            : TelegramContentType.deepLink;
      }
      return TelegramContentType.channel;
    }
    if (action == 'join' || action == 'joinchat') {
      return TelegramContentType.invite;
    }
    if (action == 'privatepost') {
      return TelegramContentType.privateMessage;
    }
    if (action == 'msg' || action == 'msg_url' || action == 'share') {
      return TelegramContentType.share;
    }
    if (action.isEmpty) return TelegramContentType.deepLink;
    return TelegramContentType.deepLink;
  }

  static String? channelFromUri(Uri uri) {
    if (isTelegramScheme(uri)) {
      final domain = uri.queryParameters['domain']?.trim();
      if (domain != null && _usernamePattern.hasMatch(domain)) return domain;
      return null;
    }
    if (isDirectMediaHost(uri.host)) return null;

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;

    final first = segments.first;
    if (first.startsWith('+')) return null;
    final lowerFirst = first.toLowerCase();
    if (lowerFirst == 's' && segments.length >= 2) {
      final channel = segments[1];
      return _usernamePattern.hasMatch(channel) ? channel : null;
    }
    if (lowerFirst == 'c') return null;
    if (_reservedFirstSegments.contains(lowerFirst)) return null;
    return _usernamePattern.hasMatch(first) ? first : null;
  }

  static String? messageIdFromUri(Uri uri) {
    if (isTelegramScheme(uri)) {
      final post = uri.queryParameters['post']?.trim();
      if (post != null && _messageIdPattern.hasMatch(post)) return post;
      return null;
    }

    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 3 && segments.first.toLowerCase() == 's') {
      return _messageIdPattern.hasMatch(segments[2]) ? segments[2] : null;
    }
    if (segments.length >= 3 && segments.first.toLowerCase() == 'c') {
      return _messageIdPattern.hasMatch(segments[2]) ? segments[2] : null;
    }
    if (segments.length >= 2 &&
        !_reservedFirstSegments.contains(segments.first.toLowerCase()) &&
        !segments.first.startsWith('+')) {
      return _messageIdPattern.hasMatch(segments[1]) ? segments[1] : null;
    }
    return null;
  }

  static String? privateChannelIdFromUri(Uri uri) {
    if (isTelegramScheme(uri) && uri.host.toLowerCase() == 'privatepost') {
      final channel = uri.queryParameters['channel']?.trim();
      return channel != null && _numericIdPattern.hasMatch(channel)
          ? channel
          : null;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments.first.toLowerCase() == 'c') {
      return _numericIdPattern.hasMatch(segments[1]) ? segments[1] : null;
    }
    return null;
  }

  static String? contentIdFromUri(Uri uri) {
    final channel = channelFromUri(uri);
    final messageId = messageIdFromUri(uri);
    if (channel != null && messageId != null) return '$channel/$messageId';
    return messageId ?? channel;
  }

  /// Message and public-preview posts can yield media. Channels, home, private
  /// `/c/` links, and invites cannot.
  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      TelegramContentType.message ||
      TelegramContentType.publicMessagePreview ||
      TelegramContentType.directMedia => true,
      _ => false,
    };
  }

  static bool isRestricted(Uri uri) {
    return switch (classifyUrl(uri)) {
      TelegramContentType.privateMessage || TelegramContentType.invite => true,
      _ => false,
    };
  }

  /// URL-level login only. Private `/c/` and invites are [isRestricted], not
  /// authentication. Login-walled HTML is classified by [TelegramResolver].
  static bool requiresAuthentication(Uri uri) {
    if (isTelegramScheme(uri) && uri.host.toLowerCase() == 'login') {
      return true;
    }
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    return segments.isNotEmpty && segments.first.toLowerCase() == 'login';
  }

  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    if (type == TelegramContentType.directMedia) {
      return 'telegram:media:${uri.host.toLowerCase()}${uri.path}';
    }
    if (type == TelegramContentType.privateMessage) {
      final channelId = privateChannelIdFromUri(uri);
      final messageId = messageIdFromUri(uri);
      if (channelId != null && messageId != null) {
        return 'telegram:private:$channelId:$messageId';
      }
      return 'telegram:private';
    }
    if (type == TelegramContentType.invite) return 'telegram:invite';
    if (type == TelegramContentType.home) return 'telegram:home';
    final channel = channelFromUri(uri);
    final messageId = messageIdFromUri(uri);
    if (channel != null && messageId != null) {
      return 'telegram:message:$channel:$messageId';
    }
    if (channel != null) {
      return type == TelegramContentType.publicChannelPreview
          ? 'telegram:preview:$channel'
          : 'telegram:channel:$channel';
    }
    if (type == TelegramContentType.share) return 'telegram:share';
    if (type == TelegramContentType.deepLink) return 'telegram:deeplink';
    return null;
  }

  /// HTTPS `t.me` canonical form. Tracking is stripped. Public `tg://resolve`
  /// links become `https://t.me/{domain}` or `https://t.me/{domain}/{post}`.
  static Uri normalize(Uri uri) {
    if (isTelegramScheme(uri)) {
      return tryNormalizeDeepLink(uri) ?? uri;
    }
    if (isDirectMediaHost(uri.host)) {
      return uri.replace(scheme: 'https', fragment: '');
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere(
        (key, _) =>
            _trackingParams.contains(key.toLowerCase()) ||
            key.toLowerCase().startsWith('utm_'),
      )
      ..remove('embed')
      ..remove('mode')
      ..remove('single');

    final type = classifyUrl(uri);
    final channel = channelFromUri(uri);
    final messageId = messageIdFromUri(uri);

    if (channel != null && messageId != null) {
      return Uri.parse('https://t.me/$channel/$messageId');
    }
    if (channel != null &&
        (type == TelegramContentType.channel ||
            type == TelegramContentType.publicChannelPreview)) {
      if (type == TelegramContentType.publicChannelPreview) {
        return Uri.parse('https://t.me/s/$channel');
      }
      return Uri.parse('https://t.me/$channel');
    }

    if (type == TelegramContentType.privateMessage) {
      final channelId = privateChannelIdFromUri(uri);
      if (channelId != null && messageId != null) {
        return Uri.parse('https://t.me/c/$channelId/$messageId');
      }
    }

    if (type == TelegramContentType.home) {
      if (uri.host.toLowerCase().contains('telegram.org')) {
        return Uri.parse('https://telegram.org/');
      }
      return Uri.parse('https://t.me/');
    }

    var path = uri.path.isEmpty ? '/' : uri.path;
    if (!path.startsWith('/')) path = '/$path';
    return Uri(
      scheme: 'https',
      host: isWebHost(uri.host) ? 't.me' : uri.host.toLowerCase(),
      path: path,
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  /// Converts a public `tg://resolve` deep link to `https://t.me/...`.
  /// Returns null for invites, private posts, and malformed deep links.
  static Uri? tryNormalizeDeepLink(Uri uri) {
    if (!isTelegramScheme(uri)) return null;
    if (classifyUrl(uri) == TelegramContentType.invite ||
        classifyUrl(uri) == TelegramContentType.privateMessage) {
      return null;
    }
    final action = uri.host.toLowerCase();
    if (action != 'resolve') return null;
    final domain = uri.queryParameters['domain']?.trim() ?? '';
    if (!_usernamePattern.hasMatch(domain)) return null;
    final post = uri.queryParameters['post']?.trim();
    if (post != null && post.isNotEmpty) {
      if (!_messageIdPattern.hasMatch(post)) return null;
      return Uri.parse('https://t.me/$domain/$post');
    }
    return Uri.parse('https://t.me/$domain');
  }

  static String deepLinkRejectionMessage(Uri uri) {
    return switch (classifyUrl(uri)) {
      TelegramContentType.invite =>
        'This Telegram invite is restricted. The app cannot join private '
            'groups or bypass invite links.',
      TelegramContentType.privateMessage =>
        'This Telegram content is restricted.',
      TelegramContentType.channel =>
        'This Telegram deep link is a channel, not a downloadable message.',
      _ => 'This Telegram link is not a downloadable public message.',
    };
  }

  static List<Uri> fetchTargets(Uri uri) {
    final normalized = normalize(uri);
    final targets = <Uri>{uri, normalized};
    final channel = channelFromUri(uri) ?? channelFromUri(normalized);
    final messageId = messageIdFromUri(uri) ?? messageIdFromUri(normalized);
    if (channel != null && messageId != null) {
      targets.add(Uri.parse('https://t.me/s/$channel/$messageId'));
      targets.add(Uri.parse('https://t.me/$channel/$messageId?embed=1'));
      targets.add(
        Uri.parse('https://t.me/$channel/$messageId?embed=1&mode=tme'),
      );
    } else if (channel != null) {
      targets.add(Uri.parse('https://t.me/s/$channel'));
      targets.add(Uri.parse('https://t.me/$channel'));
    }
    return targets.toList();
  }
}

/// Telegram URL content type classification.
enum TelegramContentType {
  home,
  channel,
  publicChannelPreview,
  message,
  publicMessagePreview,
  privateMessage,
  invite,
  share,
  stickers,
  instantView,
  deepLink,
  directMedia,
  nonContent,
}

/// Parses and normalizes public Snapchat URLs (web, share, story, Spotlight).
class SnapchatUri {
  const SnapchatUri._();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'fbclid',
    'gclid',
    'mc_cid',
    'mc_eid',
    'sc_referrer',
    'sc_ua',
  };

  static const _reservedFirstSegments = {
    'download',
    'discover',
    'create',
    'snapcodes',
    'support',
    'legal',
    'privacy',
    'ads',
    'about',
    'newsroom',
    'jobs',
    'careers',
    'press',
    'map',
    'bitmoji',
    'plus',
    'search',
    'explore',
    'help',
    'terms',
    'cookies',
    'safety',
    'parents',
    'advertisers',
    'developers',
    'docs',
    'business',
    'creators',
    'news',
    'values',
    'for-business',
    'for-creators',
    'public-profiles',
    'get-the-app',
    'ghost',
    'ios',
    'android',
    'kit',
    'snapkit',
  };

  static const _privateFirstSegments = {
    'chat',
    'memories',
    'friends',
    'snaps',
    'messages',
  };

  static const _authFirstSegments = {
    'login',
    'accounts',
    'signup',
    'register',
    'auth',
    'oauth',
    'account',
  };

  static final _usernamePattern = RegExp(r'^[a-zA-Z][a-zA-Z0-9._-]{1,23}$');
  static final _idPattern = RegExp(r'^[A-Za-z0-9_-]{4,}$');

  static bool isSnapchatHost(String host) =>
      SocialPlatform.isSnapchatHost(host);

  static bool isSnapchatScheme(Uri uri) =>
      SocialPlatform.isSnapchatScheme(uri);

  static bool isDirectMediaHost(String host) {
    final h = host.toLowerCase();
    return h == 'sc-cdn.net' || h.endsWith('.sc-cdn.net');
  }

  static bool isWebHost(String host) {
    final h = host.toLowerCase();
    if (h == 'snapchat.com' || h.endsWith('.snapchat.com')) return true;
    return false;
  }

  static bool isShareHost(String host) {
    final h = host.toLowerCase();
    return h == 't.snapchat.com' || h.endsWith('.t.snapchat.com');
  }

  static bool isStoryHost(String host) {
    final h = host.toLowerCase();
    return h == 'story.snapchat.com' || h.endsWith('.story.snapchat.com');
  }

  static bool isAccountsHost(String host) {
    final h = host.toLowerCase();
    return h == 'accounts.snapchat.com' ||
        h.endsWith('.accounts.snapchat.com');
  }

  static SnapchatContentType classifyUrl(Uri uri) {
    if (isSnapchatScheme(uri)) return _classifyDeepLink(uri);

    final host = uri.host.toLowerCase();
    if (isDirectMediaHost(host)) return SnapchatContentType.directMedia;
    if (isAccountsHost(host)) return SnapchatContentType.authentication;
    if (!isWebHost(host)) return SnapchatContentType.nonContent;

    if (isShareHost(host)) {
      final segments = _segments(uri);
      if (segments.isEmpty) return SnapchatContentType.home;
      return _idPattern.hasMatch(segments.first)
          ? SnapchatContentType.share
          : SnapchatContentType.nonContent;
    }

    if (isStoryHost(host)) {
      return _classifyStoryHost(uri);
    }

    final segments = _segments(uri);
    if (segments.isEmpty) return SnapchatContentType.home;

    final first = segments.first;
    final lowerFirst = first.toLowerCase();

    if (_authFirstSegments.contains(lowerFirst)) {
      return SnapchatContentType.authentication;
    }
    if (_privateFirstSegments.contains(lowerFirst)) {
      return SnapchatContentType.private;
    }
    if (lowerFirst == 'stories') return SnapchatContentType.private;

    if (lowerFirst == 'add') {
      if (segments.length >= 2 && _isUsername(segments[1])) {
        return SnapchatContentType.publicProfile;
      }
      return SnapchatContentType.nonContent;
    }

    if (first.startsWith('@')) {
      final username = first.substring(1);
      if (!_isUsername(username)) return SnapchatContentType.nonContent;
      if (segments.length >= 3 &&
          segments[1].toLowerCase() == 'spotlight') {
        return SnapchatContentType.spotlight;
      }
      if (segments.length >= 2 &&
          segments[1].toLowerCase() == 'spotlight') {
        return SnapchatContentType.spotlightFeed;
      }
      return SnapchatContentType.publicProfile;
    }

    if (lowerFirst == 'p') {
      if (segments.length < 2) return SnapchatContentType.nonContent;
      if (segments.length >= 3 &&
          segments[2].toLowerCase() == 'highlights') {
        return SnapchatContentType.savedStory;
      }
      if (segments.length >= 3) return SnapchatContentType.publicStory;
      return SnapchatContentType.publicProfile;
    }

    if (lowerFirst == 'spotlight') {
      if (segments.length < 2) return SnapchatContentType.spotlightFeed;
      return SnapchatContentType.spotlight;
    }

    if (lowerFirst == 't') {
      if (segments.length >= 2 && _idPattern.hasMatch(segments[1])) {
        return SnapchatContentType.share;
      }
      return SnapchatContentType.nonContent;
    }

    if (lowerFirst == 'embed') {
      if (segments.length >= 2) return SnapchatContentType.embed;
      return SnapchatContentType.nonContent;
    }

    if (lowerFirst == 'lens' ||
        lowerFirst == 'lenses' ||
        lowerFirst == 'unlock') {
      return SnapchatContentType.lens;
    }

    if (lowerFirst == 'story') {
      if (segments.length >= 3) return SnapchatContentType.savedStory;
      if (segments.length >= 2) return SnapchatContentType.publicStory;
      return SnapchatContentType.nonContent;
    }

    if (lowerFirst == 'snap') {
      if (segments.length >= 2) return SnapchatContentType.snap;
      return SnapchatContentType.nonContent;
    }

    if (_reservedFirstSegments.contains(lowerFirst)) {
      return SnapchatContentType.nonContent;
    }

    return SnapchatContentType.nonContent;
  }

  static SnapchatContentType _classifyStoryHost(Uri uri) {
    final segments = _segments(uri);
    if (segments.isEmpty) return SnapchatContentType.home;
    if (segments.first.toLowerCase() == 's') {
      if (segments.length >= 3) return SnapchatContentType.savedStory;
      if (segments.length >= 2 && _isUsername(segments[1])) {
        return SnapchatContentType.publicStory;
      }
      return SnapchatContentType.nonContent;
    }
    if (segments.first.toLowerCase() == 'p' && segments.length >= 2) {
      return segments.length >= 3
          ? SnapchatContentType.savedStory
          : SnapchatContentType.publicStory;
    }
    return SnapchatContentType.nonContent;
  }

  static SnapchatContentType _classifyDeepLink(Uri uri) {
    final action = uri.host.toLowerCase();
    final params = uri.queryParameters;
    if (action == 'add') {
      final username = _pathUsername(uri) ?? params['username']?.trim();
      return username != null && _isUsername(username)
          ? SnapchatContentType.publicProfile
          : SnapchatContentType.deepLink;
    }
    if (action == 'spotlight') {
      final id = _pathId(uri) ?? params['id']?.trim();
      return id != null && id.isNotEmpty
          ? SnapchatContentType.spotlight
          : SnapchatContentType.deepLink;
    }
    if (action == 'story') {
      final username = _pathUsername(uri) ?? params['username']?.trim();
      return username != null && _isUsername(username)
          ? SnapchatContentType.publicStory
          : SnapchatContentType.deepLink;
    }
    if (action == 'snap' || action == 'detail') {
      return SnapchatContentType.snap;
    }
    if (action == 'embed') return SnapchatContentType.embed;
    if (action == 'unlock' || action == 'lens') {
      return SnapchatContentType.lens;
    }
    if (action == 'chat' || action == 'memories' || action == 'friends') {
      return SnapchatContentType.private;
    }
    if (action == 'login' || action == 'accounts' || action == 'auth') {
      return SnapchatContentType.authentication;
    }
    if (action.isEmpty) return SnapchatContentType.deepLink;
    return SnapchatContentType.deepLink;
  }

  static String? usernameFromUri(Uri uri) {
    if (isSnapchatScheme(uri)) {
      final action = uri.host.toLowerCase();
      if (action == 'add' || action == 'story') {
        return _pathUsername(uri) ??
            uri.queryParameters['username']?.trim();
      }
      return null;
    }
    if (isDirectMediaHost(uri.host) || isAccountsHost(uri.host)) return null;

    final segments = _segments(uri);
    if (segments.isEmpty) return null;

    if (isStoryHost(uri.host) &&
        segments.first.toLowerCase() == 's' &&
        segments.length >= 2) {
      return _isUsername(segments[1]) ? segments[1] : null;
    }

    final first = segments.first;
    if (first.toLowerCase() == 'add' && segments.length >= 2) {
      return _isUsername(segments[1]) ? segments[1] : null;
    }
    if (first.startsWith('@')) {
      final username = first.substring(1);
      return _isUsername(username) ? username : null;
    }
    if (first.toLowerCase() == 'story' && segments.length >= 2) {
      return _isUsername(segments[1]) ? segments[1] : null;
    }
    return null;
  }

  static String? profileIdFromUri(Uri uri) {
    final segments = _segments(uri);
    if (segments.length >= 2 && segments.first.toLowerCase() == 'p') {
      return segments[1].isNotEmpty ? segments[1] : null;
    }
    return null;
  }

  static String? spotlightIdFromUri(Uri uri) {
    if (isSnapchatScheme(uri) && uri.host.toLowerCase() == 'spotlight') {
      return _pathId(uri) ?? uri.queryParameters['id']?.trim();
    }
    final segments = _segments(uri);
    if (segments.length >= 3 &&
        segments.first.startsWith('@') &&
        segments[1].toLowerCase() == 'spotlight') {
      return segments[2].isNotEmpty ? segments[2] : null;
    }
    if (segments.length >= 2 &&
        (segments.first.toLowerCase() == 'spotlight' ||
            segments.first.toLowerCase() == 'embed')) {
      return segments[1].isNotEmpty ? segments[1] : null;
    }
    return null;
  }

  static String? storyIdFromUri(Uri uri) {
    final segments = _segments(uri);
    if (segments.length >= 4 &&
        segments.first.toLowerCase() == 'p' &&
        segments[2].toLowerCase() == 'highlights') {
      return segments[3];
    }
    if (segments.length >= 3 && segments.first.toLowerCase() == 'p') {
      return segments[2];
    }
    if (isStoryHost(uri.host) &&
        segments.length >= 3 &&
        segments.first.toLowerCase() == 's') {
      return segments[2];
    }
    if (segments.length >= 3 && segments.first.toLowerCase() == 'story') {
      return segments[2];
    }
    return null;
  }

  static String? shareCodeFromUri(Uri uri) {
    if (isShareHost(uri.host)) {
      final segments = _segments(uri);
      return segments.isNotEmpty ? segments.first : null;
    }
    final segments = _segments(uri);
    if (segments.length >= 2 && segments.first.toLowerCase() == 't') {
      return segments[1];
    }
    return null;
  }

  static String? snapIdFromUri(Uri uri) {
    if (isSnapchatScheme(uri) &&
        (uri.host.toLowerCase() == 'snap' ||
            uri.host.toLowerCase() == 'detail')) {
      return _pathId(uri) ?? uri.queryParameters['id']?.trim();
    }
    final segments = _segments(uri);
    if (segments.length >= 2 && segments.first.toLowerCase() == 'snap') {
      return segments[1];
    }
    return null;
  }

  static String? contentIdFromUri(Uri uri) {
    return spotlightIdFromUri(uri) ??
        snapIdFromUri(uri) ??
        storyIdFromUri(uri) ??
        shareCodeFromUri(uri) ??
        usernameFromUri(uri) ??
        profileIdFromUri(uri);
  }

  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      SnapchatContentType.spotlight ||
      SnapchatContentType.publicStory ||
      SnapchatContentType.savedStory ||
      SnapchatContentType.snap ||
      SnapchatContentType.share ||
      SnapchatContentType.embed ||
      SnapchatContentType.directMedia => true,
      _ => false,
    };
  }

  static bool isRestricted(Uri uri) {
    return classifyUrl(uri) == SnapchatContentType.private;
  }

  static bool requiresAuthentication(Uri uri) {
    return classifyUrl(uri) == SnapchatContentType.authentication;
  }

  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    switch (type) {
      case SnapchatContentType.directMedia:
        return 'snapchat:media:${uri.host.toLowerCase()}${uri.path}';
      case SnapchatContentType.home:
        return 'snapchat:home';
      case SnapchatContentType.private:
        return 'snapchat:private';
      case SnapchatContentType.authentication:
        return 'snapchat:auth';
      case SnapchatContentType.spotlightFeed:
        return 'snapchat:spotlight-feed';
      case SnapchatContentType.lens:
        return 'snapchat:lens';
      case SnapchatContentType.deepLink:
        return 'snapchat:deeplink';
      case SnapchatContentType.nonContent:
        return null;
      case SnapchatContentType.publicProfile:
        final username = usernameFromUri(uri);
        final profileId = profileIdFromUri(uri);
        if (username != null) return 'snapchat:profile:$username';
        if (profileId != null) return 'snapchat:profile:$profileId';
        return 'snapchat:profile';
      case SnapchatContentType.spotlight:
      case SnapchatContentType.embed:
        final id = spotlightIdFromUri(uri);
        return id == null ? 'snapchat:spotlight' : 'snapchat:spotlight:$id';
      case SnapchatContentType.publicStory:
        final storyId = storyIdFromUri(uri);
        final username = usernameFromUri(uri);
        final profileId = profileIdFromUri(uri);
        if (storyId != null) return 'snapchat:story:$storyId';
        if (username != null) return 'snapchat:story:$username';
        if (profileId != null) return 'snapchat:story:$profileId';
        return 'snapchat:story';
      case SnapchatContentType.savedStory:
        final storyId = storyIdFromUri(uri);
        return storyId == null
            ? 'snapchat:saved'
            : 'snapchat:saved:$storyId';
      case SnapchatContentType.share:
        final code = shareCodeFromUri(uri);
        return code == null ? 'snapchat:share' : 'snapchat:share:$code';
      case SnapchatContentType.snap:
        final id = snapIdFromUri(uri);
        return id == null ? 'snapchat:snap' : 'snapchat:snap:$id';
    }
  }

  /// HTTPS canonical form. Tracking is stripped. Public deep links become web
  /// URLs. Share short links keep `t.snapchat.com` so redirects can resolve.
  static Uri normalize(Uri uri) {
    if (isSnapchatScheme(uri)) {
      return tryNormalizeDeepLink(uri) ?? uri;
    }
    if (isDirectMediaHost(uri.host)) {
      return uri.replace(scheme: 'https', fragment: '');
    }

    final type = classifyUrl(uri);
    final username = usernameFromUri(uri);
    final spotlightId = spotlightIdFromUri(uri);
    final profileId = profileIdFromUri(uri);
    final storyId = storyIdFromUri(uri);
    final shareCode = shareCodeFromUri(uri);
    final snapId = snapIdFromUri(uri);

    if (type == SnapchatContentType.publicProfile) {
      if (username != null) {
        return Uri.parse('https://www.snapchat.com/add/$username');
      }
      if (profileId != null) {
        return Uri.parse('https://www.snapchat.com/p/$profileId');
      }
    }
    if (type == SnapchatContentType.spotlight && spotlightId != null) {
      return Uri.parse('https://www.snapchat.com/spotlight/$spotlightId');
    }
    if (type == SnapchatContentType.embed && spotlightId != null) {
      return Uri.parse('https://www.snapchat.com/spotlight/$spotlightId');
    }
    if (type == SnapchatContentType.share && shareCode != null) {
      return Uri.parse('https://www.snapchat.com/t/$shareCode');
    }
    if (type == SnapchatContentType.publicStory) {
      if (username != null && storyId == null) {
        return Uri.parse('https://story.snapchat.com/s/$username');
      }
      if (profileId != null && storyId != null) {
        return Uri.parse('https://www.snapchat.com/p/$profileId/$storyId');
      }
    }
    if (type == SnapchatContentType.savedStory &&
        profileId != null &&
        storyId != null) {
      return Uri.parse(
        'https://www.snapchat.com/p/$profileId/highlights/$storyId',
      );
    }
    if (type == SnapchatContentType.snap && snapId != null) {
      return Uri.parse('https://www.snapchat.com/snap/$snapId');
    }
    if (type == SnapchatContentType.home) {
      return Uri.parse('https://www.snapchat.com/');
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere(
        (key, _) =>
            _trackingParams.contains(key.toLowerCase()) ||
            key.toLowerCase().startsWith('utm_'),
      );

    var path = uri.path.isEmpty ? '/' : uri.path;
    if (!path.startsWith('/')) path = '/$path';
    return Uri(
      scheme: 'https',
      host: isShareHost(uri.host)
          ? 't.snapchat.com'
          : isStoryHost(uri.host)
          ? 'story.snapchat.com'
          : 'www.snapchat.com',
      path: path,
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  static Uri? tryNormalizeDeepLink(Uri uri) {
    if (!isSnapchatScheme(uri)) return null;
    final type = classifyUrl(uri);
    if (type == SnapchatContentType.private ||
        type == SnapchatContentType.authentication) {
      return null;
    }
    final username = usernameFromUri(uri);
    final spotlightId = spotlightIdFromUri(uri);
    final snapId = snapIdFromUri(uri);
    if (type == SnapchatContentType.publicProfile && username != null) {
      return Uri.parse('https://www.snapchat.com/add/$username');
    }
    if (type == SnapchatContentType.spotlight && spotlightId != null) {
      return Uri.parse('https://www.snapchat.com/spotlight/$spotlightId');
    }
    if (type == SnapchatContentType.publicStory && username != null) {
      return Uri.parse('https://story.snapchat.com/s/$username');
    }
    if (type == SnapchatContentType.snap && snapId != null) {
      return Uri.parse('https://www.snapchat.com/snap/$snapId');
    }
    return null;
  }

  static String deepLinkRejectionMessage(Uri uri) {
    return switch (classifyUrl(uri)) {
      SnapchatContentType.private =>
        'This Snapchat content is restricted.',
      SnapchatContentType.authentication =>
        'Snapchat authentication is required.',
      SnapchatContentType.publicProfile =>
        'This Snapchat deep link is a public profile, not downloadable media.',
      _ => 'This Snapchat link is not a downloadable public item.',
    };
  }

  static List<Uri> fetchTargets(Uri uri) {
    final normalized = normalize(uri);
    final targets = <Uri>{uri, normalized};
    final spotlightId =
        spotlightIdFromUri(uri) ?? spotlightIdFromUri(normalized);
    final username = usernameFromUri(uri) ?? usernameFromUri(normalized);
    final shareCode = shareCodeFromUri(uri) ?? shareCodeFromUri(normalized);
    if (spotlightId != null) {
      targets.add(Uri.parse('https://www.snapchat.com/spotlight/$spotlightId'));
      if (username != null) {
        targets.add(
          Uri.parse(
            'https://www.snapchat.com/@$username/spotlight/$spotlightId',
          ),
        );
      }
    } else if (shareCode != null) {
      targets.add(Uri.parse('https://t.snapchat.com/$shareCode'));
      targets.add(Uri.parse('https://www.snapchat.com/t/$shareCode'));
    } else if (username != null) {
      targets.add(Uri.parse('https://www.snapchat.com/add/$username'));
      targets.add(Uri.parse('https://www.snapchat.com/@$username'));
      targets.add(Uri.parse('https://story.snapchat.com/s/$username'));
    }
    return targets.toList();
  }

  static List<String> _segments(Uri uri) =>
      uri.pathSegments.where((s) => s.isNotEmpty).toList();

  static bool _isUsername(String value) {
    final cleaned = value.startsWith('@') ? value.substring(1) : value;
    return _usernamePattern.hasMatch(cleaned);
  }

  static String? _pathUsername(Uri uri) {
    final segments = _segments(uri);
    if (segments.isEmpty) return null;
    final value = segments.first.startsWith('@')
        ? segments.first.substring(1)
        : segments.first;
    return _isUsername(value) ? value : null;
  }

  static String? _pathId(Uri uri) {
    final segments = _segments(uri);
    return segments.isEmpty ? null : segments.first;
  }
}

/// Snapchat URL content type classification.
enum SnapchatContentType {
  home,
  publicProfile,
  publicStory,
  savedStory,
  spotlight,
  spotlightFeed,
  snap,
  share,
  embed,
  lens,
  private,
  authentication,
  deepLink,
  directMedia,
  nonContent,
}

/// Parses and normalizes public Threads URLs (`threads.net`, `threads.com`).
///
/// Profiles and the home page are classified and are never treated as
/// downloadable media. Share / tracking variants of the same post collapse to
/// one `threads:post:{id}` identity. Private posts cannot be identified from
/// the URL alone — the resolver classifies those from public HTML.
class ThreadsUri {
  const ThreadsUri._();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'fbclid',
    'gclid',
    'igshid',
    'igsh',
    'xmt',
    '_r',
    '_se',
    'hl',
    'ref',
    'source',
    'si',
    'mibextid',
    'next',
  };

  static const _systemPages = {
    'search',
    'activity',
    'liked',
    'following',
    'followers',
    'settings',
    'privacy',
    'terms',
    'about',
    'download',
    'help',
    'legal',
    'cookies',
    'notifications',
    'inbox',
    'messages',
    'explore',
    'saved',
    'archive',
    'tos',
    'community',
  };

  static const _authPages = {
    'login',
    'signup',
    'accounts',
    'auth',
    'oauth',
    'register',
  };

  static final _usernamePattern = RegExp(r'^[A-Za-z0-9._]{1,30}$');
  static final _postIdPattern = RegExp(r'^[A-Za-z0-9_-]{5,}$');

  static bool isThreadsHost(String host) => SocialPlatform.isThreadsHost(host);

  static bool isShareHost(String host) {
    final h = host.toLowerCase();
    return h == 'l.threads.net' ||
        h == 'l.threads.com' ||
        h.endsWith('.l.threads.net') ||
        h.endsWith('.l.threads.com');
  }

  static bool isWebHost(String host) {
    final h = host.toLowerCase();
    if (isShareHost(h)) return true;
    return isThreadsHost(h);
  }

  static ThreadsContentType classifyUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    if (!isWebHost(host)) return ThreadsContentType.nonContent;

    if (isShareHost(host)) {
      final segments = _segments(uri);
      if (segments.isEmpty) return ThreadsContentType.home;
      return ThreadsContentType.share;
    }

    final segments = _segments(uri);
    if (segments.isEmpty) return ThreadsContentType.home;

    final first = segments.first;
    final lowerFirst = first.toLowerCase();

    if (_authPages.contains(lowerFirst)) {
      return ThreadsContentType.authentication;
    }
    if (_systemPages.contains(lowerFirst)) {
      return ThreadsContentType.nonContent;
    }

    if (lowerFirst == 'embed') {
      return postIdFromUri(uri) == null
          ? ThreadsContentType.nonContent
          : ThreadsContentType.embed;
    }

    if (lowerFirst == 't') {
      if (segments.length >= 2 && _isPostId(segments[1])) {
        return ThreadsContentType.post;
      }
      return ThreadsContentType.nonContent;
    }

    if (lowerFirst == 'post') {
      if (segments.length < 2 || !_isPostId(segments[1])) {
        return ThreadsContentType.nonContent;
      }
      if (segments.length >= 3 && segments[2].toLowerCase() == 'embed') {
        return ThreadsContentType.embed;
      }
      return ThreadsContentType.post;
    }

    if (first.startsWith('@')) {
      final username = first.substring(1);
      if (!_isUsername(username)) return ThreadsContentType.nonContent;
      if (segments.length >= 3 &&
          segments[1].toLowerCase() == 'post' &&
          _isPostId(segments[2])) {
        if (segments.length >= 4 && segments[3].toLowerCase() == 'embed') {
          return ThreadsContentType.embed;
        }
        return ThreadsContentType.post;
      }
      if (segments.length == 1) return ThreadsContentType.profile;
      return ThreadsContentType.nonContent;
    }

    return ThreadsContentType.nonContent;
  }

  static String? usernameFromUri(Uri uri) {
    final segments = _segments(uri);
    if (segments.isEmpty) return null;
    final first = segments.first;
    if (first.startsWith('@')) {
      final username = first.substring(1);
      return _isUsername(username) ? username : null;
    }
    return null;
  }

  static String? postIdFromUri(Uri uri) {
    final segments = _segments(uri);
    for (var i = 0; i < segments.length; i++) {
      final lower = segments[i].toLowerCase();
      if ((lower == 'post' || lower == 't' || lower == 'embed') &&
          i + 1 < segments.length &&
          _isPostId(segments[i + 1])) {
        return segments[i + 1];
      }
    }
    final fromQuery = uri.queryParameters['post_id'] ??
        uri.queryParameters['id'] ??
        uri.queryParameters['shortcode'];
    if (fromQuery != null && _isPostId(fromQuery)) return fromQuery;
    return null;
  }

  static String? authorUrlFromUri(Uri uri) {
    final username = usernameFromUri(uri);
    if (username == null) return null;
    return 'https://www.threads.net/@$username';
  }

  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      ThreadsContentType.post ||
      ThreadsContentType.embed ||
      ThreadsContentType.share => true,
      _ => false,
    };
  }

  static bool requiresAuthentication(Uri uri) =>
      classifyUrl(uri) == ThreadsContentType.authentication;

  static bool isRestricted(Uri uri) => requiresAuthentication(uri);

  /// Canonical identity for duplicate detection.
  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    final postId = postIdFromUri(uri);
    if (postId != null) return 'threads:post:$postId';
    if (type == ThreadsContentType.share) {
      final segments = _segments(uri);
      final code = segments.isEmpty ? null : segments.first;
      return code == null ? 'threads:share' : 'threads:share:$code';
    }
    if (type == ThreadsContentType.profile) {
      final username = usernameFromUri(uri);
      return username == null ? 'threads:profile' : 'threads:profile:$username';
    }
    if (type == ThreadsContentType.home) return 'threads:home';
    if (type == ThreadsContentType.authentication) return 'threads:auth';
    return null;
  }

  /// HTTPS, `www.threads.net`, tracking stripped. Posts canonicalize to
  /// `/@user/post/{id}` when a username is present.
  static Uri normalize(Uri uri) {
    final postId = postIdFromUri(uri);
    final username = usernameFromUri(uri);
    final type = classifyUrl(uri);

    if (type == ThreadsContentType.share && postId == null) {
      return uri.replace(
        scheme: 'https',
        fragment: '',
      );
    }

    if (postId != null && username != null) {
      return Uri.parse('https://www.threads.net/@$username/post/$postId');
    }
    if (postId != null) {
      return Uri.parse('https://www.threads.net/t/$postId');
    }
    if (type == ThreadsContentType.profile && username != null) {
      return Uri.parse('https://www.threads.net/@$username');
    }
    if (type == ThreadsContentType.home) {
      return Uri.parse('https://www.threads.net/');
    }
    if (type == ThreadsContentType.authentication) {
      return Uri.parse('https://www.threads.net/login');
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere(
        (key, _) =>
            _trackingParams.contains(key) ||
            key.toLowerCase().startsWith('utm_'),
      );

    var path = uri.path.isEmpty ? '/' : uri.path;
    if (!path.startsWith('/')) path = '/$path';

    return Uri(
      scheme: 'https',
      host: 'www.threads.net',
      path: path,
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  static List<Uri> fetchTargets(Uri uri) {
    final normalized = normalize(uri);
    final targets = <Uri>{uri, normalized};
    final postId = postIdFromUri(uri) ?? postIdFromUri(normalized);
    final username = usernameFromUri(uri) ?? usernameFromUri(normalized);

    if (postId != null) {
      targets.add(Uri.parse('https://www.threads.net/post/$postId/embed/'));
      targets.add(Uri.parse('https://www.threads.net/t/$postId'));
      targets.add(Uri.parse('https://www.threads.com/t/$postId'));
      if (username != null) {
        targets.add(
          Uri.parse('https://www.threads.net/@$username/post/$postId'),
        );
        targets.add(
          Uri.parse('https://www.threads.net/@$username/post/$postId/embed/'),
        );
        targets.add(
          Uri.parse('https://www.threads.com/@$username/post/$postId'),
        );
      }
    }

    return targets.toList();
  }

  static List<String> _segments(Uri uri) =>
      uri.pathSegments.where((s) => s.isNotEmpty).toList();

  static bool _isUsername(String value) {
    final cleaned = value.startsWith('@') ? value.substring(1) : value;
    if (cleaned.isEmpty) return false;
    return _usernamePattern.hasMatch(cleaned);
  }

  static bool _isPostId(String value) => _postIdPattern.hasMatch(value);
}

/// Threads URL content type classification.
enum ThreadsContentType {
  home,
  profile,
  post,
  embed,
  share,
  authentication,
  nonContent,
}

/// Parses and normalizes public WhatsApp URLs (`wa.me`, `whatsapp.com`).
///
/// Click-to-chat, group invites, WhatsApp Web, and private media CDNs are
/// classified and are **never** treated as downloadable chat content. Public
/// Channel pages may expose Open Graph metadata. Private chats, encrypted
/// media gateways, and disappearing messages are never fetched or bypassed.
class WhatsAppUri {
  const WhatsAppUri._();

  static const _trackingParams = {
    'utm_source',
    'utm_medium',
    'utm_campaign',
    'utm_term',
    'utm_content',
    'fbclid',
    'gclid',
    'mc_cid',
    'mc_eid',
    'si',
    'src',
  };

  static const _homeFirstSegments = {
    'download',
    'android',
    'ios',
    'app',
    'desktop',
    'features',
    'security',
    'privacy',
    'legal',
    'terms',
    'contact',
    'communities',
    'business',
    'meta',
    'dl',
    'qr',
  };

  static final _phoneDigitsPattern = RegExp(r'^\d{7,15}$');
  static final _channelIdPattern = RegExp(r'^[A-Za-z0-9_-]{10,40}$');
  static final _inviteCodePattern = RegExp(r'^[A-Za-z0-9_-]{10,40}$');

  static bool isWhatsAppHost(String host) =>
      SocialPlatform.isWhatsAppHost(host);

  static bool isWhatsAppScheme(Uri uri) =>
      SocialPlatform.isWhatsAppScheme(uri);

  /// Public CDN hosts that Channel pages may expose in Open Graph tags.
  /// Encrypted private media (`mmg`, `pps`) is never included.
  static bool isPublicMediaHost(String host) {
    final h = host.toLowerCase();
    if (h == 'fbcdn.net' || h.endsWith('.fbcdn.net')) return true;
    if (h == 'lookaside.fbsbx.com' || h.endsWith('.lookaside.fbsbx.com')) {
      return true;
    }
    if (h == 'static.whatsapp.net' || h.endsWith('.static.whatsapp.net')) {
      return true;
    }
    return false;
  }

  /// Encrypted WhatsApp media gateway — requires a WhatsApp session.
  static bool isPrivateMediaHost(String host) {
    final h = host.toLowerCase();
    if (h == 'mmg.whatsapp.net' || h.endsWith('.mmg.whatsapp.net')) return true;
    if (h == 'pps.whatsapp.net' || h.endsWith('.pps.whatsapp.net')) return true;
    if (h == 'media.whatsapp.net' || h.endsWith('.media.whatsapp.net')) {
      return true;
    }
    return false;
  }

  static bool isWaMeHost(String host) {
    final h = host.toLowerCase();
    return h == 'wa.me' || h.endsWith('.wa.me');
  }

  static bool isChatHost(String host) {
    final h = host.toLowerCase();
    return h == 'chat.whatsapp.com' || h.endsWith('.chat.whatsapp.com');
  }

  static bool isWebHost(String host) {
    final h = host.toLowerCase();
    return h == 'web.whatsapp.com' || h.endsWith('.web.whatsapp.com');
  }

  static bool isApiHost(String host) {
    final h = host.toLowerCase();
    return h == 'api.whatsapp.com' || h.endsWith('.api.whatsapp.com');
  }

  static bool isCallHost(String host) {
    final h = host.toLowerCase();
    return h == 'call.whatsapp.com' || h.endsWith('.call.whatsapp.com');
  }

  static WhatsAppContentType classifyUrl(Uri uri) {
    if (isWhatsAppScheme(uri)) {
      return _classifyDeepLink(uri);
    }

    final host = uri.host.toLowerCase();
    if (isPrivateMediaHost(host)) return WhatsAppContentType.privateMedia;
    if (isPublicMediaHost(host)) return WhatsAppContentType.directMedia;
    if (isWebHost(host)) return WhatsAppContentType.whatsappWeb;
    if (isCallHost(host)) return WhatsAppContentType.callLink;
    if (isChatHost(host)) {
      final code = inviteCodeFromUri(uri);
      return code == null
          ? WhatsAppContentType.invalid
          : WhatsAppContentType.groupInvite;
    }
    if (isApiHost(host)) {
      return phoneFromUri(uri) == null
          ? WhatsAppContentType.invalid
          : WhatsAppContentType.chatLink;
    }
    if (isWaMeHost(host)) {
      return _classifyWaMe(uri);
    }
    if (!isWhatsAppHost(host)) return WhatsAppContentType.nonContent;

    return _classifyWhatsAppDotCom(uri);
  }

  static WhatsAppContentType _classifyWaMe(Uri uri) {
    final segments = _segments(uri);
    if (segments.isEmpty) return WhatsAppContentType.home;
    final first = segments.first;
    if (first.toLowerCase() == 'message') {
      return segments.length >= 2
          ? WhatsAppContentType.businessChat
          : WhatsAppContentType.invalid;
    }
    if (_isPhonePath(first) && segments.length == 1) {
      return WhatsAppContentType.chatLink;
    }
    return WhatsAppContentType.invalid;
  }

  static WhatsAppContentType _classifyWhatsAppDotCom(Uri uri) {
    final segments = _segments(uri);
    if (segments.isEmpty) return WhatsAppContentType.home;

    final first = segments.first.toLowerCase();
    if (first == 'channel') {
      if (segments.length < 2 || !_channelIdPattern.hasMatch(segments[1])) {
        return WhatsAppContentType.invalid;
      }
      if (segments.length >= 3) return WhatsAppContentType.publicChannelPost;
      return WhatsAppContentType.publicChannel;
    }
    if (first == 'send') {
      return phoneFromUri(uri) == null
          ? WhatsAppContentType.invalid
          : WhatsAppContentType.chatLink;
    }
    if (first == 'status') return WhatsAppContentType.status;
    if (first == 'login' || first == 'auth') {
      return WhatsAppContentType.authentication;
    }
    if (_homeFirstSegments.contains(first)) return WhatsAppContentType.home;
    return WhatsAppContentType.invalid;
  }

  static WhatsAppContentType _classifyDeepLink(Uri uri) {
    final action = uri.host.toLowerCase();
    final params = uri.queryParameters;
    if (action == 'send') {
      final phone = _digitsOnly(params['phone'] ?? params['phone_number']);
      if (phone != null) return WhatsAppContentType.chatLink;
      return WhatsAppContentType.deepLink;
    }
    if (action == 'chat' || action == 'invite') {
      return WhatsAppContentType.groupInvite;
    }
    if (action == 'channel') return WhatsAppContentType.publicChannel;
    if (action == 'status') return WhatsAppContentType.status;
    if (action == 'call') return WhatsAppContentType.callLink;
    if (action.isEmpty) return WhatsAppContentType.deepLink;
    return WhatsAppContentType.deepLink;
  }

  static String? phoneFromUri(Uri uri) {
    if (isWhatsAppScheme(uri)) {
      return _digitsOnly(
        uri.queryParameters['phone'] ?? uri.queryParameters['phone_number'],
      );
    }
    if (isApiHost(uri.host) ||
        (_segments(uri).isNotEmpty &&
            _segments(uri).first.toLowerCase() == 'send')) {
      return _digitsOnly(
        uri.queryParameters['phone'] ?? uri.queryParameters['phone_number'],
      );
    }
    if (isWaMeHost(uri.host)) {
      final segments = _segments(uri);
      if (segments.length == 1) return _digitsOnly(segments.first);
    }
    return null;
  }

  static String? prefilledTextFromUri(Uri uri) {
    final text = uri.queryParameters['text'];
    if (text == null || text.isEmpty) return null;
    return text;
  }

  static String? inviteCodeFromUri(Uri uri) {
    if (isWhatsAppScheme(uri) &&
        (uri.host.toLowerCase() == 'chat' ||
            uri.host.toLowerCase() == 'invite')) {
      final code =
          uri.queryParameters['code'] ?? uri.queryParameters['invite'];
      if (code != null && _inviteCodePattern.hasMatch(code)) return code;
      return null;
    }
    if (!isChatHost(uri.host)) return null;
    final segments = _segments(uri);
    if (segments.length == 1 && _inviteCodePattern.hasMatch(segments.first)) {
      return segments.first;
    }
    return null;
  }

  static String? channelIdFromUri(Uri uri) {
    if (isWhatsAppScheme(uri) && uri.host.toLowerCase() == 'channel') {
      final id = uri.queryParameters['id'] ??
          (uri.pathSegments.isEmpty ? null : uri.pathSegments.first);
      if (id != null && _channelIdPattern.hasMatch(id)) return id;
      return null;
    }
    final segments = _segments(uri);
    if (segments.length >= 2 && segments.first.toLowerCase() == 'channel') {
      return _channelIdPattern.hasMatch(segments[1]) ? segments[1] : null;
    }
    return null;
  }

  static String? channelPostIdFromUri(Uri uri) {
    final segments = _segments(uri);
    if (segments.length >= 3 && segments.first.toLowerCase() == 'channel') {
      final post = segments[2];
      return post.isEmpty ? null : post;
    }
    return null;
  }

  static String? businessCodeFromUri(Uri uri) {
    final segments = _segments(uri);
    if (segments.length >= 2 && segments.first.toLowerCase() == 'message') {
      return segments[1].isEmpty ? null : segments[1];
    }
    return null;
  }

  /// Public Channel pages and posts may expose Open Graph media. Chat links,
  /// invites, Web, and encrypted CDNs cannot.
  static bool isDownloadable(Uri uri) {
    return switch (classifyUrl(uri)) {
      WhatsAppContentType.publicChannel ||
      WhatsAppContentType.publicChannelPost ||
      WhatsAppContentType.directMedia => true,
      _ => false,
    };
  }

  static bool isRestricted(Uri uri) {
    return switch (classifyUrl(uri)) {
      WhatsAppContentType.groupInvite ||
      WhatsAppContentType.status ||
      WhatsAppContentType.privateMedia => true,
      _ => false,
    };
  }

  static bool requiresAuthentication(Uri uri) {
    return switch (classifyUrl(uri)) {
      WhatsAppContentType.whatsappWeb ||
      WhatsAppContentType.authentication ||
      WhatsAppContentType.privateMedia => true,
      _ => false,
    };
  }

  static String? contentIdentity(Uri uri) {
    final type = classifyUrl(uri);
    switch (type) {
      case WhatsAppContentType.directMedia:
        return 'whatsapp:media:${uri.host.toLowerCase()}${uri.path}';
      case WhatsAppContentType.privateMedia:
        return 'whatsapp:private-media';
      case WhatsAppContentType.groupInvite:
        final code = inviteCodeFromUri(uri);
        return code == null ? 'whatsapp:invite' : 'whatsapp:invite:$code';
      case WhatsAppContentType.home:
        return 'whatsapp:home';
      case WhatsAppContentType.whatsappWeb:
        return 'whatsapp:web';
      case WhatsAppContentType.authentication:
        return 'whatsapp:auth';
      case WhatsAppContentType.status:
        return 'whatsapp:status';
      case WhatsAppContentType.callLink:
        return 'whatsapp:call';
      case WhatsAppContentType.invalid:
        return 'whatsapp:invalid';
      case WhatsAppContentType.chatLink:
        final phone = phoneFromUri(uri);
        return phone == null ? 'whatsapp:chat' : 'whatsapp:chat:$phone';
      case WhatsAppContentType.businessChat:
        final code = businessCodeFromUri(uri);
        return code == null ? 'whatsapp:business' : 'whatsapp:business:$code';
      case WhatsAppContentType.publicChannel:
      case WhatsAppContentType.publicChannelPost:
        final channel = channelIdFromUri(uri);
        final post = channelPostIdFromUri(uri);
        if (channel != null && post != null) {
          return 'whatsapp:channel:$channel:$post';
        }
        if (channel != null) return 'whatsapp:channel:$channel';
        return 'whatsapp:channel';
      case WhatsAppContentType.deepLink:
        return 'whatsapp:deeplink';
      case WhatsAppContentType.nonContent:
        return null;
    }
  }

  /// HTTPS canonical form. Tracking is stripped. `text` and `phone` are kept
  /// on click-to-chat links. Public `whatsapp://send` becomes `https://wa.me`.
  static Uri normalize(Uri uri) {
    if (isWhatsAppScheme(uri)) {
      return tryNormalizeDeepLink(uri) ?? uri;
    }
    if (isPublicMediaHost(uri.host) || isPrivateMediaHost(uri.host)) {
      return uri.replace(scheme: 'https', fragment: '');
    }

    final type = classifyUrl(uri);
    final phone = phoneFromUri(uri);
    final text = prefilledTextFromUri(uri);

    if (type == WhatsAppContentType.chatLink && phone != null) {
      return Uri(
        scheme: 'https',
        host: 'wa.me',
        path: '/$phone',
        queryParameters: text == null ? null : {'text': text},
      );
    }

    if (type == WhatsAppContentType.businessChat) {
      final code = businessCodeFromUri(uri);
      if (code != null) {
        return Uri.parse('https://wa.me/message/$code');
      }
    }

    if (type == WhatsAppContentType.groupInvite) {
      final code = inviteCodeFromUri(uri);
      if (code != null) {
        return Uri.parse('https://chat.whatsapp.com/$code');
      }
    }

    if (type == WhatsAppContentType.publicChannel ||
        type == WhatsAppContentType.publicChannelPost) {
      final channel = channelIdFromUri(uri);
      final post = channelPostIdFromUri(uri);
      if (channel != null && post != null) {
        return Uri.parse('https://www.whatsapp.com/channel/$channel/$post');
      }
      if (channel != null) {
        return Uri.parse('https://www.whatsapp.com/channel/$channel');
      }
    }

    if (type == WhatsAppContentType.home) {
      if (isWaMeHost(uri.host)) return Uri.parse('https://wa.me/');
      return Uri.parse('https://www.whatsapp.com/');
    }

    if (type == WhatsAppContentType.whatsappWeb) {
      return Uri.parse('https://web.whatsapp.com/');
    }

    final cleanedParams = Map<String, String>.from(uri.queryParameters)
      ..removeWhere(
        (key, _) =>
            _trackingParams.contains(key.toLowerCase()) ||
            key.toLowerCase().startsWith('utm_'),
      );

    var path = uri.path.isEmpty ? '/' : uri.path;
    if (!path.startsWith('/')) path = '/$path';
    return Uri(
      scheme: 'https',
      host: _canonicalHost(uri.host, type),
      path: path,
      queryParameters: cleanedParams.isEmpty ? null : cleanedParams,
    );
  }

  static String _canonicalHost(String host, WhatsAppContentType type) {
    if (isWaMeHost(host)) return 'wa.me';
    if (isChatHost(host)) return 'chat.whatsapp.com';
    if (isWebHost(host)) return 'web.whatsapp.com';
    if (isApiHost(host)) return 'api.whatsapp.com';
    if (type == WhatsAppContentType.publicChannel ||
        type == WhatsAppContentType.publicChannelPost) {
      return 'www.whatsapp.com';
    }
    return 'www.whatsapp.com';
  }

  /// Converts a public `whatsapp://send` deep link to `https://wa.me/...`.
  /// Returns null for invites, status, and malformed deep links.
  static Uri? tryNormalizeDeepLink(Uri uri) {
    if (!isWhatsAppScheme(uri)) return null;
    final type = classifyUrl(uri);
    if (type == WhatsAppContentType.groupInvite ||
        type == WhatsAppContentType.status ||
        type == WhatsAppContentType.privateMedia) {
      return null;
    }
    if (type == WhatsAppContentType.chatLink) {
      final phone = phoneFromUri(uri);
      if (phone == null) return null;
      final text = prefilledTextFromUri(uri);
      return Uri(
        scheme: 'https',
        host: 'wa.me',
        path: '/$phone',
        queryParameters: text == null ? null : {'text': text},
      );
    }
    if (type == WhatsAppContentType.publicChannel) {
      final id = channelIdFromUri(uri);
      if (id == null) return null;
      return Uri.parse('https://www.whatsapp.com/channel/$id');
    }
    return null;
  }

  static String deepLinkRejectionMessage(Uri uri) {
    return switch (classifyUrl(uri)) {
      WhatsAppContentType.groupInvite =>
        'This is a WhatsApp group invitation. Open it in WhatsApp to join. '
            'The app cannot join groups or extract private content.',
      WhatsAppContentType.status =>
        'This WhatsApp status cannot be accessed automatically.',
      WhatsAppContentType.whatsappWeb ||
      WhatsAppContentType.authentication ||
      WhatsAppContentType.privateMedia =>
        'WhatsApp authentication is required.',
      WhatsAppContentType.chatLink =>
        'WhatsApp link detected. Open it in WhatsApp. '
            'This is not a downloadable media resource.',
      _ => 'This WhatsApp link is not a downloadable public item.',
    };
  }

  static List<Uri> fetchTargets(Uri uri) {
    final normalized = normalize(uri);
    final targets = <Uri>{uri, normalized};
    final channel = channelIdFromUri(uri) ?? channelIdFromUri(normalized);
    final post = channelPostIdFromUri(uri) ?? channelPostIdFromUri(normalized);
    if (channel != null && post != null) {
      targets.add(
        Uri.parse('https://www.whatsapp.com/channel/$channel/$post'),
      );
    } else if (channel != null) {
      targets.add(Uri.parse('https://www.whatsapp.com/channel/$channel'));
      targets.add(Uri.parse('https://whatsapp.com/channel/$channel'));
    }
    return targets.toList();
  }

  static List<String> _segments(Uri uri) =>
      uri.pathSegments.where((s) => s.isNotEmpty).toList();

  static bool _isPhonePath(String value) {
    return _digitsOnly(value) != null;
  }

  static String? _digitsOnly(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (!_phoneDigitsPattern.hasMatch(digits)) return null;
    return digits;
  }
}

/// WhatsApp URL content type classification.
enum WhatsAppContentType {
  home,
  chatLink,
  businessChat,
  groupInvite,
  publicChannel,
  publicChannelPost,
  whatsappWeb,
  status,
  callLink,
  invalid,
  directMedia,
  privateMedia,
  authentication,
  deepLink,
  nonContent,
}
