import 'dart:convert';

import 'package:dio/dio.dart';

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_url_resolver.dart';
import 'social_url_utils.dart';

/// Resolves Reddit post URLs via the public JSON API and HTML fallbacks.
///
/// Supports:
/// - Video posts (`reddit_video` / `v.redd.it`)
/// - Image posts (`i.redd.it`, PNG/JPG/WebP)
/// - GIF / GIF-like posts (preserves actual MIME — GIF vs MP4)
/// - Gallery / multi-image posts (`gallery_data` + `media_metadata`)
/// - Mixed-media galleries
/// - Direct media CDN URLs
/// - Short (`redd.it/<id>`) and share (`/r/<sub>/s/<id>`) URLs
/// - Link posts to other supported platforms (YouTube, Vimeo, TikTok, …)
typedef ResolveLinkedPage = Future<List<DiscoveredResource>> Function(Uri uri);

class RedditResolver {
  RedditResolver({
    Dio? dio,
    ResolveLinkedPage? resolveLinkedPage,
  })  : _dio = dio ?? Dio(),
        _urlResolver = SocialUrlResolver(dio: dio),
        _resolveLinkedPage = resolveLinkedPage;

  final Dio _dio;
  final SocialUrlResolver _urlResolver;
  final ResolveLinkedPage? _resolveLinkedPage;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  /// Returns every downloadable media item for a Reddit URL.
  /// Galleries preserve `gallery_data.items` order.
  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    var resolved = RedditUri.normalize(pageUrl);
    final type = RedditUri.classifyUrl(resolved);

    if (!RedditUri.isDownloadable(resolved) &&
        type != RedditContentType.share) {
      return const [];
    }

    if (type == RedditContentType.directMedia) {
      return [_directMediaResource(resolved, pageUrl)];
    }

    if (type == RedditContentType.share ||
        (type == RedditContentType.short &&
            RedditUri.postIdFromUri(resolved) == null)) {
      resolved = RedditUri.normalize(
        await _urlResolver.resolveRedirects(pageUrl),
      );
      if (!RedditUri.isDownloadable(resolved)) return const [];
      if (RedditUri.classifyUrl(resolved) == RedditContentType.directMedia) {
        return [_directMediaResource(resolved, pageUrl)];
      }
    }

    final jsonUrl = RedditUri.jsonEndpoint(resolved);
    if (jsonUrl != null) {
      final payload = await _fetchJsonPayload(jsonUrl, pageUrl);
      if (payload != null) {
        final fromJson = parseAllMedia(pageUrl: pageUrl, payload: payload);
        if (fromJson.isNotEmpty) return fromJson;

        final linked = linkedUrlFromPayload(payload);
        final follow = _resolveLinkedPage;
        if (linked != null && follow != null) {
          return follow(linked);
        }
      }
    }

    final html = await _fetchHtml(resolved);
    if (html == null || html.isEmpty) return const [];

