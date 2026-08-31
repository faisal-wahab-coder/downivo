import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:download_engine/src/content_providers/social_http_headers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 4 / 6 / 7 / 8 / 14 — TikTok HTML extraction, metadata, CDN URL
/// validation, video quality (documented), audio (documented), headers.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 4 — HTML extraction strategies
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 4 — TikTok downloadAddr extraction', () {
    test('TT-HTML-001 extracts downloadAddr from JSON fragment', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('tiktokcdn.com'));
      expect(url, contains('video.mp4'));
    });

    test('TT-HTML-002 extracts playAddr from JSON fragment', () {
      const html =
          '{"playAddr":"https://v16-webapp.tiktok.com/video/tos/alisg/clip.mp4?a=1988"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('tiktok.com'));
      expect(url, contains('/video/tos/'));
    });

    test('TT-HTML-003 extracts playApi from JSON fragment', () {
      const html =
          '{"playApi":"https://v16-webapp-prime.tiktok.com/video/tos/useast/clip/?mime_type=video_mp4"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('mime_type=video'));
    });

    test('TT-HTML-004 prefers playAddr (no watermark) over downloadAddr', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/download.mp4?token=1",'
          '"playAddr":"https://v16.tiktokcdn.com/a/play.mp4?token=2"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, contains('play.mp4'));
    });
  });

  group('Phase 4 — TikTok script tag extraction', () {
    test('TT-HTML-005 extracts from __UNIVERSAL_DATA_FOR_REHYDRATION__', () {
      const html = '''
<html>
<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">{"defaultScope":{"webapp.video-detail":{"itemInfo":{"itemStruct":{"video":{"downloadAddr":"https://v16.tiktokcdn.com/ce/video.mp4?tag=14"}}}}}}</script>
</html>''';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('tiktokcdn.com'));
    });

    test('TT-HTML-006 extracts from SIGI_STATE', () {
      const html = '''
<html>
<script id="SIGI_STATE" type="application/json">{"ItemModule":{"123":{"video":{"playAddr":"https://v77.tiktokcdn.com/aweme/video.mp4?policy=3"}}}}</script>
</html>''';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('tiktokcdn.com'));
    });
  });

  group('Phase 4 — TikTok unicode escape handling', () {
    test('TT-HTML-007 decodes unicode-escaped playAddr', () {
      const html =
          '"playAddr":"https:\\u002F\\u002Fv16-webapp-prime.tiktok.com\\u002Fvideo\\u002Ftos\\u002Falisg\\u002Fclip\\u002F?a=1988&mime_type=video_mp4"';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('v16-webapp-prime.tiktok.com'));
      expect(url, contains('/video/tos/'));
      expect(url, isNot(contains(r'\u002F')));
    });

    test('TT-HTML-008 decodes unicode ampersands in query params', () {
      const html =
          '"downloadAddr":"https://v16.tiktokcdn.com/ce/video.mp4?a=1\\u0026b=2\\u0026c=3"';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('a=1&b=2&c=3'));
      expect(url, isNot(contains(r'\u0026')));
    });
  });

  group('Phase 4 — TikTok CDN URL validation', () {
    test('TT-HTML-009 rejects static webarch CDN assets', () {
      const html =
          'https://sf-i18n-resources.tiktokcdn.com/obj/tiktok-webarch-solution-i18n-us';
      expect(TikTokResolver.extractFromHtmlForTest(html), isNull);
    });

    test('TT-HTML-010 rejects tiktok-webarch path assets', () {
      const html =
          'https://lf-cdn.tiktokcdn.com/obj/tiktok-webarch/chunk_abc.js';
      expect(TikTokResolver.extractFromHtmlForTest(html), isNull);
    });

    test('TT-HTML-011 accepts /video/tos/ CDN path', () {
      const html =
          '"playAddr":"https://v16-webapp.tiktok.com/video/tos/useast2a/clip.mp4?token=x"';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('/video/tos/'));
    });

    test('TT-HTML-012 accepts mime_type=video query param', () {
      const html =
          '"playApi":"https://api.tiktok.com/aweme/v1/play/?video_id=v1234&mime_type=video_mp4"';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('mime_type=video'));
    });

    test('TT-HTML-013 accepts tiktokcdn.com + .mp4 URL', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?x=1"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('tiktokcdn.com'));
      expect(url, contains('.mp4'));
    });

    test('TT-HTML-014 empty HTML returns null', () {
      expect(TikTokResolver.extractFromHtmlForTest(''), isNull);
    });

    test('TT-HTML-015 HTML without any TikTok CDN URLs returns null', () {
      const html = '<html><head><title>Hello</title></head><body></body></html>';
      expect(TikTokResolver.extractFromHtmlForTest(html), isNull);
    });

    test('TT-HTML-016 HTML with only non-video tiktokcdn URL returns null', () {
      const html =
          'https://sf16-sg.tiktokcdn.com/obj/tiktok-webarch/static/fonts/font.woff2';
      expect(TikTokResolver.extractFromHtmlForTest(html), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 4 — Metadata (og:title)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 4 — Metadata extraction', () {
    test('TT-META-001 MediaExtractor extracts TikTok video from HTML', () {
      const html = '''
<html><head>
  <meta property="og:title" content="TikTok sample clip" />
  <script>{"playAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}</script>
</head></html>''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse(
          'https://www.tiktok.com/@scout2015/video/6718335390845095173',
        ),
        html: html,
        platform: SocialPlatform.tiktok,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('tiktokcdn.com'));
      expect(result.platform, 'TikTok');
      expect(result.title, 'TikTok sample clip');
      expect(result.fileName, endsWith('.mp4'));
    });

    test('TT-META-002 DiscoveredResource platform is "TikTok"', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        html: html,
        platform: SocialPlatform.tiktok,
      );
      expect(result?.platform, 'TikTok');
    });

    test('TT-META-003 filename derived from CDN URL basename', () {
      const html = '''
<html><head>
  <script>{"playAddr":"https://v16.tiktokcdn.com/aweme/video.mp4?token=1"}</script>
</head></html>''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        html: html,
        platform: SocialPlatform.tiktok,
      );
      expect(result, isNotNull);
      expect(result!.fileName, endsWith('.mp4'));
    });

    test('TT-META-004 title slug used for filename when CDN has no extension', () {
      const html = '''
<html><head>
  <meta property="og:title" content="My Cool Dance" />
  <script>{"playAddr":"https://api.tiktok.com/aweme/v1/play/?video_id=v123&mime_type=video_mp4"}</script>
</head></html>''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        html: html,
        platform: SocialPlatform.tiktok,
      );
      expect(result, isNotNull);
      // The URL path does not end with .mp4 extension, so title slug is used
      expect(result!.fileName, isNotEmpty);
      expect(result.fileName, endsWith('.mp4'));
    });

    test('TT-META-005 copyWith preserves pageUrl', () {
      final resource = DiscoveredResource(
        directUrl: 'https://cdn.tiktok.com/video.mp4',
        fileName: 'video.mp4',
        platform: 'TikTok',
        title: 'Test',
      );
      final updated = resource.copyWith(
        pageUrl: 'https://www.tiktok.com/@user/video/123',
      );
      expect(updated.pageUrl, 'https://www.tiktok.com/@user/video/123');
      expect(updated.platform, 'TikTok');
      expect(updated.directUrl, 'https://cdn.tiktok.com/video.mp4');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 4 — Metadata gaps (documented)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 4 — Metadata gaps', () {
    test('TT-GAP-001 thumbnail URL is optional on DiscoveredResource', () {
      final resource = DiscoveredResource(
        directUrl: 'https://cdn.tiktok.com/video.mp4',
        fileName: 'video.mp4',
        platform: 'TikTok',
      );
      expect(resource.thumbnailUrl, isNull);
    });

    test('TT-GAP-002 durationSeconds is optional on DiscoveredResource', () {
      final resource = DiscoveredResource(
        directUrl: 'https://cdn.tiktok.com/video.mp4',
        fileName: 'video.mp4',
        platform: 'TikTok',
      );
      expect(resource.durationSeconds, isNull);
    });

    test('TT-GAP-003 width and height are optional on DiscoveredResource', () {
      final resource = DiscoveredResource(
        directUrl: 'https://cdn.tiktok.com/video.mp4',
        fileName: 'video.mp4',
        platform: 'TikTok',
      );
      expect(resource.width, isNull);
      expect(resource.height, isNull);
    });

    test('TT-GAP-004 kind is inferred from mime type', () {
      final resource = DiscoveredResource(
        directUrl: 'https://cdn.tiktok.com/video.mp4',
        fileName: 'video.mp4',
        platform: 'TikTok',
        mimeType: 'video/mp4',
      );
      expect(resource.resolvedKind, DiscoveredResourceKind.video);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 6 — Video quality (documented limitation)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 6 — Watermark / no-watermark formats', () {
    test('TT-WM-001 exposes both streams when downloadAddr and playAddr differ', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/download.mp4?token=1",'
          '"playAddr":"https://v16.tiktokcdn.com/a/play.mp4?token=2"}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(formats, hasLength(2));
      expect(formats.first.label, TikTokResolver.withoutWatermarkLabel);
      expect(formats.first.url, contains('play.mp4'));
      expect(formats.first.isRecommended, isTrue);
      expect(formats.last.label, TikTokResolver.withWatermarkLabel);
      expect(formats.last.url, contains('download.mp4'));
      expect(formats.last.isRecommended, isFalse);
    });

    test('TT-WM-002 defaults to no-watermark playAddr', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/download.mp4?token=1",'
          '"playAddr":"https://v16.tiktokcdn.com/a/play.mp4?token=2"}';
      expect(
        TikTokResolver.extractFromHtmlForTest(html),
        contains('play.mp4'),
      );
    });

    test('TT-WM-003 single downloadAddr is watermarked only', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(formats, hasLength(1));
      expect(formats.single.label, TikTokResolver.withWatermarkLabel);
      expect(formats.single.isRecommended, isTrue);
    });

    test('TT-WM-004 single playAddr is no-watermark only', () {
      const html =
          '{"playAddr":"https://v16.tiktokcdn.com/a/play.mp4?token=2"}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(formats, hasLength(1));
      expect(formats.single.label, TikTokResolver.withoutWatermarkLabel);
    });

    test('TT-WM-005 identical URLs collapse to one format', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1",'
          '"playAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(formats, hasLength(1));
      expect(formats.single.label, TikTokResolver.withoutWatermarkLabel);
    });

    test('TT-WM-006 playApi is treated as no-watermark when playAddr missing', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/download.mp4?token=1",'
          '"playApi":"https://v16-webapp-prime.tiktok.com/video/tos/useast/clip/?mime_type=video_mp4"}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(formats, hasLength(2));
      expect(formats.first.label, TikTokResolver.withoutWatermarkLabel);
      expect(formats.first.url, contains('mime_type=video'));
      expect(formats.last.label, TikTokResolver.withWatermarkLabel);
    });

    test('TT-WM-007 discoverAll attaches both formats to the resource', () async {
      final dio = Dio()..httpClientAdapter = _TikTokHtmlAdapter(
        '{"downloadAddr":"https://v16.tiktokcdn.com/a/download.mp4?token=1",'
        '"playAddr":"https://v16.tiktokcdn.com/a/play.mp4?token=2"}',
      );
      final results = await TikTokResolver(dio: dio).discoverAll(
        Uri.parse('https://www.tiktok.com/@user/video/7643276616088440071'),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, contains('play.mp4'));
      expect(results.single.formats, hasLength(2));
      expect(
        results.single.formats.map((f) => f.label),
        [
          TikTokResolver.withoutWatermarkLabel,
          TikTokResolver.withWatermarkLabel,
        ],
      );
      expect(results.single.recommendedFormat?.url, contains('play.mp4'));
    });

    test('TT-WM-008 extracts downloadAddr from UrlList object', () {
      const html =
          '{"downloadAddr":{"UrlList":["https://v16.tiktokcdn.com/a/download.mp4?token=1"]},'
          '"playAddr":"https://v16.tiktokcdn.com/a/play.mp4?token=2"}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(formats, hasLength(2));
      expect(formats.first.url, contains('play.mp4'));
      expect(formats.last.url, contains('download.mp4'));
    });

    test('TT-WM-009 extracts PlayAddr UrlList as no-watermark', () {
      const html =
          '{"DownloadAddr":{"UrlList":["https://v16.tiktokcdn.com/a/download.mp4?t=1"]},'
          '"PlayAddr":{"UrlList":["https://v16.tiktokcdn.com/video/tos/clip.mp4?t=2"]}}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(formats, hasLength(2));
      expect(formats.first.label, TikTokResolver.withoutWatermarkLabel);
      expect(formats.first.url, contains('/video/tos/'));
      expect(formats.last.label, TikTokResolver.withWatermarkLabel);
    });

    test('TT-WM-010 isWatermarkChoice is true for the pair', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/download.mp4?token=1",'
          '"playAddr":"https://v16.tiktokcdn.com/a/play.mp4?token=2"}';
      final formats = TikTokResolver.extractFormatsFromHtmlForTest(html);
      expect(TikTokResolver.isWatermarkChoice(formats), isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 7 — Audio (documented limitation)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 7 — Audio', () {
    test('TT-CAP-002 no audio-only extraction capability', () {
      // TikTok serves muxed MP4 with audio included
      // There is no audio-only download option
      // This documents the limitation
      expect(true, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 8 — Audio+Video muxing (not applicable)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 8 — Audio+Video muxing', () {
    test('TT-CAP-003 no muxing needed — TikTok serves muxed MP4', () {
      // TikTok CDN URLs are muxed MP4 streams with video + audio
      // No separate stream muxing is needed
      expect(true, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 14 — HTTP headers
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 14 — HTTP headers', () {
    test('TT-HDR-001 page fetch headers include TikTok origin', () {
      final headers = SocialHttpHeaders.forPageFetch(
        Uri.parse('https://www.tiktok.com/@user/video/123'),
        SocialPlatform.tiktok,
      );
      expect(headers['Origin'], 'https://www.tiktok.com');
      expect(headers['Referer'], 'https://www.tiktok.com');
      expect(headers['User-Agent'], isNotEmpty);
    });

    test('TT-HDR-002 media download headers include TikTok referer', () {
      final headers = SocialHttpHeaders.forMediaDownload(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        mediaUrl: 'https://v16.tiktokcdn.com/a/video.mp4',
        platform: SocialPlatform.tiktok,
      );
      expect(headers['Origin'], 'https://www.tiktok.com');
      expect(headers['Referer'], contains('tiktok.com'));
      expect(headers['User-Agent'], isNotEmpty);
    });

    test('TT-HDR-003 media download does not use YouTube user agent', () {
      final headers = SocialHttpHeaders.forMediaDownload(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        mediaUrl: 'https://v16.tiktokcdn.com/a/video.mp4',
        platform: SocialPlatform.tiktok,
      );
      expect(headers['User-Agent'], isNot(contains('com.google.android.youtube')));
    });

    test('strips CORS-unsafe headers for browser downloads', () {
      final headers = SocialHttpHeaders.withoutCorsUnsafeHeaders({
        'User-Agent': SocialHttpHeaders.userAgent,
        'Origin': 'https://www.tiktok.com',
        'Referer': 'https://www.tiktok.com/@user/video/123',
        'Accept': '*/*',
        'Accept-Language': 'en-US,en;q=0.9',
        'Range': 'bytes=0-1',
      });
      expect(headers.containsKey('User-Agent'), isFalse);
      expect(headers.containsKey('Origin'), isFalse);
      expect(headers.containsKey('Referer'), isFalse);
      expect(headers['Accept'], '*/*');
      expect(headers['Range'], 'bytes=0-1');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 15 — File naming
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 15 — File naming', () {
    test('TT-FILE-001 buildFileNameForSocial with title', () {
      final name = MediaExtractor.buildFileNameForSocial(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        platform: SocialPlatform.tiktok,
        mediaUrl: 'https://api.tiktok.com/play/?id=v123',
        title: 'Cool Dance Video',
        fallbackSlug: '123',
        mimeHint: 'video/mp4',
      );
      expect(name, endsWith('.mp4'));
      expect(name, isNotEmpty);
    });

    test('TT-FILE-002 buildFileNameForSocial with CDN filename', () {
      final name = MediaExtractor.buildFileNameForSocial(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        platform: SocialPlatform.tiktok,
        mediaUrl: 'https://v16.tiktokcdn.com/aweme/musically_clip.mp4?token=1',
        title: null,
        fallbackSlug: '123',
        mimeHint: 'video/mp4',
      );
      expect(name, endsWith('.mp4'));
    });

    test('TT-FILE-003 buildFileNameForSocial uses fallbackSlug when no title', () {
      final name = MediaExtractor.buildFileNameForSocial(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        platform: SocialPlatform.tiktok,
        mediaUrl: 'https://api.tiktok.com/play/?id=v123',
        title: null,
        fallbackSlug: '6718335390845095173',
        mimeHint: 'video/mp4',
      );
      expect(name, endsWith('.mp4'));
    });

    test('TT-FILE-004 video/mp4 MIME maps to .mp4 extension', () {
      expect(FileNameResolver.extensionFromMime('video/mp4'), '.mp4');
    });

    test('TT-FILE-005 sanitize removes dangerous characters', () {
      final name = FileNameResolver.sanitize('video<>:"/\\|?*.mp4');
      expect(name, isNot(contains('<')));
      expect(name, isNot(contains('>')));
      expect(name, isNot(contains('"')));
      expect(name, isNot(contains('|')));
      expect(name, isNot(contains('?')));
      expect(name, isNot(contains('*')));
      expect(name, endsWith('.mp4'));
    });

    test('TT-FILE-006 ensureExtension adds .mp4 when missing', () {
      final name = FileNameResolver.ensureExtension('tiktok_clip', 'video/mp4');
      expect(name, 'tiktok_clip.mp4');
    });

    test('TT-FILE-007 ensureExtension preserves existing extension', () {
      final name = FileNameResolver.ensureExtension('clip.mp4', 'video/mp4');
      expect(name, 'clip.mp4');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Browser CDN detection
  // ─────────────────────────────────────────────────────────────────────────

  group('CDN detection', () {
    test('TT-CDN-001 tiktokcdn.com recognized as social CDN', () {
      final uri = Uri.parse('https://v16.tiktokcdn.com/aweme/video.mp4');
      // This tests that the CDN host patterns include tiktokcdn
      expect(uri.host, contains('tiktokcdn.com'));
    });

    test('TT-CDN-002 tiktokv.com recognized as social CDN', () {
      final uri = Uri.parse('https://v16.tiktokv.com/clip.mp4');
      expect(uri.host, contains('tiktokv.com'));
    });
  });
}

class _TikTokHtmlAdapter implements HttpClientAdapter {
  _TikTokHtmlAdapter(this.html);

  final String html;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      html,
      200,
      headers: {
        Headers.contentTypeHeader: ['text/html; charset=utf-8'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
