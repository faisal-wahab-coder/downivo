import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_session_utils.dart';
import 'social_url_utils.dart';

/// Resolves publicly accessible Snapchat URLs to direct media CDN links.
///
/// Supports:
/// - Public Spotlight posts
/// - Public Stories and Saved Stories when Snapchat exposes media
/// - Public photo / video Snaps
/// - Share (`t.snapchat.com`, `/t/`) and embed URLs
/// - Direct `sc-cdn.net` media URLs
///
/// Public profiles are classified and are **not** downloaded as a whole.
/// Private Stories, friends-only content, chat, Memories, and login walls
/// are never bypassed. HLS-only streams are not remuxed into a file.
class SnapchatResolver {
  SnapchatResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final type = SnapchatUri.classifyUrl(pageUrl);
    if (SnapchatUri.isRestricted(pageUrl)) return const [];
    if (SnapchatUri.requiresAuthentication(pageUrl)) return const [];
    if (!SnapchatUri.isDownloadable(pageUrl) &&
        type != SnapchatContentType.directMedia) {
      return const [];
    }

    if (type == SnapchatContentType.directMedia ||
        SnapchatUri.isDirectMediaHost(pageUrl.host)) {
      return [_directMediaResource(pageUrl, pageUrl)];
    }

    final resolved = SnapchatUri.normalize(pageUrl);
    if (!SnapchatUri.isDownloadable(resolved) &&
        SnapchatUri.classifyUrl(resolved) !=
            SnapchatContentType.directMedia) {
      return const [];
    }

    final contentId =
        SnapchatUri.contentIdFromUri(resolved) ??
        SnapchatUri.contentIdFromUri(pageUrl);

    String? lastBadHtml;
    String? lastOkHtml;
    var sawOkHtml = false;

