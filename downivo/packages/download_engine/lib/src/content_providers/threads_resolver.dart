import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_session_utils.dart';
import 'social_url_utils.dart';

/// Resolves publicly accessible Threads URLs to direct media CDN links.
///
/// Supports:
/// - Public image posts
/// - Public video posts (progressive MP4 only; HLS is not downloaded)
/// - Public carousel / multi-media posts (order preserved, duplicates collapsed)
/// - Public quote posts and reposts when the underlying media is exposed
/// - Share / `threads.com` / embed / tracking URLs (normalized to post identity)
///
/// Profiles and the home page are classified and are **not** downloaded.
/// Text-only posts produce no fabricated media. Private profiles, private
/// posts, login walls, and deleted content are never bypassed.
class ThreadsResolver {
  ThreadsResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final type = ThreadsUri.classifyUrl(pageUrl);
    if (ThreadsUri.requiresAuthentication(pageUrl)) return const [];
    if (!ThreadsUri.isDownloadable(pageUrl)) return const [];

    final resolved = ThreadsUri.normalize(pageUrl);
    if (!ThreadsUri.isDownloadable(resolved) &&
        ThreadsUri.classifyUrl(resolved) != ThreadsContentType.share) {
      return const [];
    }

    final contentId =
        ThreadsUri.postIdFromUri(resolved) ?? ThreadsUri.postIdFromUri(pageUrl);

    String? lastBadHtml;
    String? lastOkHtml;
    var sawOkHtml = false;

