import 'package:flutter/foundation.dart';

import '../web_request_proxy.dart';
import 'social_platform.dart';

/// Browser-like headers required by social CDNs and page fetches.
class SocialHttpHeaders {
  const SocialHttpHeaders._();

  static const userAgent =
      'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Mobile Safari/537.36';

  static const youtubeAndroidUserAgent =
      'com.google.android.youtube/20.10.38 (Linux; U; Android 14) gzip';

  /// Threads serves a media-less JS shell to Android Chrome, but public Open
  /// Graph + post JSON to mobile Safari. This is a normal browser UA, not a
  /// crawler impersonation.
  static const threadsMobileUserAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
      'AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 '
      'Mobile/15E148 Safari/604.1';

  /// SoundCloud's Android Chrome page is a media-less mobile shell without
  /// `__sc_hydration`. Desktop Chrome still embeds track/playlist JSON.
  static const soundcloudDesktopUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';

  static const _userAgent = userAgent;

  static Map<String, String> forPageFetch(
    Uri pageUrl,
    SocialPlatform platform,
  ) {
    final origin = _originFor(platform, pageUrl);
    final headers = {
      'User-Agent': platform == SocialPlatform.soundcloud
          ? soundcloudDesktopUserAgent
          : platform == SocialPlatform.threads
          ? threadsMobileUserAgent
          : _userAgent,
      'Accept':
          'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': origin,
      'Origin': origin,
      'Cache-Control': 'no-cache',
      'Pragma': 'no-cache',
      'sec-fetch-dest': 'document',
      'sec-fetch-mode': 'navigate',
      'sec-fetch-site': 'none',
      'sec-fetch-user': '?1',
      'upgrade-insecure-requests': '1',
    };
    return _forBrowser(headers);
  }

  /// Direct file URLs (PDFs, zips, generic CDNs). Omits a Chrome User-Agent:
  /// Cloudflare Bot Fight Mode challenges clients that claim to be Chrome
  /// without a matching browser TLS fingerprint (`Just a moment...` / 403).
  static Map<String, String> forDirectFile() => const {
    'Accept': '*/*',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  static Map<String, String> forMediaDownload({
    required Uri pageUrl,
    required String mediaUrl,
    SocialPlatform? platform,
  }) {
    final resolved = platform ?? SocialPlatform.fromUri(pageUrl);
    final isYouTube =
        resolved == SocialPlatform.youtube ||
        mediaUrl.contains('googlevideo.com');
    if (resolved == null && !isYouTube) {
      return _forBrowser(forDirectFile());
    }
    final social = resolved ?? SocialPlatform.youtube;
    final referer = _pageReferer(pageUrl);
    final headers = {
      'User-Agent': isYouTube
          ? youtubeAndroidUserAgent
          : social == SocialPlatform.soundcloud
          ? soundcloudDesktopUserAgent
          : social == SocialPlatform.threads
          ? threadsMobileUserAgent
          : _userAgent,
      'Accept': '*/*',
      'Accept-Language': 'en-US,en;q=0.9',
      'Referer': isYouTube ? 'https://www.youtube.com/' : referer,
      'Origin': _originFor(social, pageUrl),
    };
    return _forBrowser(headers);
  }

  /// Drops headers that force a CORS preflight (`User-Agent` is not safelisted).
  /// Kept when the web CORS proxy is enabled — the proxy, not the browser,
  /// sends User-Agent / Referer to the origin.
  static Map<String, String> withoutCorsUnsafeHeaders(
    Map<String, String> headers,
  ) {
    const unsafe = {
      'user-agent',
      'origin',
      'referer',
      'cache-control',
      'pragma',
    };
    return Map.fromEntries(
      headers.entries.where((e) => !unsafe.contains(e.key.toLowerCase())),
    );
  }

  static Map<String, String> _forBrowser(Map<String, String> headers) {
    if (kIsWeb && !WebRequestProxy.isEnabled) {
      return withoutCorsUnsafeHeaders(headers);
    }
    return headers;
  }

  static String _pageReferer(Uri pageUrl) {
    if (pageUrl.scheme != 'http' && pageUrl.scheme != 'https') {
      return pageUrl.toString();
    }
    final path = pageUrl.path.isEmpty ? '/' : pageUrl.path;
    return '${pageUrl.scheme}://${pageUrl.host}$path';
  }

  static String _originFor(SocialPlatform platform, [Uri? pageUrl]) =>
      switch (platform) {
        SocialPlatform.youtube => 'https://www.youtube.com',
        SocialPlatform.tiktok => 'https://www.tiktok.com',
        SocialPlatform.instagram => 'https://www.instagram.com',
        SocialPlatform.twitter => 'https://x.com',
        SocialPlatform.facebook => 'https://www.facebook.com',
        SocialPlatform.reddit => 'https://www.reddit.com',
        SocialPlatform.pinterest => 'https://www.pinterest.com',
        SocialPlatform.linkedin => 'https://www.linkedin.com',
        SocialPlatform.threads =>
          (pageUrl?.host.toLowerCase().contains('threads.com') ?? false)
              ? 'https://www.threads.com'
              : 'https://www.threads.net',
        SocialPlatform.soundcloud => 'https://soundcloud.com',
        SocialPlatform.vimeo => 'https://vimeo.com',
        SocialPlatform.twitch => 'https://www.twitch.tv',
        SocialPlatform.telegram => 'https://t.me',
        SocialPlatform.snapchat => 'https://www.snapchat.com',
        SocialPlatform.whatsapp => 'https://www.whatsapp.com',
        SocialPlatform.dailymotion => 'https://www.dailymotion.com',
      };
}
