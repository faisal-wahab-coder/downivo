import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_session_utils.dart';
import 'social_url_utils.dart';

/// Resolves publicly accessible Telegram URLs to direct media CDN links.
///
/// Supports:
/// - Public channel posts (`t.me/{channel}/{id}` and `t.me/s/{channel}/{id}`)
/// - Public photos, videos, GIFs/animations, audio, voice, documents
/// - Public albums / media groups (order preserved)
/// - Share URLs and public `tg://resolve` deep links (normalized to `t.me`)
/// - Direct Telegram CDN URLs
///
/// Channel home URLs, text-only messages, private `/c/` messages, and invite
/// links are classified and are **not** downloaded. Authentication, private
/// channels, and invite-only groups are never bypassed.
class TelegramResolver {
  TelegramResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final type = TelegramUri.classifyUrl(pageUrl);
    if (TelegramUri.isRestricted(pageUrl)) return const [];
    if (!TelegramUri.isDownloadable(pageUrl) &&
        type != TelegramContentType.directMedia) {
      return const [];
    }

    if (type == TelegramContentType.directMedia ||
        TelegramUri.isDirectMediaHost(pageUrl.host)) {
      return [_directMediaResource(pageUrl, pageUrl)];
    }

    final resolved = TelegramUri.normalize(pageUrl);
    if (!TelegramUri.isDownloadable(resolved) &&
        TelegramUri.classifyUrl(resolved) != TelegramContentType.directMedia) {
      return const [];
    }

    final contentId =
        TelegramUri.contentIdFromUri(resolved) ??
        TelegramUri.contentIdFromUri(pageUrl);

    String? lastBadHtml;
    String? lastOkHtml;
    var sawOkHtml = false;

    for (final target in TelegramUri.fetchTargets(resolved)) {
      final html = await _fetchHtml(target);
      if (html == null || html.isEmpty) continue;
      final status = classifyHtml(html);
      if (status != TelegramHtmlStatus.ok) {
        lastBadHtml = html;
        continue;
      }
      sawOkHtml = true;
      lastOkHtml = html;

      final resources = parseHtmlResources(
        html: html,
        pageUrl: pageUrl,
        contentId: contentId,
      );
      if (resources.isNotEmpty) return resources;
    }

    if (!sawOkHtml && lastBadHtml != null) {
      throw ArgumentError(userFacingError(pageUrl, html: lastBadHtml));
    }
    if (sawOkHtml) {
      throw ArgumentError(userFacingError(pageUrl, html: lastOkHtml));
    }

