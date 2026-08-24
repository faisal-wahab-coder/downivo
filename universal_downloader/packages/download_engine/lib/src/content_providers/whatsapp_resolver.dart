import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

import 'media_extractor.dart';
import 'models/discovered_resource.dart';
import 'social_http_headers.dart';
import 'social_platform.dart';
import 'social_session_utils.dart';
import 'social_url_utils.dart';

/// Resolves publicly accessible WhatsApp URLs and classifies user-shared files.
///
/// Supports:
/// - `wa.me` / `api.whatsapp.com` click-to-chat (classified, not downloaded)
/// - Group invitations (`chat.whatsapp.com`) — classified, never joined
/// - Public Channel pages that expose Open Graph media
/// - User-exported files (image, video, audio, voice note, PDF, document,
///   archive, vCard) through the existing File Import / Share pipeline
///
/// Private chats, WhatsApp Web sessions, encrypted media gateways
/// (`mmg.whatsapp.net`), disappearing messages, and authentication bypass
/// are never attempted.
class WhatsAppResolver {
  WhatsAppResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<DiscoveredResource?> discover(Uri pageUrl) async {
    final all = await discoverAll(pageUrl);
    return all.isEmpty ? null : all.first;
  }

  Future<List<DiscoveredResource>> discoverAll(Uri pageUrl) async {
    final type = WhatsAppUri.classifyUrl(pageUrl);
    if (WhatsAppUri.isRestricted(pageUrl)) return const [];
    if (WhatsAppUri.requiresAuthentication(pageUrl)) return const [];
    if (!WhatsAppUri.isDownloadable(pageUrl) &&
        type != WhatsAppContentType.directMedia) {
      return const [];
    }

    if (type == WhatsAppContentType.directMedia ||
        WhatsAppUri.isPublicMediaHost(pageUrl.host)) {
      if (!isDirectMediaUrl(pageUrl.toString())) return const [];
      return [_directMediaResource(pageUrl, pageUrl)];
    }

    final resolved = WhatsAppUri.normalize(pageUrl);
    if (!WhatsAppUri.isDownloadable(resolved)) return const [];

    final contentId = WhatsAppUri.contentIdentity(resolved);
    String? lastBadHtml;
    String? lastOkHtml;
    var sawOkHtml = false;

    for (final target in WhatsAppUri.fetchTargets(resolved)) {
      final html = await _fetchHtml(target);
      if (html == null || html.isEmpty) continue;
      final status = classifyHtml(html);
      if (status != WhatsAppHtmlStatus.ok) {
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

  static WhatsAppContentType classifyUrl(Uri uri) =>
      WhatsAppUri.classifyUrl(uri);

  /// Public Channel HTML status. Never treats a login wall or private chat
  /// as media.
  static WhatsAppHtmlStatus classifyHtml(String html) {
    if (html.trim().isEmpty) return WhatsAppHtmlStatus.unavailable;
    final lower = html.toLowerCase();
    if (lower.contains('this chat is private') ||
        lower.contains('this group is private') ||
        lower.contains('end-to-end encrypted') &&
            lower.contains('you need to open whatsapp') ||
        lower.contains('join this group in whatsapp')) {
      return WhatsAppHtmlStatus.restricted;
    }
    if (lower.contains('log in to whatsapp') ||
        lower.contains('scan the qr code') ||
        lower.contains('keep your phone connected') ||
        lower.contains('id="login-form"')) {
      return WhatsAppHtmlStatus.authenticationRequired;
    }
    if (lower.contains('this message has disappeared') ||
        lower.contains('view once') && lower.contains('no longer available') ||
        lower.contains('this content is no longer available') ||
        lower.contains('this channel is no longer available')) {
      return WhatsAppHtmlStatus.unavailable;
    }
    return WhatsAppHtmlStatus.ok;
  }

  static WhatsAppAccess accessFor(Uri uri, {String? html}) {
    if (WhatsAppUri.requiresAuthentication(uri)) {
      return WhatsAppAccess.authenticationRequired;
    }
    if (WhatsAppUri.isRestricted(uri)) {
      return WhatsAppAccess.restricted;
    }
    if (html != null) {
      return switch (classifyHtml(html)) {
        WhatsAppHtmlStatus.restricted => WhatsAppAccess.restricted,
        WhatsAppHtmlStatus.authenticationRequired =>
          WhatsAppAccess.authenticationRequired,
        WhatsAppHtmlStatus.unavailable => WhatsAppAccess.unavailable,
        WhatsAppHtmlStatus.ok => WhatsAppAccess.public,
      };
    }
    return WhatsAppAccess.public;
  }

  /// Parses downloadable media from a public WhatsApp Channel page.
  static List<DiscoveredResource> parseHtmlResources({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    if (html.trim().isEmpty) return const [];
    if (classifyHtml(html) != WhatsAppHtmlStatus.ok) return const [];

    final info = parseChannelInfo(
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
  static List<WhatsAppMediaItem> parseMediaItems(String html) {
    final items = <WhatsAppMediaItem>[];
    final seen = <String>{};

    void add(WhatsAppMediaItem item) {
      if (item.url.isEmpty || !isDirectMediaUrl(item.url)) return;
      if (!seen.add(item.url)) return;
      items.add(item);
    }

    final ogVideo =
        _metaContent(html, 'og:video') ??
        _metaContent(html, 'og:video:url') ??
        _metaContent(html, 'og:video:secure_url');
    if (ogVideo != null) {
      add(
        WhatsAppMediaItem(
          url: ogVideo,
          mediaType: WhatsAppMediaType.video,
          mimeType: mimeFromUrl(ogVideo, hint: 'video/mp4'),
          thumbnailUrl: _bestThumbnail(html),
          durationSeconds: _durationFromHtml(html),
          width: _intMeta(html, 'og:video:width'),
          height: _intMeta(html, 'og:video:height'),
        ),
      );
    }

    if (items.isEmpty) {
      final ogImage =
          _metaContent(html, 'og:image') ??
          _metaContent(html, 'og:image:url') ??
          _metaContent(html, 'og:image:secure_url');
      if (ogImage != null && !_isSiteIcon(ogImage)) {
        add(
          WhatsAppMediaItem(
            url: ogImage,
            mediaType: WhatsAppMediaType.image,
            mimeType: mimeFromUrl(ogImage, hint: 'image/jpeg'),
            width: _intMeta(html, 'og:image:width'),
            height: _intMeta(html, 'og:image:height'),
          ),
        );
      }
    }

    return items;
  }

  static WhatsAppChannelInfo parseChannelInfo({
    required String html,
    required Uri pageUrl,
    String? contentId,
  }) {
    final channelId = WhatsAppUri.channelIdFromUri(pageUrl);
    final postId = WhatsAppUri.channelPostIdFromUri(pageUrl);
    final title = _cleanTitle(
      _metaContent(html, 'og:title') ?? _metaContent(html, 'twitter:title'),
    );
    final description =
        _metaContent(html, 'og:description') ??
        _metaContent(html, 'twitter:description');
    return WhatsAppChannelInfo(
      contentId: contentId ?? WhatsAppUri.contentIdentity(pageUrl),
      channelId: channelId,
      postId: postId,
      title: title,
      description: description,
      thumbnailUrl: _bestThumbnail(html),
      durationSeconds: _durationFromHtml(html),
      width:
          _intMeta(html, 'og:image:width') ?? _intMeta(html, 'og:video:width'),
      height:
          _intMeta(html, 'og:image:height') ??
          _intMeta(html, 'og:video:height'),
      mediaType: detectMediaType(html),
      canonicalUrl: WhatsAppUri.normalize(pageUrl).toString(),
    );
  }

  static WhatsAppMediaType detectMediaType(String html) {
    final items = parseMediaItems(html);
    if (items.length == 1) return items.first.mediaType;
    if (items.length > 1) return WhatsAppMediaType.unknown;
    final description = _metaContent(html, 'og:description');
    if (description != null && description.trim().isNotEmpty) {
      return WhatsAppMediaType.text;
    }
    return WhatsAppMediaType.unknown;
  }

  /// Classifies a user-exported WhatsApp file from filename + MIME.
  /// Does not inspect file bytes and does not convert formats.
  static WhatsAppMediaType classifyImportedFile({
    required String fileName,
    String? mimeType,
  }) {
    final name = fileName.toLowerCase();
    final mime = (mimeType ?? '').toLowerCase().split(';').first.trim();
    final ext = p.extension(name);

    if (mime == 'text/vcard' ||
        mime == 'text/x-vcard' ||
        ext == '.vcf' ||
        ext == '.vcard') {
      return WhatsAppMediaType.contact;
    }
    if (mime == 'application/pdf' || ext == '.pdf') {
      return WhatsAppMediaType.pdf;
    }
    if (mime.contains('zip') ||
        mime.contains('x-rar') ||
        mime.contains('x-7z') ||
        mime.contains('x-tar') ||
        mime.contains('gzip') ||
        ext == '.zip' ||
        ext == '.rar' ||
        ext == '.7z' ||
        ext == '.tar' ||
        ext == '.gz') {
      return WhatsAppMediaType.archive;
    }
    if (mime.startsWith('image/') ||
        ext == '.jpg' ||
        ext == '.jpeg' ||
        ext == '.png' ||
        ext == '.gif' ||
        ext == '.webp' ||
        name.startsWith('img-')) {
      return WhatsAppMediaType.image;
    }
    if (mime.startsWith('video/') ||
        ext == '.mp4' ||
        ext == '.mov' ||
        ext == '.mkv' ||
        ext == '.webm' ||
        ext == '.3gp' ||
        name.startsWith('vid-')) {
      return WhatsAppMediaType.video;
    }
    if (_isVoiceNote(name, mime, ext)) {
      return WhatsAppMediaType.voiceNote;
    }
    if (mime.startsWith('audio/') ||
        ext == '.mp3' ||
        ext == '.m4a' ||
        ext == '.aac' ||
        ext == '.wav' ||
        ext == '.flac' ||
        name.startsWith('aud-')) {
      return WhatsAppMediaType.audio;
    }
    if (ext == '.txt' || mime == 'text/plain') {
      return WhatsAppMediaType.text;
    }
    if (ext == '.doc' ||
        ext == '.docx' ||
        ext == '.xls' ||
        ext == '.xlsx' ||
        ext == '.ppt' ||
        ext == '.pptx' ||
        ext == '.csv' ||
        mime.contains('msword') ||
        mime.contains('officedocument') ||
        mime.contains('ms-excel') ||
        mime.contains('ms-powerpoint') ||
        mime == 'text/csv') {
      return WhatsAppMediaType.document;
    }
    return WhatsAppMediaType.unknown;
  }

  static bool _isVoiceNote(String name, String mime, String ext) {
    if (name.startsWith('ptt-') || name.contains('ptt-')) return true;
    if (name.contains('voice') || name.contains('voicenote')) return true;
    if (ext == '.opus' || ext == '.oga') return true;
    if (mime == 'audio/opus' || mime == 'audio/ogg' || mime == 'audio/ogg;') {
      return true;
    }
    if (mime.startsWith('audio/ogg')) return true;
    if (ext == '.ogg') return true;
    return false;
  }

  static String mimeFromUrl(String url, {String? hint}) {
    final lower = url.toLowerCase();
    if (lower.contains('.m3u8') || lower.contains('.mpd')) {
      return 'application/vnd.apple.mpegurl';
    }
    if (lower.contains('.mp4') || lower.contains('.m4v')) return 'video/mp4';
    if (lower.contains('.webm')) return 'video/webm';
    if (lower.contains('.mov')) return 'video/quicktime';
    if (lower.contains('.3gp')) return 'video/3gpp';
    if (lower.contains('.gif')) return 'image/gif';
    if (lower.contains('.png')) return 'image/png';
    if (lower.contains('.webp')) return 'image/webp';
    if (lower.contains('.jpg') || lower.contains('.jpeg')) return 'image/jpeg';
    if (lower.contains('.pdf')) return 'application/pdf';
    if (lower.contains('.zip')) return 'application/zip';
    if (lower.contains('.mp3')) return 'audio/mpeg';
    if (lower.contains('.m4a')) return 'audio/mp4';
    if (lower.contains('.aac')) return 'audio/aac';
    if (lower.contains('.opus')) return 'audio/opus';
    if (lower.contains('.oga') || lower.contains('.ogg')) return 'audio/ogg';
    if (lower.contains('.wav')) return 'audio/wav';
    if (lower.contains('.vcf') || lower.contains('.vcard')) return 'text/vcard';
    if (lower.contains('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.contains('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.contains('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    if (lower.contains('.txt')) return 'text/plain';
    if (lower.contains('.csv')) return 'text/csv';
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
    if (WhatsAppUri.isPrivateMediaHost(host)) return false;
    if (host == 'wa.me' ||
        host.endsWith('.wa.me') ||
        host == 'whatsapp.com' ||
        host.endsWith('.whatsapp.com')) {
      return false;
    }
    return WhatsAppUri.isPublicMediaHost(host);
  }

  static String userFacingError(Uri uri, {String? html}) {
    final access = accessFor(uri, html: html);
    if (access == WhatsAppAccess.restricted) {
      if (WhatsAppUri.classifyUrl(uri) == WhatsAppContentType.groupInvite) {
        return 'This is a WhatsApp group invitation. Open it in WhatsApp to '
            'join. The app cannot join groups or extract private content.';
      }
      if (WhatsAppUri.classifyUrl(uri) == WhatsAppContentType.status) {
        return 'This WhatsApp status cannot be accessed automatically.';
      }
      return 'This WhatsApp content cannot be accessed automatically.';
    }
    if (access == WhatsAppAccess.authenticationRequired) {
      return 'WhatsApp authentication is required.';
    }
    if (access == WhatsAppAccess.unavailable) {
      return 'This WhatsApp content is unavailable.';
    }

    return switch (WhatsAppUri.classifyUrl(uri)) {
      WhatsAppContentType.home =>
        'This is the WhatsApp home page, not a downloadable file.',
      WhatsAppContentType.chatLink =>
        'WhatsApp link detected. Open it in WhatsApp. '
            'This is not a downloadable media resource.',
      WhatsAppContentType.businessChat =>
        'This WhatsApp business chat link is not a downloadable file. '
            'Open it in WhatsApp.',
      WhatsAppContentType.groupInvite =>
        'This is a WhatsApp group invitation. Open it in WhatsApp to join. '
            'The app cannot join groups or extract private content.',
      WhatsAppContentType.publicChannel =>
        html != null && detectMediaType(html) == WhatsAppMediaType.text
            ? 'This WhatsApp Channel does not expose downloadable media.'
            : 'This WhatsApp Channel does not expose downloadable media. '
                'Open it in WhatsApp, or share the file with UniversalDownloader.',
      WhatsAppContentType.publicChannelPost =>
        'No downloadable media found on this WhatsApp Channel post. '
            'If the post only opens WhatsApp, that is a platform limitation.',
      WhatsAppContentType.whatsappWeb =>
        'WhatsApp authentication is required.',
      WhatsAppContentType.status =>
        'This WhatsApp status cannot be accessed automatically.',
      WhatsAppContentType.callLink =>
        'This WhatsApp call link is not a downloadable file.',
      WhatsAppContentType.invalid => 'Invalid WhatsApp URL.',
      WhatsAppContentType.privateMedia =>
        'WhatsApp authentication is required.',
      WhatsAppContentType.authentication =>
        'WhatsApp authentication is required.',
      WhatsAppContentType.deepLink =>
        'This WhatsApp link is not a downloadable public item. '
            'Open it in WhatsApp.',
      WhatsAppContentType.directMedia =>
        'Could not find downloadable media on this WhatsApp URL.',
      WhatsAppContentType.nonContent => 'This WhatsApp URL is not supported.',
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
          headers: SocialHttpHeaders.forPageFetch(url, SocialPlatform.whatsapp),
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
        platform: SocialPlatform.whatsapp,
        mediaUrl: url,
        fallbackSlug: 'whatsapp_media',
        mimeHint: mime,
      ),
      platform: SocialPlatform.whatsapp.label,
      pageUrl: pageUrl.toString(),
      mimeType: mime,
      thumbnailUrl: mime.startsWith('image/') ? url : null,
      requestHeaders: _mediaHeaders(pageUrl),
    );
  }

  static Map<String, String> _mediaHeaders(Uri pageUrl) {
    return SocialHttpHeaders.forMediaDownload(
      pageUrl: pageUrl,
      mediaUrl: 'https://scontent.xx.fbcdn.net/',
      platform: SocialPlatform.whatsapp,
    );
  }

  static DiscoveredResource _resourceForItem({
    required WhatsAppMediaItem item,
    required Uri pageUrl,
    required WhatsAppChannelInfo info,
    required Map<String, String> headers,
    required int index,
    required int total,
  }) {
    final slug =
        (info.contentId ?? 'whatsapp').replaceAll(':', '_').replaceAll('/', '_');
    final indexedSlug = total > 1 ? '${slug}_${index + 1}' : slug;
    return DiscoveredResource(
      directUrl: item.url,
      fileName: MediaExtractor.buildFileNameForSocial(
        pageUrl: pageUrl,
        platform: SocialPlatform.whatsapp,
        mediaUrl: item.url,
        title: item.fileName ?? info.title,
        fallbackSlug: indexedSlug,
        mimeHint: item.mimeType,
      ),
      platform: SocialPlatform.whatsapp.label,
      pageUrl: pageUrl.toString(),
      title: info.title,
      mimeType: item.mimeType,
      thumbnailUrl:
          item.thumbnailUrl ??
          info.thumbnailUrl ??
          (item.mimeType.startsWith('image/') ? item.url : null),
      requestHeaders: headers,
      author: info.title,
      durationSeconds: item.durationSeconds ?? info.durationSeconds,
      width: item.width ?? info.width,
      height: item.height ?? info.height,
      kind: DiscoveredResourceKind.fromMime(
        item.mimeType,
        carousel: total > 1,
      ),
    );
  }

  static bool _isSiteIcon(String url) {
    final lower = url.toLowerCase();
    return lower.contains('whatsapp-logo') ||
        lower.contains('whatsapp_logo') ||
        lower.contains('/rsrc.php') ||
        lower.contains('favicon') ||
        lower.contains('/img/whatsapp');
  }

  static String? _bestThumbnail(String html) {
    final og = _metaContent(html, 'og:image');
    if (og != null && isDirectMediaUrl(og) && !_isSiteIcon(og)) return og;
    return null;
  }

  static double? _durationFromHtml(String html) {
    final og = _metaContent(html, 'og:video:duration');
    return og == null ? null : double.tryParse(og);
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

  static String? _cleanTitle(String? title) {
    if (title == null) return null;
    var cleaned = title.trim();
    cleaned = cleaned.replaceAll(RegExp(r'\s+–\s+WhatsApp$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+\|\s+WhatsApp$'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+-\s+WhatsApp$'), '');
    return cleaned.isEmpty ? null : cleaned;
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

enum WhatsAppHtmlStatus { ok, restricted, authenticationRequired, unavailable }

enum WhatsAppAccess { public, restricted, authenticationRequired, unavailable }

enum WhatsAppMediaType {
  image,
  video,
  audio,
  voiceNote,
  document,
  pdf,
  archive,
  contact,
  text,
  unknown,
}

class WhatsAppMediaItem {
  const WhatsAppMediaItem({
    required this.url,
    required this.mediaType,
    required this.mimeType,
    this.thumbnailUrl,
    this.fileName,
    this.durationSeconds,
    this.width,
    this.height,
  });

  final String url;
  final WhatsAppMediaType mediaType;
  final String mimeType;
  final String? thumbnailUrl;
  final String? fileName;
  final double? durationSeconds;
  final int? width;
  final int? height;
}

class WhatsAppChannelInfo {
  const WhatsAppChannelInfo({
    this.contentId,
    this.channelId,
    this.postId,
    this.title,
    this.description,
    this.thumbnailUrl,
    this.durationSeconds,
    this.width,
    this.height,
    this.mediaType = WhatsAppMediaType.unknown,
    this.canonicalUrl,
  });

  final String? contentId;
  final String? channelId;
  final String? postId;
  final String? title;
  final String? description;
  final String? thumbnailUrl;
  final double? durationSeconds;
  final int? width;
  final int? height;
  final WhatsAppMediaType mediaType;
  final String? canonicalUrl;
}
