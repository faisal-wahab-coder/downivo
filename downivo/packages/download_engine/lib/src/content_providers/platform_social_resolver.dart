import 'package:dio/dio.dart';

import 'dailymotion_resolver.dart';
import 'facebook_resolver.dart';
import 'instagram_graphql_resolver.dart';
import 'linkedin_resolver.dart';
import 'models/discovered_resource.dart';
import 'pinterest_resolver.dart';
import 'reddit_resolver.dart';
import 'social_platform.dart';
import 'soundcloud_resolver.dart';
import 'snapchat_resolver.dart';
import 'telegram_resolver.dart';
import 'threads_resolver.dart';
import 'tiktok_resolver.dart';
import 'whatsapp_resolver.dart';
import 'twitch_resolver.dart';
import 'twitter_resolver.dart';
import 'vimeo_resolver.dart';
import 'youtube_resolver.dart';

/// Platform-specific discovery before generic HTML extraction.
class PlatformSocialResolver {
  PlatformSocialResolver({Dio? dio})
      : _instagram = InstagramGraphqlResolver(dio: dio),
        _tiktok = TikTokResolver(dio: dio),
        _youtube = YouTubeResolver(dio: dio),
        _twitter = TwitterResolver(dio: dio),
        _facebook = FacebookResolver(dio: dio),
        _soundcloud = SoundCloudResolver(dio: dio),
        _pinterest = PinterestResolver(dio: dio),
        _vimeo = VimeoResolver(dio: dio),
        _twitch = TwitchResolver(dio: dio),
        _linkedin = LinkedInResolver(dio: dio),
        _telegram = TelegramResolver(dio: dio),
        _snapchat = SnapchatResolver(dio: dio),
        _threads = ThreadsResolver(dio: dio),
        _whatsapp = WhatsAppResolver(dio: dio),
        _dailymotion = DailymotionResolver(dio: dio) {
    _reddit = RedditResolver(
      dio: dio,
      resolveLinkedPage: (uri) async {
        final linkedPlatform = SocialPlatform.fromUri(uri);
        if (linkedPlatform == null ||
            linkedPlatform == SocialPlatform.reddit) {
          return const [];
        }
        final found = await discover(uri, linkedPlatform);
        return found == null ? const [] : [found];
      },
    );
  }

  final InstagramGraphqlResolver _instagram;
  final TikTokResolver _tiktok;
  final YouTubeResolver _youtube;
  final TwitterResolver _twitter;
  late final RedditResolver _reddit;
  final FacebookResolver _facebook;
  final SoundCloudResolver _soundcloud;
  final PinterestResolver _pinterest;
  final VimeoResolver _vimeo;
  final TwitchResolver _twitch;
  final LinkedInResolver _linkedin;
  final TelegramResolver _telegram;
  final SnapchatResolver _snapchat;
  final ThreadsResolver _threads;
  final WhatsAppResolver _whatsapp;
  final DailymotionResolver _dailymotion;

  Future<DiscoveredResource?> discover(
    Uri pageUrl,
    SocialPlatform platform,
  ) {
    return switch (platform) {
      SocialPlatform.instagram => _instagram.discover(pageUrl),
      SocialPlatform.tiktok => _tiktok.discover(pageUrl),
      SocialPlatform.youtube => _youtube.discover(pageUrl),
      SocialPlatform.twitter => _twitter.discover(pageUrl),
      SocialPlatform.reddit => _reddit.discover(pageUrl),
      SocialPlatform.facebook => _facebook.discover(pageUrl),
      SocialPlatform.soundcloud => _soundcloud.discover(pageUrl),
      SocialPlatform.pinterest => _pinterest.discover(pageUrl),
      SocialPlatform.vimeo => _vimeo.discover(pageUrl),
      SocialPlatform.twitch => _twitch.discover(pageUrl),
      SocialPlatform.linkedin => _linkedin.discover(pageUrl),
      SocialPlatform.telegram => _telegram.discover(pageUrl),
      SocialPlatform.snapchat => _snapchat.discover(pageUrl),
      SocialPlatform.threads => _threads.discover(pageUrl),
      SocialPlatform.whatsapp => _whatsapp.discover(pageUrl),
      SocialPlatform.dailymotion => _dailymotion.discover(pageUrl),
    };
  }

  /// Returns all discoverable resources for platforms that support multi-item
  /// content (e.g. Instagram carousels, TikTok photo posts, Facebook multi-photo,
  /// SoundCloud playlists/sets).
  /// Falls back to single-item list.
  Future<List<DiscoveredResource>> discoverAll(
    Uri pageUrl,
    SocialPlatform platform,
  ) async {
    if (platform == SocialPlatform.instagram) {
      return _instagram.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.tiktok) {
      return _tiktok.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.facebook) {
      return _facebook.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.soundcloud) {
      return _soundcloud.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.reddit) {
      return _reddit.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.pinterest) {
      return _pinterest.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.vimeo) {
      return _vimeo.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.twitch) {
      return _twitch.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.linkedin) {
      return _linkedin.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.telegram) {
      return _telegram.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.snapchat) {
      return _snapchat.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.threads) {
      return _threads.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.whatsapp) {
      return _whatsapp.discoverAll(pageUrl);
    }
    if (platform == SocialPlatform.dailymotion) {
      return _dailymotion.discoverAll(pageUrl);
    }
    final single = await discover(pageUrl, platform);
    return single != null ? [single] : const [];
  }
}