    final embedded = _extractFromEmbeddedJson(html);
    if (embedded != null && !_isPlaylistUrl(embedded)) {
      return [
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: embedded,
          title: null,
          fallbackSlug: RedditUri.postIdFromUri(resolved) ??
              _slugFromPath(pageUrl),
          mimeType: mimeFromUrl(embedded),
          thumbnailUrl: null,
        ),
      ];
    }

    return const [];
  }

  /// Classifies a Reddit URL — exposed for tests.
  static RedditContentType classifyUrl(Uri uri) => RedditUri.classifyUrl(uri);

  static Uri? jsonEndpoint(Uri pageUrl) => RedditUri.jsonEndpoint(pageUrl);

  /// Parses Reddit post JSON — exposed for unit tests (first media item).
  static DiscoveredResource? parsePostJson({
    required Uri pageUrl,
    required List<dynamic> payload,
  }) {
    final all = parseAllMedia(pageUrl: pageUrl, payload: payload);
    return all.isEmpty ? null : all.first;
  }

  /// Parses every media item from Reddit post JSON — exposed for unit tests.
  static List<DiscoveredResource> parseAllMedia({
    required Uri pageUrl,
    required List<dynamic> payload,
  }) {
    final postData = postDataFromPayload(payload);
    if (postData == null) return const [];
    return _resourcesFromPost(postData: postData, pageUrl: pageUrl);
  }

  /// Extracts structured post metadata — exposed for unit tests.
  static RedditPostInfo? parsePostInfo({
    required List<dynamic> payload,
  }) {
    final postData = postDataFromPayload(payload);
    if (postData == null) return null;
    return RedditPostInfo.fromPostData(postData);
  }

  /// Off-platform URL from a Reddit link post (YouTube, Vimeo, TikTok, …).
  /// Returns null for Reddit-hosted media and unsupported hosts.
  static Uri? linkedUrlFromPayload(List<dynamic> payload) {
    final postData = postDataFromPayload(payload);
    if (postData == null) return null;
    return linkedUrlFromPost(_unwrapCrosspost(postData));
  }

  static Uri? linkedUrlFromPost(Map<dynamic, dynamic> postData) {
    final raw = postData['url_overridden_by_dest'] ?? postData['url'];
    if (raw is! String || !raw.startsWith('http')) return null;
    final uri = Uri.tryParse(_unescapeUrl(raw));
    if (uri == null) return null;
    final platform = SocialPlatform.fromUri(uri);
    if (platform == null || platform == SocialPlatform.reddit) return null;
    return uri;
  }

  static Map<dynamic, dynamic>? postDataFromPayload(List<dynamic> payload) {
    if (payload.isEmpty) return null;
    final postListing = payload.first;
    if (postListing is! Map) return null;
    final listingData = postListing['data'];
    if (listingData is! Map) return null;
    final children = listingData['children'];
    if (children is! List || children.isEmpty) return null;
    final post = children.first;
    if (post is! Map) return null;
    final postData = post['data'];
    if (postData is! Map) return null;
    return postData;
  }

  /// Derives the separate Reddit audio stream URL when video/audio are split.
  /// Returns null when the video has no audio (`is_gif` or `has_audio != true`).
  static String? audioStreamUrlFromVideo(Map<dynamic, dynamic> redditVideo) {
    if (redditVideo['is_gif'] == true) return null;
    if (redditVideo['has_audio'] != true) return null;
    final fallback = redditVideo['fallback_url'];
    if (fallback is! String || !fallback.startsWith('http')) return null;
    final uri = Uri.tryParse(fallback);
    if (uri == null || uri.pathSegments.isEmpty) return null;
    final id = uri.pathSegments.first;
    if (id.isEmpty) return null;
    return '${uri.scheme}://${uri.host}/$id/DASH_audio.mp4';
  }

  static bool hasSeparateAudio(Map<dynamic, dynamic> redditVideo) =>
      audioStreamUrlFromVideo(redditVideo) != null;

  static String mimeFromUrl(String url) {
    final path = (Uri.tryParse(url)?.path ?? url).toLowerCase();
    if (path.endsWith('.png')) return 'image/png';
    if (path.endsWith('.webp')) return 'image/webp';
    if (path.endsWith('.gif')) return 'image/gif';
    if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
    if (path.endsWith('.webm')) return 'video/webm';
    if (path.endsWith('.mp4') || path.contains('/dash_')) return 'video/mp4';
    return 'application/octet-stream';
  }

  static String normalizeMime(String? raw, {String? fallbackUrl}) {
    if (raw != null && raw.isNotEmpty) {
      final base = raw.split(';').first.trim().toLowerCase();
      if (base == 'image/jpg') return 'image/jpeg';
      return base;
    }
    if (fallbackUrl != null) return mimeFromUrl(fallbackUrl);
    return 'application/octet-stream';
  }

  // ─── JSON fetch ──────────────────────────────────────────────────────

  Future<List<dynamic>?> _fetchJsonPayload(
    Uri jsonUrl,
    Uri pageUrl,
  ) async {
    try {
      final endpoint = jsonUrl.replace(
        queryParameters: {
          ...jsonUrl.queryParameters,
          'raw_json': '1',
        },
      );
      final response = await _dio.get<dynamic>(
        endpoint.toString(),
        options: Options(
          responseType: ResponseType.json,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: {
            ...SocialHttpHeaders.forPageFetch(pageUrl, SocialPlatform.reddit),
            'Accept': 'application/json',
          },
        ),
      );

      final data = response.data;
      if (data is List) return data;
      return null;
    } on DioException {
      return null;
    } on FormatException {
      return null;
    }
  }

  Future<String?> _fetchHtml(Uri pageUrl) async {
    try {
      final response = await _dio.get<String>(
        pageUrl.toString(),
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 400,
          headers: SocialHttpHeaders.forPageFetch(
            pageUrl,
            SocialPlatform.reddit,
          ),
        ),
      );
      return response.data;
    } on DioException {
      return null;
    }
  }

  // ─── Post parsing ────────────────────────────────────────────────────

  static List<DiscoveredResource> _resourcesFromPost({
    required Map<dynamic, dynamic> postData,
    required Uri pageUrl,
  }) {
    final source = _unwrapCrosspost(postData);
    if (_isUnavailable(source) && !_hasAnyMedia(source)) {
      return const [];
    }

    final title = source['title']?.toString();
    final postId = source['id']?.toString() ?? RedditUri.postIdFromUri(pageUrl);
    final thumbnail = _thumbnailFromPost(source);

    if (source['is_gallery'] == true || source['gallery_data'] != null) {
      final gallery = _parseGallery(
        postData: source,
        pageUrl: pageUrl,
        title: title,
        postId: postId,
        thumbnailUrl: thumbnail,
      );
      if (gallery.isNotEmpty) return gallery;
    }

    final video = _parseRedditVideo(
      postData: source,
      pageUrl: pageUrl,
      title: title,
      postId: postId,
      thumbnailUrl: thumbnail,
    );
    if (video != null) return [video];

    final preview = _parsePreviewMedia(
      postData: source,
      pageUrl: pageUrl,
      title: title,
      postId: postId,
      thumbnailUrl: thumbnail,
    );
    if (preview != null) return [preview];

    final url = source['url_overridden_by_dest'] ?? source['url'];
    if (url is String) {
      final direct = _resourceFromDirectUrl(
        url: url,
        pageUrl: pageUrl,
        title: title,
        postId: postId,
        thumbnailUrl: thumbnail,
      );
      if (direct != null) return [direct];
    }

    return const [];
  }

  static Map<dynamic, dynamic> _unwrapCrosspost(Map<dynamic, dynamic> post) {
    final parents = post['crosspost_parent_list'];
    if (parents is List && parents.isNotEmpty && parents.first is Map) {
      return parents.first as Map<dynamic, dynamic>;
    }
    return post;
  }

  static bool _isUnavailable(Map<dynamic, dynamic> post) {
    final removed = post['removed_by_category'];
    if (removed is String && removed.isNotEmpty) return true;
    final author = post['author']?.toString();
    if (author == '[deleted]') return true;
    return false;
  }

  static bool _hasAnyMedia(Map<dynamic, dynamic> post) {
    return post['is_video'] == true ||
        post['is_gallery'] == true ||
        post['media'] != null ||
        post['secure_media'] != null ||
        post['gallery_data'] != null ||
        post['media_metadata'] != null;
  }

  static DiscoveredResource? _parseRedditVideo({
    required Map<dynamic, dynamic> postData,
    required Uri pageUrl,
    required String? title,
    required String? postId,
    required String? thumbnailUrl,
  }) {
    final redditVideo = postData['secure_media']?['reddit_video'] ??
        postData['media']?['reddit_video'];
    if (redditVideo is! Map) return null;

    final mediaUrl = _mp4UrlFromRedditVideo(redditVideo);
    if (mediaUrl == null) return null;

    return _buildResource(
      pageUrl: pageUrl,
      mediaUrl: mediaUrl,
      title: title,
      fallbackSlug: postId,
      mimeType: 'video/mp4',
      thumbnailUrl: thumbnailUrl,
    );
  }

  static String? _mp4UrlFromRedditVideo(Map<dynamic, dynamic> redditVideo) {
    final fallback = redditVideo['fallback_url'];
    if (fallback is String &&
        fallback.startsWith('http') &&
        !_isPlaylistUrl(fallback)) {
      return fallback;
    }
    return null;
  }

  static List<DiscoveredResource> _parseGallery({
    required Map<dynamic, dynamic> postData,
    required Uri pageUrl,
    required String? title,
    required String? postId,
    required String? thumbnailUrl,
  }) {
    final galleryData = postData['gallery_data'];
    final metadata = postData['media_metadata'];
    if (galleryData is! Map || metadata is! Map) return const [];

    final items = galleryData['items'];
    if (items is! List || items.isEmpty) return const [];

    final resources = <DiscoveredResource>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item is! Map) continue;
      final mediaId = item['media_id']?.toString();
      if (mediaId == null) continue;
      final meta = metadata[mediaId];
      if (meta is! Map) continue;

      final parsed = _parseMediaMetadata(meta);
      if (parsed == null) continue;

      final indexLabel = '${i + 1}';
      resources.add(
        _buildResource(
          pageUrl: pageUrl,
          mediaUrl: parsed.url,
          title: title == null ? null : '${title}_$indexLabel',
          fallbackSlug: postId == null ? indexLabel : '${postId}_$indexLabel',
          mimeType: parsed.mimeType,
          thumbnailUrl: parsed.previewUrl ?? thumbnailUrl,
        ),
      );
    }
    return resources;
  }

  static _ParsedMedia? _parseMediaMetadata(Map<dynamic, dynamic> meta) {
    final kind = meta['e']?.toString();
    final declaredMime = normalizeMime(meta['m']?.toString());
    final source = meta['s'];
    if (source is! Map) return null;

    if (kind == 'AnimatedImage') {
      final gif = source['gif']?.toString();
      final mp4 = source['mp4']?.toString();
      if (gif != null && gif.startsWith('http') && declaredMime == 'image/gif') {
        return _ParsedMedia(
          url: _unescapeUrl(gif),
          mimeType: 'image/gif',
          previewUrl: _previewFromMetadata(meta),
        );
      }
      if (mp4 != null && mp4.startsWith('http')) {
        return _ParsedMedia(
          url: _unescapeUrl(mp4),
          mimeType: 'video/mp4',
          previewUrl: _previewFromMetadata(meta),
        );
      }
      if (gif != null && gif.startsWith('http')) {
        return _ParsedMedia(
          url: _unescapeUrl(gif),
          mimeType: 'image/gif',
          previewUrl: _previewFromMetadata(meta),
        );
      }
    }

    if (kind == 'RedditVideo') {
      final dash = source['dashUrl'] ?? source['fallback_url'] ?? source['u'];
      if (dash is String && dash.startsWith('http') && !_isPlaylistUrl(dash)) {
        return _ParsedMedia(
          url: _unescapeUrl(dash),
          mimeType: 'video/mp4',
          previewUrl: _previewFromMetadata(meta),
        );
      }
    }

    final url = source['u'] ?? source['gif'] ?? source['mp4'];
    if (url is! String || !url.startsWith('http')) return null;
    final unescaped = _unescapeUrl(url);
    return _ParsedMedia(
      url: unescaped,
      mimeType: normalizeMime(declaredMime, fallbackUrl: unescaped),
      previewUrl: _previewFromMetadata(meta),
    );
  }

  static String? _previewFromMetadata(Map<dynamic, dynamic> meta) {
    final previews = meta['p'];
    if (previews is List && previews.isNotEmpty) {
      final last = previews.last;
      if (last is Map) {
        final url = last['u']?.toString();
        if (url != null && url.startsWith('http')) return _unescapeUrl(url);
      }
    }
    final source = meta['s'];
    if (source is Map) {
      final url = source['u']?.toString();
      if (url != null && url.startsWith('http')) return _unescapeUrl(url);
    }
    return null;
  }

  static DiscoveredResource? _parsePreviewMedia({
    required Map<dynamic, dynamic> postData,
    required Uri pageUrl,
    required String? title,
    required String? postId,
    required String? thumbnailUrl,
  }) {
    final preview = postData['preview'];
    if (preview is! Map) return null;
    final images = preview['images'];
    if (images is! List || images.isEmpty) return null;
    final first = images.first;
    if (first is! Map) return null;

    final variants = first['variants'];
    if (variants is Map) {
      final gifVariant = variants['gif'];
      final mp4Variant = variants['mp4'];
      final postUrl = postData['url']?.toString() ?? '';

      if (postUrl.toLowerCase().endsWith('.gif') && gifVariant is Map) {
        final gifUrl = gifVariant['source']?['url']?.toString();
        if (gifUrl != null && gifUrl.startsWith('http')) {
          return _buildResource(
            pageUrl: pageUrl,
            mediaUrl: _unescapeUrl(gifUrl),
            title: title,
            fallbackSlug: postId,
            mimeType: 'image/gif',
            thumbnailUrl: thumbnailUrl,
          );
        }
      }

      if (mp4Variant is Map && !postUrl.toLowerCase().endsWith('.gif')) {
        final mp4Url = mp4Variant['source']?['url']?.toString();
        if (mp4Url != null && mp4Url.startsWith('http')) {
          return _buildResource(
            pageUrl: pageUrl,
            mediaUrl: _unescapeUrl(mp4Url),
            title: title,
            fallbackSlug: postId,
            mimeType: 'video/mp4',
            thumbnailUrl: thumbnailUrl,
          );
        }
      }
    }

    return null;
  }

  static DiscoveredResource? _resourceFromDirectUrl({
    required String url,
    required Uri pageUrl,
    required String? title,
    required String? postId,
    required String? thumbnailUrl,
  }) {
    if (!url.startsWith('http')) return null;
    if (_isPlaylistUrl(url)) return null;
    if (!_isDirectlyDownloadableUrl(url)) return null;

    final mime = mimeFromUrl(url);
    if (mime == 'application/octet-stream') return null;

    return _buildResource(
      pageUrl: pageUrl,
      mediaUrl: _unescapeUrl(url),
      title: title,
      fallbackSlug: postId,
      mimeType: mime,
      thumbnailUrl: thumbnailUrl ?? (mime.startsWith('image/') ? url : null),
    );
  }

  static bool _isDirectlyDownloadableUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return false;
    final host = uri.host.toLowerCase();
    if (host == 'i.redd.it' ||
        host == 'v.redd.it' ||
        host == 'preview.redd.it' ||
        host == 'i.imgur.com') {
      return true;
    }
    final path = uri.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.endsWith('.gif') ||
        path.endsWith('.mp4') ||
        path.endsWith('.webm');
  }

  static String? _thumbnailFromPost(Map<dynamic, dynamic> post) {
    final preview = post['preview'];
    if (preview is Map) {
      final images = preview['images'];
      if (images is List && images.isNotEmpty && images.first is Map) {
        final source = (images.first as Map)['source'];
        if (source is Map) {
          final url = source['url']?.toString();
          if (url != null && url.startsWith('http')) return _unescapeUrl(url);
        }
      }
    }
    final thumb = post['thumbnail']?.toString();
    if (thumb != null &&
        thumb.startsWith('http') &&
        thumb != 'self' &&
        thumb != 'default' &&
        thumb != 'nsfw' &&
        thumb != 'spoiler') {
      return thumb;
    }
    return null;
  }

  static DiscoveredResource _directMediaResource(Uri mediaUrl, Uri pageUrl) {
    final mime = mimeFromUrl(mediaUrl.toString());
    final resolvedMime = mime == 'application/octet-stream' &&
            mediaUrl.host.toLowerCase() == 'v.redd.it'
        ? 'video/mp4'
        : mime;
    return _buildResource(
      pageUrl: pageUrl,
      mediaUrl: mediaUrl.toString(),
      title: null,
      fallbackSlug: RedditUri.postIdFromUri(mediaUrl) ?? _slugFromPath(pageUrl),
      mimeType: resolvedMime,
      thumbnailUrl:
          resolvedMime.startsWith('image/') ? mediaUrl.toString() : null,
    );
  }

  static DiscoveredResource _buildResource({
    required Uri pageUrl,
    required String mediaUrl,
    required String? title,
    required String? fallbackSlug,
    required String mimeType,
    required String? thumbnailUrl,
  }) {
    return DiscoveredResource(
      directUrl: mediaUrl,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.reddit,
        mediaUrl: mediaUrl,
        title: title,
        fallbackSlug: fallbackSlug ?? _slugFromPath(pageUrl),
        mimeHint: mimeType,
      ),
      platform: SocialPlatform.reddit.label,
      pageUrl: pageUrl.toString(),
      title: title,
      mimeType: mimeType,
      thumbnailUrl: thumbnailUrl,
      kind: DiscoveredResourceKind.fromMime(mimeType),
    );
  }

  static String? _extractFromEmbeddedJson(String html) {
    final pattern = RegExp(r'"fallback_url":"([^"]+)"');
    final match = pattern.firstMatch(html);
    if (match != null) {
      final url = _unescapeUrl(match.group(1)!);
      if (!_isPlaylistUrl(url)) return url;
    }

    final scriptPattern = RegExp(
      r'<script[^>]*type="application/json"[^>]*>(\{.*?\})</script>',
      dotAll: true,
    );
    for (final match in scriptPattern.allMatches(html)) {
      try {
        final decoded = jsonDecode(match.group(1)!);
        final url = _findFallbackUrl(decoded);
        if (url != null) return url;
      } on Object {
        continue;
      }
    }

    final imageMatch = RegExp(
      r'https://i\.redd\.it/[^\s"\\]+',
    ).firstMatch(html);
    return imageMatch?.group(0);
  }

  static String? _findFallbackUrl(Object? node) {
    if (node is Map) {
      final fallback = node['fallback_url'];
      if (fallback is String &&
          fallback.startsWith('http') &&
          !_isPlaylistUrl(fallback)) {
        return fallback;
      }
      for (final value in node.values) {
        final found = _findFallbackUrl(value);
        if (found != null) return found;
      }
    } else if (node is List) {
      for (final item in node) {
        final found = _findFallbackUrl(item);
        if (found != null) return found;
      }
    }
    return null;
  }

  static bool _isPlaylistUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('.m3u8') || lower.contains('.mpd');
  }

  static String _unescapeUrl(String raw) => raw
      .replaceAll('&amp;', '&')
      .replaceAll(r'\/', '/')
      .replaceAll(r'\u0026', '&')
      .replaceAll(r'\u002F', '/');

  static String? _slugFromPath(Uri uri) {
    final segments = uri.pathSegments.where((segment) => segment.isNotEmpty);
    return segments.isEmpty ? null : segments.last;
  }
}