    return const [];
  }

  static TelegramContentType classifyUrl(Uri uri) =>
      TelegramUri.classifyUrl(uri);

  /// Public-preview / embed HTML status. Never treats a login wall as media.
  static TelegramHtmlStatus classifyHtml(String html) {
    if (html.trim().isEmpty) return TelegramHtmlStatus.unavailable;
    final lower = html.toLowerCase();
    if (lower.contains('this channel is private') ||
        lower.contains('this group is private') ||
        lower.contains('this channel is invite-only') ||
        lower.contains('this group is invite-only')) {
      return TelegramHtmlStatus.restricted;
    }
    if (lower.contains('log in to telegram') ||
        lower.contains('please log in to telegram') ||
        lower.contains('id="login-form"')) {
      return TelegramHtmlStatus.authenticationRequired;
    }
    if (lower.contains('post not found') ||
        lower.contains('message not found') ||
        lower.contains('this post is no longer available')) {
      return TelegramHtmlStatus.unavailable;
    }
    return TelegramHtmlStatus.ok;
  }

  static TelegramAccess accessFor(Uri uri, {String? html}) {
    if (TelegramUri.requiresAuthentication(uri)) {
      return TelegramAccess.authenticationRequired;
    }
    if (TelegramUri.isRestricted(uri)) {
      return TelegramAccess.restricted;
    }
    if (html != null) {
      return switch (classifyHtml(html)) {
        TelegramHtmlStatus.restricted => TelegramAccess.restricted,
        TelegramHtmlStatus.authenticationRequired =>
          TelegramAccess.authenticationRequired,
        TelegramHtmlStatus.unavailable => TelegramAccess.unavailable,
        TelegramHtmlStatus.ok => TelegramAccess.public,
      };
    }
    return TelegramAccess.public;
  }

  /// Parses downloadable media from public Telegram embed/preview HTML.
  static List<DiscoveredResource> parseHtmlResources({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    if (html.trim().isEmpty) return const [];
    if (classifyHtml(html) != TelegramHtmlStatus.ok) return const [];

    final info = parseMessageInfo(
      html: html,
      pageUrl: pageUrl,
      contentId: contentId,
    );
    final items = parseMediaItems(html);
    if (items.isEmpty) return const [];

    final headers = _mediaHeaders(pageUrl);
    final results = <DiscoveredResource>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (!isDirectMediaUrl(item.url)) continue;
      results.add(
        _resourceForItem(
          item: item,
          pageUrl: pageUrl,
          info: info,
          headers: headers,
          index: i,
          total: items.length,
        ),
      );
    }
    return results;
  }

  /// Media items in document order. Does not invent extra renditions.
  static List<TelegramMediaItem> parseMediaItems(String html) {
    final items = <TelegramMediaItem>[];
    final seen = <String>{};

    void add(TelegramMediaItem item) {
      if (item.url.isEmpty || !isDirectMediaUrl(item.url)) return;
      if (!seen.add(item.url)) return;
      items.add(item);
    }

    for (final match in _groupedMediaPattern.allMatches(html)) {
      add(_itemFromGroupedMatch(match, html));
    }

    if (items.isEmpty) {
      for (final match in _photoWrapPattern.allMatches(html)) {
        add(_itemFromPhotoMatch(match));
      }
      for (final match in _videoPlayerPattern.allMatches(html)) {
        add(_itemFromVideoMatch(match));
      }
      for (final match in _voicePattern.allMatches(html)) {
        add(_itemFromVoiceMatch(match));
      }
      for (final match in _audioHrefPattern.allMatches(html)) {
        add(_itemFromAudioMatch(match));
      }
      for (final match in _audioSrcPattern.allMatches(html)) {
        add(_itemFromAudioSrcMatch(match, html));
      }
      for (final match in _documentHrefPattern.allMatches(html)) {
        add(_itemFromDocumentMatch(match));
      }
    }

    if (items.isEmpty) {
      final ogVideo =
          _metaContent(html, 'og:video') ??
          _metaContent(html, 'og:video:url') ??
          _metaContent(html, 'og:video:secure_url');
      if (ogVideo != null && isDirectMediaUrl(ogVideo)) {
        add(
          TelegramMediaItem(
            url: ogVideo,
            mediaType: _looksLikeGif(html)
                ? TelegramMediaType.gif
                : TelegramMediaType.video,
            mimeType: mimeFromUrl(ogVideo, hint: 'video/mp4'),
          ),
        );
      }
    }

    if (items.isEmpty) {
      final ogImage =
          _metaContent(html, 'og:image') ??
          _metaContent(html, 'og:image:url') ??
          _metaContent(html, 'og:image:secure_url');
      if (ogImage != null &&
          isDirectMediaUrl(ogImage) &&
          !_isSiteIcon(ogImage)) {
        add(
          TelegramMediaItem(
            url: ogImage,
            mediaType: TelegramMediaType.photo,
            mimeType: mimeFromUrl(ogImage, hint: 'image/jpeg'),
          ),
        );
      }
    }

    return items;
  }

  static TelegramMessageInfo parseMessageInfo({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    final dataPost = _dataPost(html);
    final channel =
        dataPost?.$1 ??
        TelegramUri.channelFromUri(pageUrl) ??
        _ownerUsername(html);
    final messageId = dataPost?.$2 ?? TelegramUri.messageIdFromUri(pageUrl);
    final title =
        _metaContent(html, 'og:title') ??
        _metaContent(html, 'twitter:title') ??
        _ownerDisplayName(html);
    final caption =
        _messageText(html) ??
        _metaContent(html, 'og:description') ??
        _metaContent(html, 'twitter:description');
    final thumbnail = _bestThumbnail(html);
    final duration = _durationFromHtml(html);
    final width =
        _intMeta(html, 'og:image:width') ?? _intMeta(html, 'og:video:width');
    final height =
        _intMeta(html, 'og:image:height') ?? _intMeta(html, 'og:video:height');
    final mediaType = detectMediaType(html);
    final id =
        contentId ??
        (channel != null && messageId != null
            ? '$channel/$messageId'
            : TelegramUri.contentIdFromUri(pageUrl));

    return TelegramMessageInfo(
      contentId: id,
      channel: channel,
      messageId: messageId,
      title: _cleanTitle(title, channel),
      caption: caption,
      author: _ownerDisplayName(html) ?? channel,
      authorUrl: channel == null ? null : 'https://t.me/$channel',
      thumbnailUrl: thumbnail,
      durationSeconds: duration,
      width: width,
      height: height,
      mediaType: mediaType,
    );
  }

  static TelegramMediaType detectMediaType(String html) {
    final items = parseMediaItems(html);
    if (items.length > 1) return TelegramMediaType.mediaGroup;
    if (items.length == 1) return items.first.mediaType;
    if (_hasMessageText(html)) return TelegramMediaType.textMessage;
    if (html.contains('tgme_widget_message_document')) {
      return TelegramMediaType.document;
    }
    return TelegramMediaType.unknown;
  }

  static String mimeFromUrl(String url, {String? hint}) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) {
      return 'application/vnd.apple.mpegurl';
    }
    if (lower.contains('.mp4') || lower.contains('.m4v')) return 'video/mp4';
    if (lower.contains('.webm')) return 'video/webm';
    if (lower.contains('.gif')) return 'image/gif';
    if (lower.contains('.png')) return 'image/png';
    if (lower.contains('.webp')) return 'image/webp';
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return 'image/jpeg';
    if (lower.contains('.pdf')) return 'application/pdf';
    if (lower.contains('.zip')) return 'application/zip';
    if (lower.contains('.apk')) {
      return 'application/vnd.android.package-archive';
    }
    if (lower.contains('.mp3')) return 'audio/mpeg';
    if (lower.contains('.m4a')) return 'audio/mp4';
    if (lower.contains('.opus')) return 'audio/opus';
    if (lower.contains('.oga') || lower.contains('.ogg')) return 'audio/ogg';
    if (lower.contains('.wav')) return 'audio/wav';
    if (lower.contains('.txt')) return 'text/plain';
    if (lower.contains('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (hint != null && hint.isNotEmpty) return hint;
    return 'application/octet-stream';
  }

  static bool isDirectMediaUrl(String url) {
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return false;
    }
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.startsWith('javascript:') || lower.startsWith('file:')) {
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host == '127.0.0.1' ||
        host.endsWith('.localhost')) {
      return false;
    }
    if (host.startsWith('192.168.') ||
        host.startsWith('10.') ||
        RegExp(r'^172\.(1[6-9]|2\d|3[0-1])\.').hasMatch(host)) {
      return false;
    }
    return TelegramUri.isDirectMediaHost(host);
  }

  static String userFacingError(Uri uri, {String? html}) {
    final access = accessFor(uri, html: html);
    if (access == TelegramAccess.restricted) {
      return 'This Telegram content is restricted.';
    }
    if (access == TelegramAccess.authenticationRequired) {
      return 'Telegram authentication is required.';
    }
    if (access == TelegramAccess.unavailable) {
      return 'This Telegram message is unavailable.';
    }

    return switch (TelegramUri.classifyUrl(uri)) {
      TelegramContentType.home =>
        'This is the Telegram home page, not a downloadable message.',
      TelegramContentType.channel =>
        'This is a Telegram channel, not a downloadable message. '
            'Open a specific public post to download its media.',
      TelegramContentType.publicChannelPreview =>
        'This is a Telegram channel preview, not a downloadable message. '
            'Open a specific public post to download its media.',
      TelegramContentType.invite =>
        'This Telegram invite is restricted. The app cannot join private '
            'groups or bypass invite links.',
      TelegramContentType.privateMessage =>
        'This Telegram content is restricted.',
      TelegramContentType.share =>
        'This Telegram share link is not a downloadable message.',
      TelegramContentType.stickers =>
        'Telegram sticker packs are not downloaded as media files.',
      TelegramContentType.instantView =>
        'Telegram Instant View pages are not downloaded as media files.',
      TelegramContentType.deepLink =>
        'This Telegram link is not a downloadable public message.',
      TelegramContentType.nonContent =>
        'This Telegram URL is not a downloadable message.',
      TelegramContentType.message ||
      TelegramContentType.publicMessagePreview ||
      TelegramContentType.directMedia =>
        html != null && detectMediaType(html) == TelegramMediaType.textMessage
            ? 'This Telegram message is text-only and has no downloadable media.'
            : 'Could not find downloadable media on this Telegram message. '
                  'It may be text-only, deleted, restricted, or Telegram did not '
                  'expose a media file.',
    };
  }

  Future<String?> _fetchHtml(Uri url) async {
    try {
      final response = await _dio.get<String>(
        url.toString(),
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(url, SocialPlatform.telegram),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static DiscoveredResource _directMediaResource(Uri mediaUri, Uri pageUrl) {
    final url = mediaUri.toString();
    final mime = mimeFromUrl(url);
    return DiscoveredResource(
      directUrl: url,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.telegram,
        mediaUrl: url,
        fallbackSlug: TelegramUri.contentIdFromUri(pageUrl) ?? 'telegram_media',
        mimeHint: mime,
      ),
      platform: SocialPlatform.telegram.label,
      pageUrl: pageUrl.toString(),
      mimeType: mime,
      thumbnailUrl: mime.startsWith('image/') ? url : null,
      requestHeaders: _mediaHeaders(pageUrl),
    );
  }

  static Map<String, String> _mediaHeaders(Uri pageUrl) {
    return SocialHttpHeaders.forMediaDownload(
      pageUrl: pageUrl,
      mediaUrl: 'https://cdn4.telesco.pe/',
      platform: SocialPlatform.telegram,
    );
  }

  static DiscoveredResource _resourceForItem({
    required TelegramMediaItem item,
    required Uri pageUrl,
    required TelegramMessageInfo info,
    required Map<String, String> headers,
    required int index,
    required int total,
  }) {
    final slug =
        info.contentId?.replaceAll('/', '_') ??
        TelegramUri.contentIdFromUri(pageUrl)?.replaceAll('/', '_') ??
        'telegram';
    final indexedSlug = total > 1 ? '${slug}_${index + 1}' : slug;
    final titleForName =
        item.fileName ??
        (total > 1 ? '${info.title ?? slug} ${index + 1}' : info.title);
    return DiscoveredResource(
      directUrl: item.url,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.telegram,
        mediaUrl: item.url,
        title: titleForName,
        fallbackSlug: indexedSlug,
        mimeHint: item.mimeType,
      ),
      platform: SocialPlatform.telegram.label,
      pageUrl: pageUrl.toString(),
      title: info.title,
      mimeType: item.mimeType,
      thumbnailUrl:
          item.thumbnailUrl ??
          info.thumbnailUrl ??
          (item.mimeType.startsWith('image/') ? item.url : null),
      requestHeaders: headers,
      author: info.author,
      durationSeconds: item.durationSeconds ?? info.durationSeconds,
      width: item.width ?? info.width,
      height: item.height ?? info.height,
      kind: DiscoveredResourceKind.fromMime(
        item.mimeType,
        carousel: total > 1,
      ),
    );
  }

  static final _groupedMediaPattern = RegExp(
    r'''<a[^>]+class=["'][^"']*grouped_media_wrap[^"']*["'][^>]*>''',
    caseSensitive: false,
  );

  static final _photoWrapPattern = RegExp(
    r'''<a[^>]+class=["'][^"']*tgme_widget_message_photo_wrap[^"']*["'][^>]*>''',
    caseSensitive: false,
  );

  static final _videoPlayerPattern = RegExp(
    r'''<a[^>]+class=["'][^"']*tgme_widget_message_video_player[^"']*["'][^>]*>[\s\S]*?</a>''',
    caseSensitive: false,
  );

  static final _voicePattern = RegExp(
    r'''data-voice=["']([^"']+)["']''',
    caseSensitive: false,
  );

  static final _audioHrefPattern = RegExp(
    r'''<a[^>]+class=["'][^"']*tgme_widget_message_audio[^"']*["'][^>]+href=["']([^"']+)["']''',
    caseSensitive: false,
  );

  static final _documentHrefPattern = RegExp(
    r'''<a[^>]+class=["'][^"']*tgme_widget_message_document_wrap[^"']*["'][^>]*>[\s\S]*?</a>''',
    caseSensitive: false,
  );

  static final _bgImagePattern = RegExp(
    r'''background-image:\s*url\(['"]?([^'")\s]+)['"]?\)''',
    caseSensitive: false,
  );

  static final _videoSrcPattern = RegExp(
    r'''<(?:video|source)[^>]+src=["']([^"']+)["']''',
    caseSensitive: false,
  );

  static final _audioSrcPattern = RegExp(
    r'''<audio[^>]+src=["']([^"']+)["']''',
    caseSensitive: false,
  );

  static TelegramMediaItem _itemFromGroupedMatch(
    RegExpMatch match,
    String html,
  ) {
    final tag = match.group(0)!;
    final start = match.start;
    final end = (start + 2500).clamp(0, html.length);
    final window = html.substring(start, end);
    final video = _videoSrcPattern.firstMatch(window)?.group(1);
    if (video != null) {
      return TelegramMediaItem(
        url: _decodeUrl(video) ?? '',
        mediaType: tag.toLowerCase().contains('gif')
            ? TelegramMediaType.gif
            : TelegramMediaType.video,
        mimeType: mimeFromUrl(video, hint: 'video/mp4'),
        thumbnailUrl: _decodeUrl(_bgImagePattern.firstMatch(window)?.group(1)),
      );
    }
    final image =
        _bgImagePattern.firstMatch(tag)?.group(1) ??
        _bgImagePattern.firstMatch(window)?.group(1);
    return TelegramMediaItem(
      url: _decodeUrl(image) ?? '',
      mediaType: TelegramMediaType.photo,
      mimeType: mimeFromUrl(image ?? '', hint: 'image/jpeg'),
    );
  }

  static TelegramMediaItem _itemFromPhotoMatch(RegExpMatch match) {
    final tag = match.group(0)!;
    final image = _bgImagePattern.firstMatch(tag)?.group(1) ?? '';
    return TelegramMediaItem(
      url: _decodeUrl(image) ?? '',
      mediaType: TelegramMediaType.photo,
      mimeType: mimeFromUrl(image, hint: 'image/jpeg'),
    );
  }

  static TelegramMediaItem _itemFromVideoMatch(RegExpMatch match) {
    final block = match.group(0)!;
    final url = _videoSrcPattern.firstMatch(block)?.group(1) ?? '';
    final isGif = block.toLowerCase().contains('gif');
    return TelegramMediaItem(
      url: _decodeUrl(url) ?? '',
      mediaType: isGif ? TelegramMediaType.gif : TelegramMediaType.video,
      mimeType: mimeFromUrl(url, hint: isGif ? 'video/mp4' : 'video/mp4'),
      thumbnailUrl: _decodeUrl(_bgImagePattern.firstMatch(block)?.group(1)),
      durationSeconds: _parseClock(
        RegExp(
          r'''class=["'][^"']*message_video_duration[^"']*["'][^>]*>([^<]+)''',
          caseSensitive: false,
        ).firstMatch(block)?.group(1),
      ),
    );
  }

  static TelegramMediaItem _itemFromVoiceMatch(RegExpMatch match) {
    final url = match.group(1) ?? '';
    return TelegramMediaItem(
      url: _decodeUrl(url) ?? '',
      mediaType: TelegramMediaType.voice,
      mimeType: mimeFromUrl(url, hint: 'audio/ogg'),
    );
  }

  static TelegramMediaItem _itemFromAudioMatch(RegExpMatch match) {
    final url = match.group(1) ?? '';
    return TelegramMediaItem(
      url: _decodeUrl(url) ?? '',
      mediaType: TelegramMediaType.audio,
      mimeType: mimeFromUrl(url, hint: 'audio/mpeg'),
    );
  }

  static TelegramMediaItem _itemFromAudioSrcMatch(
    RegExpMatch match,
    String html,
  ) {
    final url = match.group(1) ?? '';
    final start = (match.start - 400).clamp(0, html.length);
    final end = (match.end + 400).clamp(0, html.length);
    final window = html.substring(start, end).toLowerCase();
    final isVoice =
        window.contains('voice') ||
        window.contains('ogg') ||
        url.toLowerCase().contains('.oga') ||
        url.toLowerCase().contains('.ogg') ||
        url.toLowerCase().contains('.opus');
    return TelegramMediaItem(
      url: _decodeUrl(url) ?? '',
      mediaType: isVoice ? TelegramMediaType.voice : TelegramMediaType.audio,
      mimeType: mimeFromUrl(url, hint: isVoice ? 'audio/ogg' : 'audio/mpeg'),
      durationSeconds: _parseClock(
        RegExp(
          r'''class=["'][^"']*tgme_widget_message_voice_duration[^"']*["'][^>]*>([^<]+)''',
          caseSensitive: false,
        ).firstMatch(window)?.group(1),
      ),
    );
  }

  static TelegramMediaItem _itemFromDocumentMatch(RegExpMatch match) {
    final block = match.group(0)!;
    final href = RegExp(
      r'''href=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(block)?.group(1);
    final title = RegExp(
      r'''tgme_widget_message_document_title[^>]*>([^<]+)''',
      caseSensitive: false,
    ).firstMatch(block)?.group(1)?.trim();
    final extra = RegExp(
      r'''tgme_widget_message_document_extra[^>]*>([^<]+)''',
      caseSensitive: false,
    ).firstMatch(block)?.group(1)?.trim();
    final url = href == null ? '' : _decodeUrl(href) ?? '';
    final isAudio =
        block.toLowerCase().contains('audio') ||
        (title != null && _looksLikeAudioName(title));
    return TelegramMediaItem(
      url: url,
      mediaType: isAudio ? TelegramMediaType.audio : TelegramMediaType.document,
      mimeType: mimeFromUrl(
        url,
        hint: isAudio ? 'audio/mpeg' : _mimeFromFileName(title),
      ),
      fileName: title,
      extra: extra,
    );
  }

  static bool _looksLikeAudioName(String name) {
    final lower = name.toLowerCase();
    return lower.endsWith('.mp3') ||
        lower.endsWith('.m4a') ||
        lower.endsWith('.ogg') ||
        lower.endsWith('.flac') ||
        lower.endsWith('.wav');
  }

  static String? _mimeFromFileName(String? name) {
    if (name == null || name.isEmpty) return null;
    return mimeFromUrl(name);
  }

  static bool _looksLikeGif(String html) {
    return html.toLowerCase().contains('tgme_widget_message_gif') ||
        html.toLowerCase().contains('og:video:type') &&
            html.toLowerCase().contains('gif');
  }

  static bool _isSiteIcon(String url) {
    final lower = url.toLowerCase();
    return lower.contains('telegram_logo') ||
        lower.contains('/img/telegram') ||
        lower.contains('favicon');
  }

  static (String, String)? _dataPost(String html) {
    final match = RegExp(
      r'''data-post=["']([a-zA-Z][a-zA-Z0-9_]{4,31})/(\d+)["']''',
    ).firstMatch(html);
    if (match == null) return null;
    return (match.group(1)!, match.group(2)!);
  }

  static String? _ownerUsername(String html) {
    final match = RegExp(
      r'''class=["'][^"']*tgme_widget_message_owner_name[^"']*["'][^>]+href=["']https?://t\.me/([a-zA-Z][a-zA-Z0-9_]{4,31})["']''',
      caseSensitive: false,
    ).firstMatch(html);
    return match?.group(1);
  }

  static String? _ownerDisplayName(String html) {
    final match = RegExp(
      r'''class=["'][^"']*tgme_widget_message_owner_name[^"']*["'][^>]*>\s*<span[^>]*>([^<]+)</span>''',
      caseSensitive: false,
    ).firstMatch(html);
    final name = match?.group(1)?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  static String? _messageText(String html) {
    final match = RegExp(
      r'''class=["'][^"']*tgme_widget_message_text[^"']*["'][^>]*>([\s\S]*?)</div>''',
      caseSensitive: false,
    ).firstMatch(html);
    if (match == null) return null;
    final text = _stripTags(match.group(1)!).trim();
    return text.isEmpty ? null : text;
  }

  static bool _hasMessageText(String html) {
    return _messageText(html) != null;
  }

  static String? _bestThumbnail(String html) {
    for (final match in _bgImagePattern.allMatches(html)) {
      final url = _decodeUrl(match.group(1));
      if (url != null && isDirectMediaUrl(url) && !_isSiteIcon(url)) {
        return url;
      }
    }
    final og = _metaContent(html, 'og:image');
    if (og != null && isDirectMediaUrl(og) && !_isSiteIcon(og)) return og;
    return null;
  }

  static double? _durationFromHtml(String html) {
    final clock = RegExp(
      r'''class=["'][^"']*(?:message_video_duration|tgme_widget_message_voice_duration)[^"']*["'][^>]*>([^<]+)''',
      caseSensitive: false,
    ).firstMatch(html)?.group(1);
    final parsed = _parseClock(clock);
    if (parsed != null) return parsed;
    final og = _metaContent(html, 'og:video:duration');
    return og == null ? null : double.tryParse(og);
  }

  static double? _parseClock(String? raw) {
    if (raw == null) return null;
    final parts = raw.trim().split(':');
    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]);
      final seconds = double.tryParse(parts[1]);
      if (minutes == null || seconds == null) return null;
      return minutes * 60 + seconds;
    }
    if (parts.length == 3) {
      final hours = int.tryParse(parts[0]);
      final minutes = int.tryParse(parts[1]);
      final seconds = double.tryParse(parts[2]);
      if (hours == null || minutes == null || seconds == null) return null;
      return hours * 3600 + minutes * 60 + seconds;
    }
    return double.tryParse(raw.trim());
  }

  static int? _intMeta(String html, String property) {
    final value = _metaContent(html, property);
    return value == null ? null : int.tryParse(value);
  }

  static String? _metaContent(String html, String property) {
    final patterns = [
      RegExp(
        '<meta[^>]+property=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
        caseSensitive: false,
      ),
      RegExp(
        '<meta[^>]+content=["\']([^"\']+)["\'][^>]+property=["\']$property["\']',
        caseSensitive: false,
      ),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) {
        return _decodeUrl(match.group(1)!);
      }
    }
    return null;
  }

  static String? _cleanTitle(String? title, String? channel) {
    if (title == null) return channel;
    var cleaned = title.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+–\s+Telegram$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\|\s+Telegram$'), '');
    return cleaned.isEmpty ? channel : cleaned;
  }

  static String _stripTags(String raw) {
    return raw
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&nbsp;', ' ');
  }

  static String? _decodeUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var value = SocialSessionUtils.decodeEmbeddedUrl(raw).trim();
    value = value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return value.isEmpty ? null : value;
  }
}

enum TelegramHtmlStatus { ok, restricted, authenticationRequired, unavailable }

enum TelegramAccess { public, restricted, authenticationRequired, unavailable }

enum TelegramMediaType {
  photo,
  video,
  document,
  audio,
  voice,
  gif,
  mediaGroup,
  textMessage,
  unknown,
}

class TelegramMediaItem {
  const TelegramMediaItem({
    required this.url,
    required this.mediaType,
    required this.mimeType,
    this.thumbnailUrl,
    this.fileName,
    this.extra,
    this.durationSeconds,
    this.width,
    this.height,
  });

  final String url;
  final TelegramMediaType mediaType;
  final String mimeType;
  final String? thumbnailUrl;
  final String? fileName;
  final String? extra;
  final double? durationSeconds;
  final int? width;
  final int? height;
}

class TelegramMessageInfo {
  const TelegramMessageInfo({
    this.contentId,
    this.channel,
    this.messageId,
    this.title,
    this.caption,
    this.author,
    this.authorUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.mediaType = TelegramMediaType.unknown,
  });

  final String? contentId;
  final String? channel;
  final String? messageId;
  final String? title;
  final String? caption;
  final String? author;
  final String? authorUrl;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final TelegramMediaType mediaType;
}