    for (final target in ThreadsUri.fetchTargets(resolved)) {
      final html = await _fetchHtml(target);
      if (html == null || html.isEmpty) continue;
      final status = classifyHtml(html);
      if (status != ThreadsHtmlStatus.ok) {
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

  static ThreadsContentType classifyUrl(Uri uri) =>
      ThreadsUri.classifyUrl(uri);

  /// Public-page HTML status. Never treats a login wall as media.
  ///
  /// Public Threads pages include a chrome "Log in" button and JS modules
  /// whose names contain "password". Those are not an authentication wall
  /// when the page also exposes public post media / Open Graph.
  static ThreadsHtmlStatus classifyHtml(String html) {
    if (html.trim().isEmpty) return ThreadsHtmlStatus.unavailable;
    final lower = html.toLowerCase();
    if (lower.contains('this profile is private') ||
        lower.contains('this account is private') ||
        lower.contains('this post is from a private account') ||
        lower.contains('only approved followers') ||
        lower.contains('this content is private') ||
        lower.contains('this threads post is private')) {
      return ThreadsHtmlStatus.restricted;
    }
    if (lower.contains("sorry, this page isn't available") ||
        lower.contains('this post is no longer available') ||
        lower.contains('this content is no longer available') ||
        lower.contains("this page isn't available") ||
        lower.contains('content isn\'t available') ||
        lower.contains('the link you followed may be broken') ||
        lower.contains('page not found')) {
      return ThreadsHtmlStatus.unavailable;
    }
    if (!_hasPublicPostSignals(html) &&
        (lower.contains('log in to threads') ||
            lower.contains('log in to see') ||
            lower.contains('login to continue'))) {
      return ThreadsHtmlStatus.authenticationRequired;
    }
    return ThreadsHtmlStatus.ok;
  }

  static bool _hasPublicPostSignals(String html) {
    return html.contains('image_versions2') ||
        html.contains('"video_versions"') ||
        html.contains('og:image') ||
        html.contains('og:video') ||
        html.contains('og:description');
  }

  static ThreadsAccess accessFor(Uri uri, {String? html}) {
    if (ThreadsUri.requiresAuthentication(uri)) {
      return ThreadsAccess.authenticationRequired;
    }
    if (html != null) {
      return switch (classifyHtml(html)) {
        ThreadsHtmlStatus.restricted => ThreadsAccess.restricted,
        ThreadsHtmlStatus.authenticationRequired =>
          ThreadsAccess.authenticationRequired,
        ThreadsHtmlStatus.unavailable => ThreadsAccess.unavailable,
        ThreadsHtmlStatus.ok => ThreadsAccess.public,
      };
    }
    return ThreadsAccess.public;
  }

  /// Parses downloadable media from public Threads HTML. HLS is skipped.
  static List<DiscoveredResource> parseHtmlResources({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    if (html.trim().isEmpty) return const [];
    if (classifyHtml(html) != ThreadsHtmlStatus.ok) return const [];

    final info = parsePostInfo(
      html: html,
      pageUrl: pageUrl,
      contentId: contentId,
    );
    final items = parseMediaItems(html, postId: contentId);
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
  static List<ThreadsMediaItem> parseMediaItems(
    String html, {
    String? postId,
  }) {
    final items = <ThreadsMediaItem>[];
    final seen = <String>{};
    final scoped = _postScopedHtml(html, postId) ?? html;

    void add(ThreadsMediaItem item) {
      if (item.url.isEmpty || !isDirectMediaUrl(item.url)) return;
      if (_isSiteIcon(item.url) || _isProfileImage(item.url)) return;
      if (!seen.add(_identityUrl(item.url))) return;
      items.add(item);
    }

    final isVideoPost = _isVideoPost(scoped);
    final hasCarousel = _carouselArrayPattern.hasMatch(scoped);

    if (hasCarousel) {
      for (final carouselItem in _extractCarouselItems(scoped)) {
        add(carouselItem);
      }
    }

    if (items.isEmpty) {
      for (final video in _extractVideoVersions(scoped)) {
        add(video);
      }
    }

    // Video posts always include image_versions2 as the poster. That is not
    // the downloadable media. `"carousel_media":null` must not be treated as
    // a carousel of those posters.
    if (items.isEmpty && !isVideoPost) {
      for (final image in _extractImageCandidates(scoped)) {
        add(image);
      }
    }

    final ogVideo = _metaContent(html, 'og:video') ??
        _metaContent(html, 'og:video:url');
    if (items.isEmpty && ogVideo != null) {
      add(
        ThreadsMediaItem(
          url: ogVideo,
          mediaType: ThreadsMediaType.video,
          mimeType: mimeFromUrl(ogVideo),
          thumbnailUrl: _bestThumbnail(html),
          durationSeconds: _durationFromHtml(html),
          width: _intMeta(html, 'og:video:width'),
          height: _intMeta(html, 'og:video:height'),
        ),
      );
    }

    // Thumbnails are not downloadable media when the page is a video post or
    // only exposes HLS.
    if (items.isEmpty && ogVideo == null && !isVideoPost) {
      final ogImage = _metaContent(html, 'og:image');
      if (ogImage != null &&
          !_isSiteIcon(ogImage) &&
          !_isProfileImage(ogImage)) {
        add(
          ThreadsMediaItem(
            url: ogImage,
            mediaType: ThreadsMediaType.image,
            mimeType: mimeFromUrl(ogImage),
            thumbnailUrl: ogImage,
            width: _intMeta(html, 'og:image:width'),
            height: _intMeta(html, 'og:image:height'),
          ),
        );
      }
    }

    if (items.isEmpty) {
      for (final match in _jsonMediaUrlPattern.allMatches(html)) {
        final url = _decodeUrl(match.group(1));
        if (url == null) continue;
        final type = _mediaTypeFromUrl(url);
        if (isVideoPost && type != ThreadsMediaType.video) continue;
        add(
          ThreadsMediaItem(
            url: url,
            mediaType: type,
            mimeType: mimeFromUrl(url),
            thumbnailUrl: _bestThumbnail(html),
          ),
        );
      }
    }

    return items;
  }

  static ThreadsMediaType detectMediaType(String html) {
    if (classifyHtml(html) != ThreadsHtmlStatus.ok) {
      return ThreadsMediaType.unknown;
    }
    final items = parseMediaItems(html);
    if (items.isEmpty) {
      if (_hasHlsOnly(html)) return ThreadsMediaType.hlsOnly;
      if (_looksLikeTextPost(html)) return ThreadsMediaType.text;
      return ThreadsMediaType.unknown;
    }
    if (items.length > 1) {
      final types = items.map((i) => i.mediaType).toSet();
      if (types.length > 1) return ThreadsMediaType.multiMedia;
      return ThreadsMediaType.carousel;
    }
    return items.single.mediaType;
  }

  static ThreadsPostKind detectPostKind(String html) {
    final lower = html.toLowerCase();
    if (lower.contains('"quoted_post"') ||
        lower.contains('quoted_post') && lower.contains('text_post_app_info')) {
      return ThreadsPostKind.quote;
    }
    if (lower.contains('"reposted_post"') ||
        lower.contains('reposted this') ||
        lower.contains('"is_repost":true')) {
      return ThreadsPostKind.repost;
    }
    if (detectMediaType(html) == ThreadsMediaType.text) {
      return ThreadsPostKind.textOnly;
    }
    return ThreadsPostKind.original;
  }

  static ThreadsPostInfo parsePostInfo({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    final title = _metaContent(html, 'og:title') ??
        _metaContent(html, 'twitter:title');
    final description = _metaContent(html, 'og:description') ??
        _metaContent(html, 'twitter:description');
    final username = _jsonString(html, 'username') ??
        ThreadsUri.usernameFromUri(pageUrl);
    final author = _jsonString(html, 'full_name') ??
        _cleanTitle(title, username);
    final authorId = _jsonString(html, 'pk') ?? _jsonString(html, 'id');
    final caption = _jsonString(html, 'text') ?? description;
    final thumbnail = _bestThumbnail(html);
    final duration = _durationFromHtml(html);
    final canonical = _metaContent(html, 'og:url') ??
        ThreadsUri.normalize(pageUrl).toString();
    final postId = contentId ??
        ThreadsUri.postIdFromUri(pageUrl) ??
        _jsonString(html, 'code');
    final quotedId = _quotedOrRepostedCode(html);
    final published = _publishedFromHtml(html);

    return ThreadsPostInfo(
      postId: postId,
      originalPostId: quotedId,
      username: username,
      author: author,
      authorId: authorId,
      title: _cleanTitle(title, username),
      caption: caption,
      thumbnailUrl: thumbnail,
      durationSeconds: duration,
      width: _intMeta(html, 'og:video:width') ??
          _intMeta(html, 'og:image:width'),
      height: _intMeta(html, 'og:video:height') ??
          _intMeta(html, 'og:image:height'),
      canonicalUrl: canonical,
      publishedAt: published,
      postKind: detectPostKind(html),
      mediaType: detectMediaType(html),
    );
  }

  static ThreadsProfileInfo parseProfileInfo({
    required String html,
    required Uri pageUrl,
  }) {
    final username = _jsonString(html, 'username') ??
        ThreadsUri.usernameFromUri(pageUrl);
    final displayName = _jsonString(html, 'full_name') ??
        _cleanTitle(_metaContent(html, 'og:title'), username);
    final description = _metaContent(html, 'og:description') ??
        _jsonString(html, 'biography');
    return ThreadsProfileInfo(
      username: username,
      displayName: displayName,
      description: description,
      thumbnailUrl: _bestThumbnail(html),
    );
  }

  static String mimeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) {
      return 'application/vnd.apple.mpegurl';
    }
    if (lower.contains('.webm')) return 'video/webm';
    if (lower.contains('.mov')) return 'video/quicktime';
    if (lower.contains('.mp4') ||
        lower.contains('/video/') ||
        lower.contains('/o1/v/') ||
        lower.contains('/v/t16') ||
        lower.contains('/v/t2/')) {
      return 'video/mp4';
    }
    if (lower.contains('.png')) return 'image/png';
    if (lower.contains('.webp')) return 'image/webp';
    if (lower.contains('.gif')) return 'image/gif';
    if (lower.contains('.jpg') ||
        lower.contains('.jpeg') ||
        lower.contains('/image/') ||
        lower.contains('scontent')) {
      return 'image/jpeg';
    }
    return 'application/octet-stream';
  }

  static bool isDirectMediaUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) return false;
    if (lower.startsWith('javascript:') || lower.startsWith('file:')) {
      return false;
    }
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
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
    if (host == 'threads.net' ||
        host.endsWith('.threads.net') ||
        host == 'threads.com' ||
        host.endsWith('.threads.com')) {
      return false;
    }
    if (host.contains('static.cdninstagram.com') ||
        lower.contains('rsrc.php')) {
      return false;
    }
    return host.contains('cdninstagram.com') || host.contains('fbcdn.net');
  }

  static bool htmlHasHlsOnly(String html) => _hasHlsOnly(html);

  static String userFacingError(Uri uri, {String? html}) {
    final access = accessFor(uri, html: html);
    if (access == ThreadsAccess.restricted) {
      return 'This Threads content is restricted.';
    }
    if (access == ThreadsAccess.authenticationRequired) {
      return 'Threads authentication is required.';
    }
    if (access == ThreadsAccess.unavailable) {
      return 'This Threads post is no longer available.';
    }

    if (html != null && _hasHlsOnly(html) && parseMediaItems(html).isEmpty) {
      return 'This Threads video is HLS-only and cannot be saved as a '
          'single file.';
    }

    if (html != null && detectMediaType(html) == ThreadsMediaType.text) {
      return 'This Threads post has no downloadable media.';
    }

    return switch (ThreadsUri.classifyUrl(uri)) {
      ThreadsContentType.home =>
        'This is the Threads home page, not a downloadable item.',
      ThreadsContentType.profile =>
        'This is a Threads profile, not a downloadable media resource. '
            'Open a specific public post to download it.',
      ThreadsContentType.authentication =>
        'Threads authentication is required.',
      ThreadsContentType.nonContent =>
        'Unable to identify Threads content.',
      ThreadsContentType.post ||
      ThreadsContentType.embed ||
      ThreadsContentType.share =>
        'Could not find downloadable media on this Threads URL. '
            'It may be text-only, restricted, deleted, or Threads did not '
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
          headers: SocialHttpHeaders.forPageFetch(url, SocialPlatform.threads),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  static Map<String, String> _mediaHeaders(Uri pageUrl) {
    return SocialHttpHeaders.forMediaDownload(
      pageUrl: pageUrl,
      mediaUrl: 'https://scontent.cdninstagram.com/',
      platform: SocialPlatform.threads,
    );
  }

  static DiscoveredResource _resourceForItem({
    required ThreadsMediaItem item,
    required Uri pageUrl,
    required ThreadsPostInfo info,
    required Map<String, String> headers,
    required int index,
    required int total,
  }) {
    final identityId = info.originalPostId ?? info.postId;
    final slug =
        identityId?.replaceAll('/', '_') ??
        ThreadsUri.postIdFromUri(pageUrl)?.replaceAll('/', '_') ??
        'threads';
    final indexedSlug = total > 1 ? '${slug}_${index + 1}' : slug;
    final titleForName = total > 1
        ? '${info.title ?? slug} ${index + 1}'
        : info.title;
    var fileName = MediaExtractor.buildFileNameForSocial(
      pageUrl: pageUrl,
      platform: SocialPlatform.threads,
      mediaUrl: item.url,
      title: titleForName,
      fallbackSlug: indexedSlug,
      mimeHint: item.mimeType,
    );
    if (total > 1) {
      fileName = _indexedFileName(fileName, index + 1);
    }
    return DiscoveredResource(
      directUrl: item.url,
      fileName: fileName,
      platform: SocialPlatform.threads.label,
      pageUrl: pageUrl.toString(),
      title: info.title,
      mimeType: item.mimeType,
      thumbnailUrl:
          item.thumbnailUrl ??
          info.thumbnailUrl ??
          (item.mimeType.startsWith('image/') ? item.url : null),
      requestHeaders: headers,
      author: info.author ?? info.username,
      durationSeconds: item.durationSeconds ?? info.durationSeconds,
      width: item.width ?? info.width,
      height: item.height ?? info.height,
      kind: DiscoveredResourceKind.fromMime(
        item.mimeType,
        carousel: total > 1,
      ),
    );
  }

  static bool _isVideoPost(String html) {
    return _videoVersionsArrayPattern.hasMatch(html) ||
        _videoMediaTypePattern.hasMatch(html);
  }

  static final _carouselArrayPattern = RegExp(r'"carousel_media"\s*:\s*\[');
  static final _videoVersionsArrayPattern = RegExp(
    r'"video_versions"\s*:\s*\[',
  );
  static final _videoMediaTypePattern = RegExp(r'"media_type"\s*:\s*2\b');

  static List<ThreadsMediaItem> _extractCarouselItems(String html) {
    final items = <ThreadsMediaItem>[];
    for (final match in _carouselArrayPattern.allMatches(html)) {
      final array = _balancedJsonArray(html, match.end - 1);
      if (array != null) {
        items.addAll(_mediaFromCarouselArray(array));
      }
    }
    return items;
  }

  static List<ThreadsMediaItem> _mediaFromCarouselArray(String array) {
    final items = <ThreadsMediaItem>[];
    for (final block in _topLevelObjects(array)) {
      final video = _bestFromBlock(block, isVideo: true);
      if (video != null) {
        items.add(video);
        continue;
      }
      final image = _bestFromBlock(block, isVideo: false);
      if (image != null) items.add(image);
    }
    if (items.isEmpty) {
      items.addAll(_extractVideoVersions(array));
      if (items.isEmpty) items.addAll(_extractImageCandidates(array));
    }
    return items;
  }

  static List<String> _topLevelObjects(String json) {
    final objects = <String>[];
    var depth = 0;
    var start = -1;
    for (var i = 0; i < json.length; i++) {
      final ch = json[i];
      if (ch == '{') {
        if (depth == 0) start = i;
        depth++;
      } else if (ch == '}') {
        depth--;
        if (depth == 0 && start >= 0) {
          objects.add(json.substring(start, i + 1));
          start = -1;
        }
      }
    }
    return objects;
  }

  static List<ThreadsMediaItem> _extractVideoVersions(String html) {
    for (final match in _videoVersionsArrayPattern.allMatches(html)) {
      final array = _balancedJsonArray(html, match.end - 1);
      if (array == null) continue;
      final best = _bestFromBlock(array, isVideo: true);
      if (best != null) {
        return [
          ThreadsMediaItem(
            url: best.url,
            mediaType: ThreadsMediaType.video,
            mimeType: mimeFromUrl(best.url),
            thumbnailUrl: _bestThumbnail(html),
            durationSeconds: _durationFromHtml(html),
            width: best.width,
            height: best.height,
          ),
        ];
      }
    }
    return const [];
  }

  static List<ThreadsMediaItem> _extractImageCandidates(String html) {
    final items = <ThreadsMediaItem>[];
    ThreadsMediaItem? best;
    var bestPixels = -1;
    for (final match in _jsonUrlValuePattern.allMatches(html)) {
      final url = _decodeUrl(match.group(1));
      if (url == null || !isDirectMediaUrl(url)) continue;
      if (_isProfileImage(url) || _isSiteIcon(url)) continue;
      if (_mediaTypeFromUrl(url) == ThreadsMediaType.video) continue;
      final nearby = _nearbyWindow(html, match.start);
      final width = _intFromNearby(nearby, 'width') ?? 0;
      final height = _intFromNearby(nearby, 'height') ?? 0;
      final pixels = width * height;
      if (pixels >= bestPixels) {
        bestPixels = pixels;
        best = ThreadsMediaItem(
          url: url,
          mediaType: ThreadsMediaType.image,
          mimeType: mimeFromUrl(url),
          thumbnailUrl: url,
          width: width == 0 ? null : width,
          height: height == 0 ? null : height,
        );
      }
    }
    if (best != null) items.add(best);
    return items;
  }

  static ThreadsMediaItem? _bestFromBlock(String block, {required bool isVideo}) {
    ThreadsMediaItem? best;
    var bestPixels = -1;
    for (final match in _jsonUrlValuePattern.allMatches(block)) {
      final url = _decodeUrl(match.group(1));
      if (url == null || !isDirectMediaUrl(url)) continue;
      final type = _mediaTypeFromUrl(url);
      if (isVideo && type != ThreadsMediaType.video) continue;
      if (!isVideo && type == ThreadsMediaType.video) continue;
      if (_isProfileImage(url) || _isSiteIcon(url)) continue;
      final width = _intFromNearby(block, 'width') ?? 0;
      final height = _intFromNearby(block, 'height') ?? 0;
      final pixels = width * height;
      if (pixels >= bestPixels) {
        bestPixels = pixels;
        best = ThreadsMediaItem(
          url: url,
          mediaType: isVideo ? ThreadsMediaType.video : ThreadsMediaType.image,
          mimeType: mimeFromUrl(url),
          thumbnailUrl: isVideo ? null : url,
          width: width == 0 ? null : width,
          height: height == 0 ? null : height,
        );
      }
    }
    return best;
  }

  /// Captures JSON `"url"` values, including `\u002F`-escaped CDN links.
  static final _jsonUrlValuePattern = RegExp(
    r'"url"\s*:\s*"((?:\\.|[^"\\])*)"',
    caseSensitive: false,
  );

  static final _jsonMediaUrlPattern = RegExp(
    r'''"(?:video_url|display_url|image_url|contentUrl|playbackUrl|downloadUrl)"\s*:\s*"((?:\\.|[^"\\])*)"''',
    caseSensitive: false,
  );

  static ThreadsMediaType _mediaTypeFromUrl(String url) {
    final mime = mimeFromUrl(url);
    if (mime.startsWith('image/')) return ThreadsMediaType.image;
    if (mime.startsWith('video/')) return ThreadsMediaType.video;
    return ThreadsMediaType.unknown;
  }

  static bool _hasHlsOnly(String html) {
    final lower = html.toLowerCase();
    if (!lower.contains('.m3u8') && !lower.contains('.mpd')) return false;
    return parseMediaItems(html).isEmpty;
  }

  static bool _looksLikeTextPost(String html) {
    final lower = html.toLowerCase();
    if (lower.contains('og:description') ||
        lower.contains('"caption"') ||
        lower.contains('text_post_app_info') ||
        lower.contains('"text"')) {
      return true;
    }
    return false;
  }

  static bool _isSiteIcon(String url) {
    final lower = url.toLowerCase();
    return lower.contains('favicon') ||
        lower.contains('apple-touch-icon') ||
        lower.contains('threads-logo') ||
        lower.contains('/static/') && lower.contains('logo');
  }

  static bool _isProfileImage(String url) {
    final lower = url.toLowerCase();
    return lower.contains('t51.2885-19') ||
        lower.contains('/profile_pic') ||
        lower.contains('profile_picture');
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
        _jsonString(html, 'video_duration') ??
        _jsonString(html, 'duration');
    if (og == null) return null;
    return double.tryParse(og);
  }

  static String _indexedFileName(String fileName, int index) {
    final dot = fileName.lastIndexOf('.');
    if (dot <= 0) return '${fileName}_$index';
    return '${fileName.substring(0, dot)}_$index${fileName.substring(dot)}';
  }

  static DateTime? _publishedFromHtml(String html) {
    final numeric = RegExp(r'"taken_at"\s*:\s*(\d+)').firstMatch(html);
    if (numeric != null) {
      final seconds = int.tryParse(numeric.group(1)!);
      if (seconds != null && seconds > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      }
    }
    final takenAt = _jsonString(html, 'taken_at');
    if (takenAt != null) {
      final seconds = int.tryParse(takenAt);
      if (seconds != null && seconds > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      }
    }
    final published =
        _metaContent(html, 'article:published_time') ??
        _jsonString(html, 'datePublished');
    if (published == null) return null;
    return DateTime.tryParse(published);
  }

  static String? _quotedOrRepostedCode(String html) {
    final quoted = RegExp(
      r'"quoted_post"\s*:\s*\{[^{}]*"code"\s*:\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(html);
    if (quoted != null) return quoted.group(1);
    final reposted = RegExp(
      r'"reposted_post"\s*:\s*\{[^{}]*"code"\s*:\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(html);
    return reposted?.group(1);
  }

  static int? _intMeta(String html, String property) {
    final value = _metaContent(html, property);
    return value == null ? null : int.tryParse(value);
  }

  static int? _intFromNearby(String text, String field) {
    final match = RegExp(
      '"$field"\\s*:\\s*(\\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  static String _nearbyWindow(String html, int index) {
    final start = index - 200 < 0 ? 0 : index - 200;
    final end = index + 200 > html.length ? html.length : index + 200;
    return html.substring(start, end);
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
    cleaned = cleaned.replaceAll(RegExp(r'\s+[–\-|]\s+Threads$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+on Threads$'), '');
    return cleaned.isEmpty ? username : cleaned;
  }

  static String? _postScopedHtml(String html, String? postId) {
    if (postId == null || postId.isEmpty) return null;
    String? emptyRecord;
    var searchFrom = 0;
    while (searchFrom < html.length) {
      var idx = html.indexOf('"code":"$postId"', searchFrom);
      if (idx < 0) idx = html.indexOf('"code": "$postId"', searchFrom);
      if (idx < 0) break;
      final object = _jsonObjectWithMedia(html, idx);
      if (object != null && _objectHasDownloadableMedia(object)) {
        return object;
      }
      emptyRecord ??= object;
      searchFrom = idx + postId.length;
    }
    final near = _indexNearMedia(html, postId);
    if (near >= 0) {
      final object = _jsonObjectWithMedia(html, near);
      if (object != null && _objectHasDownloadableMedia(object)) {
        return object;
      }
      emptyRecord ??= object;
    }
    if (emptyRecord != null) return emptyRecord;
    final loose = html.indexOf('"$postId"');
    final idx = loose >= 0 ? loose : html.indexOf(postId);
    if (idx < 0) return null;
    return _windowAround(html, idx);
  }

  static String _windowAround(String html, int idx) {
    final start = idx - 30000 < 0 ? 0 : idx - 30000;
    final end = idx + 50000 > html.length ? html.length : idx + 50000;
    return html.substring(start, end);
  }

  /// True when a post object exposes a file URL, not an empty
  /// `image_versions2.candidates` / `video_versions: null` stub.
  static bool _objectHasDownloadableMedia(String object) {
    if (_videoVersionsArrayPattern.hasMatch(object)) return true;
    if (_carouselArrayPattern.hasMatch(object)) return true;
    return RegExp(r'"candidates"\s*:\s*\[\s*\{').hasMatch(object);
  }

  static String? _jsonObjectWithMedia(String html, int idx) {
    var searchFrom = idx;
    while (searchFrom >= 0) {
      final start = _objectStartBefore(html, searchFrom);
      if (start < 0) return null;
      final object = _balancedJsonObject(html, start);
      if (object == null) return null;
      if (_objectHasDownloadableMedia(object)) return object;
      final mentionsMedia = object.contains('image_versions2') ||
          object.contains('"video_versions"') ||
          object.contains('carousel_media');
      // Empty candidates belong to this post. Do not climb into a parent
      // that also contains other posts' media.
      if (mentionsMedia) return object;
      searchFrom = start - 1;
    }
    return null;
  }

  static int _objectStartBefore(String html, int idx) {
    var depth = 0;
    for (var i = idx; i >= 0; i--) {
      final ch = html[i];
      if (ch == '}') depth++;
      if (ch == '{') {
        if (depth == 0) return i;
        depth--;
      }
    }
    return -1;
  }

  static String? _balancedJsonObject(String html, int start) {
    if (start >= html.length || html[start] != '{') return null;
    var depth = 0;
    for (var i = start; i < html.length; i++) {
      final ch = html[i];
      if (ch == '{') depth++;
      if (ch == '}') {
        depth--;
        if (depth == 0) return html.substring(start, i + 1);
      }
    }
    return null;
  }

  static int _indexNearMedia(String html, String postId) {
    var searchFrom = 0;
    while (true) {
      final idx = html.indexOf(postId, searchFrom);
      if (idx < 0) return -1;
      final start = idx - 4000 < 0 ? 0 : idx - 4000;
      final end = idx + 8000 > html.length ? html.length : idx + 8000;
      final nearby = html.substring(start, end);
      if (_objectHasDownloadableMedia(nearby)) return idx;
      searchFrom = idx + postId.length;
    }
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

  static String _identityUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return url;
    return '${uri.host}${uri.path}';
  }

  static String? _balancedJsonArray(String html, int start) {
    if (start >= html.length || html[start] != '[') return null;
    var depth = 0;
    for (var i = start; i < html.length; i++) {
      final ch = html[i];
      if (ch == '[') depth++;
      if (ch == ']') {
        depth--;
        if (depth == 0) return html.substring(start, i + 1);
      }
    }
    return null;
  }
}

enum ThreadsHtmlStatus {
  ok,
  restricted,
  authenticationRequired,
  unavailable,
}

enum ThreadsAccess {
  public,
  restricted,
  authenticationRequired,
  unavailable,
}

enum ThreadsMediaType {
  text,
  image,
  video,
  carousel,
  multiMedia,
  hlsOnly,
  unknown,
}

enum ThreadsPostKind { original, quote, repost, textOnly }

class ThreadsMediaItem {
  const ThreadsMediaItem({
    required this.url,
    required this.mediaType,
    required this.mimeType,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
  });

  final String url;
  final ThreadsMediaType mediaType;
  final String mimeType;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
}

class ThreadsPostInfo {
  const ThreadsPostInfo({
    this.postId,
    this.originalPostId,
    this.username,
    this.author,
    this.authorId,
    this.title,
    this.caption,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.canonicalUrl,
    this.publishedAt,
    this.postKind = ThreadsPostKind.original,
    this.mediaType = ThreadsMediaType.unknown,
  });

  final String? postId;
  final String? originalPostId;
  final String? username;
  final String? author;
  final String? authorId;
  final String? title;
  final String? caption;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final String? canonicalUrl;
  final DateTime? publishedAt;
  final ThreadsPostKind postKind;
  final ThreadsMediaType mediaType;
}

class ThreadsProfileInfo {
  const ThreadsProfileInfo({
    this.username,
    this.displayName,
    this.description,
    this.thumbnailUrl,
  });

  final String? username;
  final String? displayName;
  final String? description;
  final String? thumbnailUrl;
}
