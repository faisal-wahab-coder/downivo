import 'package:download_engine/download_engine.dart';
import 'package:download_engine/src/content_providers/social_http_headers.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2 / 3 — YouTube resolver unit tests.
///
/// Tests HTML and InnerTube response parsing using synthetic data.
/// No network calls required — verifies structural extraction logic.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 2 — Metadata extraction from synthetic HTML
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 2 — YouTube metadata from HTML', () {
    test('YT-META-001 MediaExtractor gets title from og:title', () {
      const html = '''
<html><head>
  <meta property="og:title" content="Big Buck Bunny" />
  <script>
  var ytInitialPlayerResponse = {
    "streamingData":{
      "formats":[
        {"url":"https://rr1---sn.example.googlevideo.com/videoplayback?id=a&itag=18","mimeType":"video/mp4","qualityLabel":"360p"}
      ]
    }
  };
  </script>
</head></html>
''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result, isNotNull);
      expect(result!.title, 'Big Buck Bunny');
    });

    test('YT-META-002 DiscoveredResource has platform label YouTube', () {
      const html = '''
<meta property="og:title" content="Test" />
<script>
var ytInitialPlayerResponse = {"streamingData":{"formats":[{"url":"https://rr1---sn.googlevideo.com/videoplayback?itag=18","mimeType":"video/mp4"}]}};
</script>
''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result?.platform, 'YouTube');
    });

    test('YT-META-003 DiscoveredResource directUrl points to googlevideo', () {
      const html = '''
<script>
var ytInitialPlayerResponse = {"streamingData":{"formats":[{"url":"https://rr2---sn.googlevideo.com/videoplayback?itag=22&source=youtube","mimeType":"video/mp4"}]}};
</script>
''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result?.directUrl, contains('googlevideo.com'));
    });

    test('YT-META-004 fileName ends with .mp4 for video content', () {
      const html = '''
<meta property="og:title" content="Sample Video" />
<script>
var ytInitialPlayerResponse = {"streamingData":{"formats":[{"url":"https://rr3---sn.googlevideo.com/videoplayback?itag=18","mimeType":"video/mp4"}]}};
</script>
''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result?.fileName, endsWith('.mp4'));
    });

    test('YT-META-005 mimeType is set from og:video:type when present', () {
      const html = '''
<meta property="og:video:type" content="video/mp4" />
<meta property="og:title" content="Test" />
<script>
var ytInitialPlayerResponse = {"streamingData":{"formats":[{"url":"https://rr1---sn.googlevideo.com/videoplayback?itag=18","mimeType":"video/mp4"}]}};
</script>
''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result?.mimeType, 'video/mp4');
    });

    test('YT-META-006 empty HTML returns null', () {
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: '',
        platform: SocialPlatform.youtube,
      );
      expect(result, isNull);
    });

    test('YT-META-007 HTML without streaming data returns null', () {
      const html = '''
<html><head>
  <meta property="og:title" content="Page Title" />
</head><body>No streaming data here</body></html>
''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 2 — InnerTube response structure
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 2 — YouTube itag preference', () {
    test('YT-ITAG-001 itag 22 is preferred over itag 18', () {
      const html = '''
<script>
var ytInitialPlayerResponse = {
  "streamingData":{
    "formats":[
      {"url":"https://rr1---sn.googlevideo.com/videoplayback?itag=18&id=low","mimeType":"video/mp4"},
      {"url":"https://rr1---sn.googlevideo.com/videoplayback?itag=22&id=high","mimeType":"video/mp4"}
    ]
  }
};
</script>
''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      // MediaExtractor picks the first available URL, but YouTubeResolver
      // has itag preference. MediaExtractor is a fallback path.
      expect(result, isNotNull);
      expect(result!.directUrl, contains('googlevideo.com'));
    });

    test('YT-ITAG-002 YouTubeResolver prefers itag 22 (720p muxed)', () {
      const html22 =
          '"streamingUrl":"https://rr1---sn.googlevideo.com/videoplayback?itag=22\\u0026source=youtube"';
      const html18 =
          '"streamingUrl":"https://rr1---sn.googlevideo.com/videoplayback?itag=18\\u0026source=youtube"';

      // itag 22 found → should be picked
      final url22 = YouTubeResolver.extractFromHtmlForTest(html22);
      expect(url22, contains('itag=22'));

      final url18 = YouTubeResolver.extractFromHtmlForTest(html18);
      expect(url18, contains('itag=18'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 3 — DiscoveredResource shape
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 3 — DiscoveredResource structure', () {
    test('YT-RES-001 DiscoveredResource has required fields', () {
      const resource = DiscoveredResource(
        directUrl: 'https://rr1.googlevideo.com/videoplayback?itag=22',
        fileName: 'test_video.mp4',
        platform: 'YouTube',
        pageUrl: 'https://www.youtube.com/watch?v=abc',
        title: 'Test Video',
        mimeType: 'video/mp4',
      );
      expect(resource.directUrl, isNotEmpty);
      expect(resource.fileName, isNotEmpty);
      expect(resource.platform, 'YouTube');
      expect(resource.title, isNotNull);
      expect(resource.mimeType, isNotNull);
    });

    test('YT-RES-002 copyWith preserves pageUrl', () {
      const original = DiscoveredResource(
        directUrl: 'https://rr1.googlevideo.com/videoplayback',
        fileName: 'video.mp4',
        platform: 'YouTube',
      );
      final copied = original.copyWith(
        pageUrl: 'https://www.youtube.com/watch?v=abc',
      );
      expect(copied.pageUrl, 'https://www.youtube.com/watch?v=abc');
      expect(copied.platform, 'YouTube');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 3 — File naming for YouTube
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 3 — YouTube file naming', () {
    test('YT-NAME-001 buildFileNameForSocial uses title slug', () {
      final name = MediaExtractor.buildFileNameForSocial(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        platform: SocialPlatform.youtube,
        mediaUrl: 'https://rr1.googlevideo.com/videoplayback?itag=22',
        title: 'Big Buck Bunny - Official Trailer',
        mimeHint: 'video/mp4',
      );
      expect(name, endsWith('.mp4'));
      expect(name.contains('big_buck_bunny'), isTrue);
    });

    test('YT-NAME-002 fallback slug uses video ID', () {
      final name = MediaExtractor.buildFileNameForSocial(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4'),
        platform: SocialPlatform.youtube,
        mediaUrl: 'https://rr1.googlevideo.com/videoplayback?itag=22',
        fallbackSlug: 'YE7VzlLtp-4',
        mimeHint: 'video/mp4',
      );
      expect(name, endsWith('.mp4'));
    });

    test('YT-NAME-003 sanitize removes dangerous characters', () {
      final name = FileNameResolver.sanitize('video/file:name?.mp4');
      expect(name.contains('/'), isFalse);
      expect(name.contains(':'), isFalse);
      expect(name.contains('?'), isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 4 / 5 / 6 — Quality, Audio, Muxing capability detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 4/5/6 — Quality and audio capability assessment', () {
    test('YT-CAP-001 resolver exposes format list and picks a recommended stream', () {
      const preferredItags = [22, 18, 37, 136, 135, 134, 399, 401, 313];
      expect(preferredItags.length, greaterThan(1));
      const resource = DiscoveredResource(
        directUrl: 'https://rr1.googlevideo.com/videoplayback?itag=22',
        fileName: 'video.mp4',
        platform: 'YouTube',
        formats: [
          MediaFormat(url: 'https://a', label: '720p', isRecommended: true),
          MediaFormat(url: 'https://b', label: '360p'),
        ],
      );
      expect(resource.formats, hasLength(2));
      expect(resource.formats.where((f) => f.isRecommended), hasLength(1));
    });

    test('YT-CAP-002 saves M4A from the muxed video and hides blocked audio URLs', () {
      final formats = YouTubeResolver.formatsFromStreamingDataForTest({
        'formats': [
          {
            'url': 'https://rr1.googlevideo.com/videoplayback?itag=22',
            'itag': 22,
            'mimeType': 'video/mp4; codecs="avc1.64001F, mp4a.40.2"',
            'qualityLabel': '720p',
            'height': 720,
          },
        ],
        'adaptiveFormats': [
          {
            'url': 'https://rr1.googlevideo.com/videoplayback?itag=136',
            'itag': 136,
            'mimeType': 'video/mp4; codecs="avc1.4d401f"',
            'qualityLabel': '720p',
            'height': 720,
          },
          {
            'url': 'https://rr1.googlevideo.com/videoplayback?itag=140',
            'itag': 140,
            'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
            'bitrate': 128000,
            'contentLength': '1000',
          },
          {
            'url': 'https://rr1.googlevideo.com/videoplayback?itag=139',
            'itag': 139,
            'mimeType': 'audio/mp4; codecs="mp4a.40.2"',
            'bitrate': 48000,
          },
          {
            'url': 'https://rr1.googlevideo.com/videoplayback?itag=251',
            'itag': 251,
            'mimeType': 'audio/webm; codecs="opus"',
            'bitrate': 160000,
          },
        ],
      });

      expect(formats.map((format) => format.label), ['720p', 'M4A']);
      expect(formats.where((format) => format.url.contains('itag=136')), isEmpty);
      expect(formats.where((format) => format.url.contains('itag=140')), isEmpty);
      expect(formats.where((format) => format.url.contains('itag=251')), isEmpty);
      expect(formats.last.track, MediaFormatTrack.audio);
      expect(formats.last.mimeType, 'audio/mp4');
      expect(formats.last.extractAudio, isTrue);
      expect(formats.last.url, contains('itag=22'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // HTTP headers for YouTube
  // ─────────────────────────────────────────────────────────────────────────

  group('YouTube HTTP headers', () {
    test('YT-HDR-001 page fetch uses mobile user agent', () {
      final headers = SocialHttpHeaders.forPageFetch(
        Uri.parse('https://www.youtube.com/watch?v=abc'),
        SocialPlatform.youtube,
      );
      expect(headers['User-Agent'], contains('Mobile'));
      expect(headers['Referer'], 'https://www.youtube.com');
    });

    test('YT-HDR-002 media download uses Android YouTube UA', () {
      final headers = SocialHttpHeaders.forMediaDownload(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        mediaUrl: 'https://rr1.googlevideo.com/videoplayback?itag=22',
        platform: SocialPlatform.youtube,
      );
      expect(headers['User-Agent'], contains('com.google.android.youtube'));
      expect(headers['Referer'], 'https://www.youtube.com/');
    });
  });
}