    for (final target in SnapchatUri.fetchTargets(pageUrl)) {
      final html = await _fetchHtml(target);
      if (html == null || html.isEmpty) continue;
      final status = classifyHtml(html);
      if (status != SnapchatHtmlStatus.ok) {
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

  static SnapchatContentType classifyUrl(Uri uri) =>
      SnapchatUri.classifyUrl(uri);

  /// Public-page HTML status. Never treats a login wall as media.
  static SnapchatHtmlStatus classifyHtml(String html) {
    if (html.trim().isEmpty) return SnapchatHtmlStatus.unavailable;
    final lower = html.toLowerCase();
    if (lower.contains('this snap is private') ||
        lower.contains('this story is private') ||
        lower.contains('friends only') ||
        lower.contains('only friends can view') ||
        lower.contains('this content is private')) {
      return SnapchatHtmlStatus.restricted;
    }
    if (lower.contains('log in to snapchat') ||
        lower.contains('sign in to snapchat') ||
        lower.contains('login to continue') ||
        lower.contains('accounts.snapchat.com') &&
            lower.contains('password')) {
      return SnapchatHtmlStatus.authenticationRequired;
    }
    if (lower.contains('this snap has expired') ||
        lower.contains('this story has expired') ||
        lower.contains('this spotlight has expired') ||
        lower.contains('content has expired') ||
        lower.contains('this snapchat content has expired')) {
      return SnapchatHtmlStatus.expired;
    }
    if (lower.contains('this snap is no longer available') ||
        lower.contains('this spotlight is no longer available') ||
        lower.contains('this story is no longer available') ||
        lower.contains('content is no longer available') ||
        lower.contains('page not found') ||
        lower.contains('spotlight not found')) {
      return SnapchatHtmlStatus.unavailable;
    }
    return SnapchatHtmlStatus.ok;
  }

  static SnapchatAccess accessFor(Uri uri, {String? html}) {
    if (SnapchatUri.requiresAuthentication(uri)) {
      return SnapchatAccess.authenticationRequired;
    }
    if (SnapchatUri.isRestricted(uri)) {
      return SnapchatAccess.restricted;
    }
    if (html != null) {
      return switch (classifyHtml(html)) {
        SnapchatHtmlStatus.restricted => SnapchatAccess.restricted,
        SnapchatHtmlStatus.authenticationRequired =>
          SnapchatAccess.authenticationRequired,
        SnapchatHtmlStatus.unavailable => SnapchatAccess.unavailable,
        SnapchatHtmlStatus.expired => SnapchatAccess.expired,
        SnapchatHtmlStatus.ok => SnapchatAccess.public,
      };
    }
    return SnapchatAccess.public;
  }

  /// Parses downloadable media from public Snapchat HTML. HLS is skipped.
  static List<DiscoveredResource> parseHtmlResources({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    if (html.trim().isEmpty) return const [];
    if (classifyHtml(html) != SnapchatHtmlStatus.ok) return const [];

    final info = parseContentInfo(
      html: html,
      pageUrl: pageUrl,
      contentId: contentId,
    );
    final items = parseMediaItems(html, pageUrl: pageUrl);
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
  ///
  /// Spotlight / Snap / share pages expose this post's file as `og:video` and
  /// also embed a related-feed JSON list of other Spotlights. Those related
  /// URLs are not this post. Stories still harvest every snap from JSON.
  static List<SnapchatMediaItem> parseMediaItems(
    String html, {
    Uri? pageUrl,
  }) {
    final items = <SnapchatMediaItem>[];
    final seen = <String>{};
    final type = pageUrl == null ? null : SnapchatUri.classifyUrl(pageUrl);
    final isStory = type == SnapchatContentType.publicStory ||
        type == SnapchatContentType.savedStory;

    void add(SnapchatMediaItem item) {
      if (item.url.isEmpty || !isDirectMediaUrl(item.url)) return;
      if (!seen.add(_canonicalMediaKey(item.url))) return;
      items.add(item);
    }

    final ogVideo = _openGraphVideo(html);
    if (!isStory && ogVideo != null && isDirectMediaUrl(ogVideo)) {
      add(
        SnapchatMediaItem(
          url: ogVideo,
          mediaType: SnapchatMediaType.video,
          mimeType: mimeFromUrl(ogVideo, hint: 'video/mp4'),
          thumbnailUrl: _bestThumbnail(html),
          durationSeconds: _durationFromHtml(html),
          width: _intMeta(html, 'og:video:width'),
          height: _intMeta(html, 'og:video:height'),
        ),
      );
      if (items.isNotEmpty) return items;
    }

    for (final match in _jsonMediaUrlPattern.allMatches(html)) {
      final url = _decodeUrl(match.group(1));
      if (url == null) continue;
      final mime = mimeFromUrl(url, hint: _videoMimeHint(html, url));
      add(
        SnapchatMediaItem(
          url: url,
          mediaType: _mediaTypeFromUrl(url, html),
          mimeType: mime,
        ),
      );
    }

    if (items.isEmpty) {
      for (final match in _videoSrcPattern.allMatches(html)) {
        final url = _decodeUrl(match.group(1));
        if (url == null) continue;
        add(
          SnapchatMediaItem(
            url: url,
            mediaType: SnapchatMediaType.video,
            mimeType: mimeFromUrl(url, hint: 'video/mp4'),
            thumbnailUrl: _bestThumbnail(html),
          ),
        );
      }
    }

    if (items.isEmpty && ogVideo != null && isDirectMediaUrl(ogVideo)) {
      add(
        SnapchatMediaItem(
          url: ogVideo,
          mediaType: SnapchatMediaType.video,
          mimeType: mimeFromUrl(ogVideo, hint: 'video/mp4'),
          thumbnailUrl: _bestThumbnail(html),
          durationSeconds: _durationFromHtml(html),
          width: _intMeta(html, 'og:video:width'),
          height: _intMeta(html, 'og:video:height'),
        ),
      );
    }

    final hasVideoTag =
        ogVideo != null || html.toLowerCase().contains('<video');

    if (items.isEmpty && !hasVideoTag) {
      for (final match in _imgSrcPattern.allMatches(html)) {
        final url = _decodeUrl(match.group(1));
        if (url == null || _isSiteIcon(url)) continue;
        add(
          SnapchatMediaItem(
            url: url,
            mediaType: SnapchatMediaType.photo,
            mimeType: mimeFromUrl(url, hint: 'image/jpeg'),
            width: _intMeta(html, 'og:image:width'),
            height: _intMeta(html, 'og:image:height'),
          ),
        );
      }
    }

    if (items.isEmpty && !hasVideoTag) {
      final ogImage =
          _metaContent(html, 'og:image') ??
          _metaContent(html, 'og:image:url') ??
          _metaContent(html, 'og:image:secure_url');
      if (ogImage != null &&
          isDirectMediaUrl(ogImage) &&
          !_isSiteIcon(ogImage)) {
        add(
          SnapchatMediaItem(
            url: ogImage,
            mediaType: SnapchatMediaType.photo,
            mimeType: mimeFromUrl(ogImage, hint: 'image/jpeg'),
            width: _intMeta(html, 'og:image:width'),
            height: _intMeta(html, 'og:image:height'),
          ),
        );
      }
    }

    return items;
  }

  static SnapchatContentInfo parseContentInfo({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    final username = SnapchatUri.usernameFromUri(pageUrl);
    final title =
        _metaContent(html, 'og:title') ??
        _metaContent(html, 'twitter:title');
    final caption =
        _metaContent(html, 'og:description') ??
        _metaContent(html, 'twitter:description');
    final thumbnail = _bestThumbnail(html);
    final duration = _durationFromHtml(html);
    final width =
        _intMeta(html, 'og:video:width') ?? _intMeta(html, 'og:image:width');
    final height =
        _intMeta(html, 'og:video:height') ?? _intMeta(html, 'og:image:height');
    final mediaType = detectMediaType(html, pageUrl: pageUrl);
    final creator =
        _jsonString(html, 'creatorName') ??
        _jsonString(html, 'displayName') ??
        username;
    final id = contentId ?? SnapchatUri.contentIdFromUri(pageUrl);

    return SnapchatContentInfo(
      contentId: id,
      username: username,
      profileId: SnapchatUri.profileIdFromUri(pageUrl),
      title: _cleanTitle(title, username),
      caption: caption,
      creator: creator,
      creatorUrl: username == null
          ? null
          : 'https://www.snapchat.com/add/$username',
      thumbnailUrl: thumbnail,
      durationSeconds: duration,
      width: width,
      height: height,
      mediaType: mediaType,
      canonicalUrl: SnapchatUri.normalize(pageUrl).toString(),
    );
  }

  static SnapchatProfileInfo parseProfileInfo({
    required String html,
    required Uri pageUrl,
  }) {
    final username = SnapchatUri.usernameFromUri(pageUrl);
    final title = _cleanTitle(
      _metaContent(html, 'og:title'),
      username,
    );
    final description = _metaContent(html, 'og:description');
    final thumbnail = _bestThumbnail(html);
    return SnapchatProfileInfo(
      username: username,
      profileId: SnapchatUri.profileIdFromUri(pageUrl),
      displayName: title ?? username,
      description: description,
      thumbnailUrl: thumbnail,
    );
  }

  static SnapchatMediaType detectMediaType(String html, {Uri? pageUrl}) {
    final items = parseMediaItems(html, pageUrl: pageUrl);
    if (items.length > 1) return SnapchatMediaType.story;
    if (items.length == 1) return items.first.mediaType;
    if (_hasHlsOnly(html)) return SnapchatMediaType.hlsOnly;
    return SnapchatMediaType.unknown;
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
    return SnapchatUri.isDirectMediaHost(host);
  }

  static bool htmlHasHlsOnly(String html) => _hasHlsOnly(html);

  static String userFacingError(Uri uri, {String? html}) {
    final access = accessFor(uri, html: html);
    if (access == SnapchatAccess.restricted) {
      return 'This Snapchat content is restricted.';
    }
    if (access == SnapchatAccess.authenticationRequired) {
      return 'Snapchat authentication is required.';
    }
    if (access == SnapchatAccess.expired) {
      return 'This Snapchat content has expired.';
    }
    if (access == SnapchatAccess.unavailable) {
      return 'This Snapchat content is no longer available.';
    }

    if (html != null && _hasHlsOnly(html) && parseMediaItems(html).isEmpty) {
      return 'This Snapchat video is HLS-only and cannot be saved as a '
          'single file.';
    }

    return switch (SnapchatUri.classifyUrl(uri)) {
      SnapchatContentType.home =>
        'This is the Snapchat home page, not a downloadable item.',
      SnapchatContentType.publicProfile =>
        'This is a Snapchat public profile, not a downloadable media resource. '
            'Open a specific public Spotlight, Story, or Snap to download it.',
      SnapchatContentType.spotlightFeed =>
        'This is the Snapchat Spotlight feed, not a downloadable post. '
            'Open a specific public Spotlight to download it.',
      SnapchatContentType.lens =>
        'Snapchat Lenses are not downloaded as media files.',
      SnapchatContentType.private =>
        'This Snapchat content is restricted.',
      SnapchatContentType.authentication =>
        'Snapchat authentication is required.',
      SnapchatContentType.deepLink =>
        'This Snapchat link is not a downloadable public item.',
      SnapchatContentType.nonContent =>
        'Unable to identify Snapchat content.',
      SnapchatContentType.spotlight ||
      SnapchatContentType.publicStory ||
      SnapchatContentType.savedStory ||
      SnapchatContentType.snap ||
      SnapchatContentType.share ||
      SnapchatContentType.embed ||
      SnapchatContentType.directMedia =>
        'Could not find downloadable media on this Snapchat URL. '
            'It may be restricted, expired, or Snapchat did not expose a file.',
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
          headers: SocialHttpHeaders.forPageFetch(url, SocialPlatform.snapchat),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static DiscoveredResource _directMediaResource(Uri mediaUri, Uri pageUrl) {
    final url = mediaUri.toString();
    final mime = mimeFromUrl(
      url,
      hint: SnapchatUri.isDirectMediaHost(mediaUri.host) ? 'video/mp4' : null,
    );
    var fileName = MediaExtractor.buildFileNameForSocial(
      pageUrl: pageUrl,
      platform: SocialPlatform.snapchat,
      mediaUrl: url,
      fallbackSlug: SnapchatUri.contentIdFromUri(pageUrl) ?? 'snapchat_media',
      mimeHint: mime,
    );
    fileName = _withMediaExtension(fileName, mime);
    return DiscoveredResource(
      directUrl: url,
      fileName: fileName,
      platform: SocialPlatform.snapchat.label,
      pageUrl: pageUrl.toString(),
      mimeType: mime,
      thumbnailUrl: mime.startsWith('image/') ? url : null,
      requestHeaders: _mediaHeaders(pageUrl),
    );
  }

  static Map<String, String> _mediaHeaders(Uri pageUrl) {
    return SocialHttpHeaders.forMediaDownload(
      pageUrl: pageUrl,
      mediaUrl: 'https://cf-st.sc-cdn.net/',
      platform: SocialPlatform.snapchat,
    );
  }

  static DiscoveredResource _resourceForItem({
    required SnapchatMediaItem item,
    required Uri pageUrl,
    required SnapchatContentInfo info,
    required Map<String, String> headers,
    required int index,
    required int total,
  }) {
    final slug =
        info.contentId?.replaceAll('/', '_') ??
        SnapchatUri.contentIdFromUri(pageUrl)?.replaceAll('/', '_') ??
        'snapchat';
    final indexedSlug = total > 1 ? '${slug}_${index + 1}' : slug;
    final titleForName = total > 1
        ? '${info.title ?? slug} ${index + 1}'
        : info.title;
    final mime = _mimeForItem(item, htmlHasVideo: info.mediaType == SnapchatMediaType.video);
    var fileName = MediaExtractor.buildFileNameForSocial(
      pageUrl: pageUrl,
      platform: SocialPlatform.snapchat,
      mediaUrl: item.url,
      title: titleForName,
      fallbackSlug: indexedSlug,
      mimeHint: mime,
    );
    fileName = _withMediaExtension(fileName, mime);
    return DiscoveredResource(
      directUrl: item.url,
      fileName: fileName,
      platform: SocialPlatform.snapchat.label,
      pageUrl: pageUrl.toString(),
      title: info.title,
      mimeType: mime,
      thumbnailUrl:
          item.thumbnailUrl ??
          info.thumbnailUrl ??
          (item.mimeType.startsWith('image/') ? item.url : null),
      requestHeaders: headers,
      durationSeconds: item.durationSeconds ?? info.durationSeconds,
      width: item.width ?? info.width,
      height: item.height ?? info.height,
      kind: DiscoveredResourceKind.fromMime(
        mime,
        carousel: total > 1,
      ),
    );
  }

  static final _jsonMediaUrlPattern = RegExp(
    r'''"(?:contentUrl|snapMediaUrl|mediaUrl|playbackUrl)"\s*:\s*"(https?:\\?/\\?/[^"]+)"''',
    caseSensitive: false,
  );

  static final _videoSrcPattern = RegExp(
    r'''<(?:video|source)[^>]+src=["']([^"']+)["']''',
    caseSensitive: false,
  );

  static final _imgSrcPattern = RegExp(
    r'''<img[^>]+src=["']([^"']+)["']''',
    caseSensitive: false,
  );

  static String _mimeForItem(SnapchatMediaItem item, {required bool htmlHasVideo}) {
    if (item.mimeType.startsWith('video/') || item.mimeType.startsWith('image/')) {
      return item.mimeType;
    }
    if (item.mediaType == SnapchatMediaType.video || htmlHasVideo) {
      return 'video/mp4';
    }
    if (item.mediaType == SnapchatMediaType.photo) return 'image/jpeg';
    return item.mimeType;
  }

  static String _withMediaExtension(String fileName, String mime) {
    final lower = fileName.toLowerCase();
    if (mime.startsWith('video/')) {
      if (lower.endsWith('.mp4') ||
          lower.endsWith('.webm') ||
          lower.endsWith('.m4v')) {
        return fileName;
      }
      final dot = fileName.lastIndexOf('.');
      final base = dot > 0 ? fileName.substring(0, dot) : fileName;
      return '$base.mp4';
    }
    if (mime.startsWith('image/')) {
      if (lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif')) {
        return fileName;
      }
      final dot = fileName.lastIndexOf('.');
      final base = dot > 0 ? fileName.substring(0, dot) : fileName;
      return '$base.jpg';
    }
    return fileName;
  }

  static SnapchatMediaType _mediaTypeFromUrl(String url, String html) {
    final mime = mimeFromUrl(url);
    if (mime.startsWith('image/')) return SnapchatMediaType.photo;
    if (mime.startsWith('video/')) return SnapchatMediaType.video;
    if (html.toLowerCase().contains('og:video')) {
      return SnapchatMediaType.video;
    }
    return SnapchatMediaType.unknown;
  }

  static bool _hasHlsOnly(String html) {
    final lower = html.toLowerCase();
    if (!lower.contains('.m3u8') && !lower.contains('.mpd')) return false;
    return parseMediaItems(html).isEmpty;
  }

  static bool _isSiteIcon(String url) {
    final lower = url.toLowerCase();
    return lower.contains('favicon') ||
        lower.contains('apple-touch-icon') ||
        lower.contains('snapchat-logo') ||
        lower.contains('/ghost') ||
        lower.contains('static.snapchat.com/img') ||
        lower.contains('accounts.snapchat.com');
  }

  static String? _openGraphVideo(String html) {
    return _metaContent(html, 'og:video') ??
        _metaContent(html, 'og:video:url') ??
        _metaContent(html, 'og:video:secure_url') ??
        _metaContent(html, 'twitter:player:stream');
  }

  static String? _videoMimeHint(String html, String url) {
    if (html.toLowerCase().contains('og:video')) return 'video/mp4';
    final mime = mimeFromUrl(url);
    return mime == 'application/octet-stream' ? 'video/mp4' : null;
  }

  static String _canonicalMediaKey(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty) return url;
    return '${uri.host.toLowerCase()}${uri.path}';
  }

  static String? _bestThumbnail(String html) {
    final og = _metaContent(html, 'og:image');
    if (og != null && !_isSiteIcon(og)) {
      if (isDirectMediaUrl(og) || og.startsWith('https://')) return og;
    }
    return null;
  }

  static double? _durationFromHtml(String html) {
    final og =
        _metaContent(html, 'og:video:duration') ??
        _metaContent(html, 'og:duration') ??
        _jsonString(html, 'duration');
    if (og == null) return null;
    return double.tryParse(og);
  }

  static int? _intMeta(String html, String property) {
    final value = _metaContent(html, property);
    return value == null ? null : int.tryParse(value);
  }

  static String? _jsonString(String html, String field) {
    final match = RegExp(
      '"$field"\\s*:\\s*"((?:\\\\.|[^"\\\\])*)"',
      caseSensitive: false,
    ).firstMatch(html);
    if (match == null) return null;
    final value = _decodeUrl(match.group(1));
    return value == null || value.isEmpty ? null : value;
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
      RegExp(
        '<meta[^>]+name=["\']$property["\'][^>]+content=["\']([^"\']+)["\']',
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

  static String? _cleanTitle(String? title, String? username) {
    if (title == null) return username;
    var cleaned = title.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+[–\-|]\s+Snapchat$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+on Snapchat$'), '');
    return cleaned.isEmpty ? username : cleaned;
  }

  static String? _decodeUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    var value = SocialSessionUtils.decodeEmbeddedUrl(raw).trim();
    value = value
        .replaceAll(r'\/', '/')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'");
    return value.isEmpty ? null : value;
  }
}

enum SnapchatHtmlStatus {
  ok,
  restricted,
  authenticationRequired,
  unavailable,
  expired,
}

enum SnapchatAccess {
  public,
  restricted,
  authenticationRequired,
  unavailable,
  expired,
}

enum SnapchatMediaType { photo, video, story, hlsOnly, unknown }

class SnapchatMediaItem {
  const SnapchatMediaItem({
    required this.url,
    required this.mediaType,
    required this.mimeType,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
  });

  final String url;
  final SnapchatMediaType mediaType;
  final String mimeType;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
}

class SnapchatContentInfo {
  const SnapchatContentInfo({
    this.contentId,
    this.username,
    this.profileId,
    this.title,
    this.caption,
    this.creator,
    this.creatorUrl,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.mediaType = SnapchatMediaType.unknown,
    this.canonicalUrl,
  });

  final String? contentId;
  final String? username;
  final String? profileId;
  final String? title;
  final String? caption;
  final String? creator;
  final String? creatorUrl;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final SnapchatMediaType mediaType;
  final String? canonicalUrl;
}

class SnapchatProfileInfo {
  const SnapchatProfileInfo({
    this.username,
    this.profileId,
    this.displayName,
    this.description,
    this.thumbnailUrl,
  });

  final String? username;
  final String? profileId;
  final String? displayName;
  final String? description;
  final String? thumbnailUrl;
}