class _ParsedMedia {
  const _ParsedMedia({
    required this.url,
    required this.mimeType,
    this.previewUrl,
  });

  final String url;
  final String mimeType;
  final String? previewUrl;
}

/// Structured Reddit post metadata extracted from the public JSON API.
class RedditPostInfo {
  const RedditPostInfo({
    required this.postId,
    this.subreddit,
    this.author,
    this.title,
    this.selftext,
    this.permalink,
    this.thumbnailUrl,
    this.isVideo = false,
    this.isGallery = false,
    this.isGif = false,
    this.hasAudio,
    this.durationSeconds,
    this.width,
    this.height,
    this.removedByCategory,
    this.galleryCount = 0,
  });

  final String postId;
  final String? subreddit;
  final String? author;
  final String? title;
  final String? selftext;
  final String? permalink;
  final String? thumbnailUrl;
  final bool isVideo;
  final bool isGallery;
  final bool isGif;
  final bool? hasAudio;
  final int? durationSeconds;
  final int? width;
  final int? height;
  final String? removedByCategory;
  final int galleryCount;

  bool get isRemoved =>
      removedByCategory != null && removedByCategory!.isNotEmpty;

  factory RedditPostInfo.fromPostData(Map<dynamic, dynamic> post) {
    final redditVideo = post['secure_media']?['reddit_video'] ??
        post['media']?['reddit_video'];
    final video = redditVideo is Map ? redditVideo : null;
    final galleryItems = post['gallery_data'] is Map
        ? (post['gallery_data'] as Map)['items']
        : null;
    final thumbnail = post['thumbnail']?.toString();

    return RedditPostInfo(
      postId: post['id']?.toString() ?? '',
      subreddit: post['subreddit']?.toString(),
      author: post['author']?.toString(),
      title: post['title']?.toString(),
      selftext: post['selftext']?.toString(),
      permalink: post['permalink']?.toString(),
      thumbnailUrl:
          thumbnail != null && thumbnail.startsWith('http') ? thumbnail : null,
      isVideo: post['is_video'] == true,
      isGallery: post['is_gallery'] == true || galleryItems is List,
      isGif: video?['is_gif'] == true,
      hasAudio: video == null ? null : video['has_audio'] == true,
      durationSeconds: video?['duration'] is num
          ? (video!['duration'] as num).toInt()
          : null,
      width: video?['width'] is num ? (video!['width'] as num).toInt() : null,
      height:
          video?['height'] is num ? (video!['height'] as num).toInt() : null,
      removedByCategory: post['removed_by_category']?.toString(),
      galleryCount: galleryItems is List ? galleryItems.length : 0,
    );
  }
}
