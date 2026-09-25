import 'dailymotion_uri.dart';

/// Supported social / content platforms — docs/11.5 Content Provider Architecture.
enum SocialPlatform {
  youtube('YouTube'),
  tiktok('TikTok'),
  instagram('Instagram'),
  twitter('X (Twitter)'),
  facebook('Facebook'),
  reddit('Reddit'),
  pinterest('Pinterest'),
  linkedin('LinkedIn'),
  threads('Threads'),
  soundcloud('SoundCloud'),
  vimeo('Vimeo'),
  twitch('Twitch'),
  telegram('Telegram'),
  snapchat('Snapchat'),
  whatsapp('WhatsApp'),
  dailymotion('Dailymotion');

  const SocialPlatform(this.label);

  final String label;

  static SocialPlatform? fromLabel(String? label) {
    if (label == null || label.isEmpty) return null;
    for (final platform in SocialPlatform.values) {
      if (platform.label == label) return platform;
    }
    return null;
  }

  static SocialPlatform? fromUri(Uri uri) {
    if (isTelegramScheme(uri) || isTelegramHost(uri.host)) {
      return SocialPlatform.telegram;
    }
    if (isSnapchatScheme(uri) || isSnapchatHost(uri.host)) {
      return SocialPlatform.snapchat;
    }
    if (isWhatsAppScheme(uri) || isWhatsAppHost(uri.host)) {
      return SocialPlatform.whatsapp;
    }
    if (DailymotionUri.isHost(uri.host)) {
      return SocialPlatform.dailymotion;
    }
    final host = uri.host.toLowerCase();
    if (host == 'youtu.be' ||
        host.endsWith('.youtu.be') ||
        host == 'youtube.com' ||
        host.endsWith('.youtube.com')) {
      return SocialPlatform.youtube;
    }
    if (_isTikTokPageHost(host)) {
      return SocialPlatform.tiktok;
    }
    if (host == 'instagram.com' || host.endsWith('.instagram.com')) {
      return SocialPlatform.instagram;
    }
    if (host == 'twitter.com' ||
        host == 'x.com' ||
        host.endsWith('.twitter.com')) {
      return SocialPlatform.twitter;
    }
    if (host == 'facebook.com' ||
        host == 'fb.watch' ||
        host.endsWith('.facebook.com')) {
      return SocialPlatform.facebook;
    }
    if (host == 'reddit.com' ||
        host == 'old.reddit.com' ||
        host == 'redd.it' ||
        host.endsWith('.reddit.com') ||
        host.endsWith('.redd.it')) {
      return SocialPlatform.reddit;
    }
    if (isPinterestHost(host)) {
      return SocialPlatform.pinterest;
    }
    if (isLinkedInHost(host)) {
      return SocialPlatform.linkedin;
    }
    if (isThreadsHost(host)) {
      return SocialPlatform.threads;
    }
    if (host == 'soundcloud.com' ||
        host.endsWith('.soundcloud.com') ||
        host == 'snd.sc' ||
        host == 'on.soundcloud.com' ||
        host.endsWith('.on.soundcloud.com')) {
      return SocialPlatform.soundcloud;
    }
    if (isVimeoHost(host)) {
      return SocialPlatform.vimeo;
    }
    if (isTwitchHost(host)) {
      return SocialPlatform.twitch;
    }
    return null;
  }

  /// True for Pinterest sites, short links (`pin.it`), and media CDN hosts.
  static bool isPinterestHost(String host) {
    final h = host.toLowerCase();
    if (h == 'pin.it' || h.endsWith('.pin.it')) return true;
    if (h == 'pinimg.com' || h.endsWith('.pinimg.com')) return true;
    if (h == 'pinterest.com' || h.endsWith('.pinterest.com')) return true;
    return RegExp(
      r'^(?:[a-z0-9-]+\.)?pinterest\.(?:com\.[a-z]{2}|co\.uk|com|ca|de|fr|es|it|jp|cl|pt|ph|at|ch|dk|ie|nz|se|co|hu|pe|ec|id|sk|pl|nl|be|kr|in)$',
    ).hasMatch(h);
  }

  /// True for `vimeo.com`, `player.vimeo.com`, and regional/mobile subdomains.
  static bool isVimeoHost(String host) {
    final h = host.toLowerCase();
    return h == 'vimeo.com' || h.endsWith('.vimeo.com');
  }

  /// True for `twitch.tv`, `clips.twitch.tv`, `player.twitch.tv`, and mobile hosts.
  static bool isTwitchHost(String host) {
    final h = host.toLowerCase();
    return h == 'twitch.tv' || h.endsWith('.twitch.tv');
  }

  /// True for LinkedIn sites, `lnkd.in` share links, and `licdn.com` media CDNs.
  static bool isLinkedInHost(String host) {
    final h = host.toLowerCase();
    if (h == 'linkedin.com' || h.endsWith('.linkedin.com')) return true;
    if (h == 'lnkd.in' || h.endsWith('.lnkd.in')) return true;
    if (h == 'licdn.com' || h.endsWith('.licdn.com')) return true;
    return false;
  }

  /// True for `threads.net`, `threads.com`, and documented share/mobile hosts.
  static bool isThreadsHost(String host) {
    final h = host.toLowerCase();
    if (h == 'threads.net' || h.endsWith('.threads.net')) return true;
    if (h == 'threads.com' || h.endsWith('.threads.com')) return true;
    return false;
  }

  /// True for `tg://` and `telegram://` deep links.
  static bool isTelegramScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'tg' || scheme == 'telegram';
  }

  /// True for `snapchat://` and `snap://` deep links.
  static bool isSnapchatScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'snapchat' || scheme == 'snap';
  }

  /// True for Snapchat web, share, story, and public media CDN hosts.
  static bool isSnapchatHost(String host) {
    final h = host.toLowerCase();
    if (h == 'snapchat.com' || h.endsWith('.snapchat.com')) return true;
    if (h == 'sc-cdn.net' || h.endsWith('.sc-cdn.net')) return true;
    return false;
  }

  /// True for `whatsapp://` click-to-chat and invite deep links.
  static bool isWhatsAppScheme(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    return scheme == 'whatsapp';
  }

  /// True for `wa.me`, `whatsapp.com`, `chat.whatsapp.com`, WhatsApp Web, and
  /// documented public/static hosts. Private media CDNs (`mmg.whatsapp.net`)
  /// are still WhatsApp hosts so they can be classified as authentication-
  /// required — they are never treated as downloadable files.
  static bool isWhatsAppHost(String host) {
    final h = host.toLowerCase();
    if (h == 'wa.me' || h.endsWith('.wa.me')) return true;
    if (h == 'whatsapp.com' || h.endsWith('.whatsapp.com')) return true;
    if (h == 'whatsapp.net' || h.endsWith('.whatsapp.net')) return true;
    return false;
  }

  /// True only for TikTok page/share hosts, excluding CDN subdomains like
  /// `v16-webapp-prime.tiktok.com` that should be downloaded directly.
  static bool _isTikTokPageHost(String host) {
    const pageHosts = {
      'tiktok.com',
      'www.tiktok.com',
      'm.tiktok.com',
      'vm.tiktok.com',
      'vt.tiktok.com',
      't.tiktok.com',
    };
    return pageHosts.contains(host);
  }

  /// True for `t.me`, `telegram.me`, `telegram.org`, and Telegram CDN hosts.
  static bool isTelegramHost(String host) {
    final h = host.toLowerCase();
    if (h == 't.me' || h.endsWith('.t.me')) return true;
    if (h == 'telegram.me' || h.endsWith('.telegram.me')) return true;
    if (h == 'telegram.dog' || h.endsWith('.telegram.dog')) return true;
    if (h == 'telegram.org' || h.endsWith('.telegram.org')) return true;
    if (h == 'telesco.pe' || h.endsWith('.telesco.pe')) return true;
    if (h == 'telegram-cdn.org' || h.endsWith('.telegram-cdn.org')) return true;
    if (h == 'cdn.telegram.org' || h.endsWith('.cdn.telegram.org')) return true;
    return false;
  }
}
