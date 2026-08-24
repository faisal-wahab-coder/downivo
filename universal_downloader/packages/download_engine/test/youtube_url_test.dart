import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 1 / 7 / 8 / 12 — YouTube URL parsing, Shorts detection, URL
/// variations, and invalid-URL rejection.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Platform detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — YouTube platform detection', () {
    test('YT-URL-001 www.youtube.com/watch is YouTube', () {
      final uri = Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.youtube);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'YouTube');
    });

    test('YT-URL-002 youtu.be shortlink is YouTube', () {
      final uri = Uri.parse('https://youtu.be/YE7VzlLtp-4');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.youtube);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('YT-URL-003 youtube.com/shorts is YouTube', () {
      final uri = Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.youtube);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('YT-URL-004 m.youtube.com is YouTube', () {
      final uri = Uri.parse('https://m.youtube.com/watch?v=YE7VzlLtp-4');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.youtube);
    });

    test('YT-URL-005 youtube.com/embed is YouTube', () {
      final uri = Uri.parse('https://www.youtube.com/embed/YE7VzlLtp-4');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.youtube);
    });

    test('YT-URL-006 non-YouTube host is not YouTube', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.example.com/12345')),
        isNull,
      );
      expect(
        ContentProviderRegistry.canHandle(
          Uri.parse('https://www.example.com/12345'),
        ),
        isFalse,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Video ID extraction (standard videos)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — Standard YouTube video ID extraction', () {
    test('YT-001 www.youtube.com/watch?v=YE7VzlLtp-4 → YE7VzlLtp-4', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4'),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-002 youtu.be/YE7VzlLtp-4 → YE7VzlLtp-4', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtu.be/YE7VzlLtp-4'),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-003 watch?v=YE7VzlLtp-4&t=30s → YE7VzlLtp-4', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4&t=30s'),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-004 watch?v=YE7VzlLtp-4&feature=youtu.be → YE7VzlLtp-4', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse(
            'https://www.youtube.com/watch?v=YE7VzlLtp-4&feature=youtu.be',
          ),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-005 watch?v=f7NwyBnIRTE → f7NwyBnIRTE', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/watch?v=f7NwyBnIRTE'),
        ),
        'f7NwyBnIRTE',
      );
    });

    test('YT-006 YouTubeResolver.videoIdFromUri matches YouTubeUri', () {
      final url = Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4');
      expect(
        YouTubeResolver.videoIdFromUri(url),
        YouTubeUri.videoIdFromUri(url),
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 7 — YouTube Shorts video ID extraction
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 7 — YouTube Shorts video ID extraction', () {
    test('YTS-001 youtube.com/shorts/ld4K5nw9gsk → ld4K5nw9gsk', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk'),
        ),
        'ld4K5nw9gsk',
      );
    });

    test('YTS-002 youtube.com/shorts/XFM4tCakAXY → XFM4tCakAXY', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtube.com/shorts/XFM4tCakAXY'),
        ),
        'XFM4tCakAXY',
      );
    });

    test('YTS-003 youtube.com/shorts/BxXzzAEEhCA → BxXzzAEEhCA', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtube.com/shorts/BxXzzAEEhCA'),
        ),
        'BxXzzAEEhCA',
      );
    });

    test('YTS-004 youtube.com/shorts/LNv4y3wPQA0 → LNv4y3wPQA0', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtube.com/shorts/LNv4y3wPQA0'),
        ),
        'LNv4y3wPQA0',
      );
    });

    test('YTS-005 youtube.com/shorts/hvmIZAvt3jE → hvmIZAvt3jE', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtube.com/shorts/hvmIZAvt3jE'),
        ),
        'hvmIZAvt3jE',
      );
    });

    test('YTS-006 youtube.com/shorts/MNRgAw45mTM → MNRgAw45mTM', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtube.com/shorts/MNRgAw45mTM'),
        ),
        'MNRgAw45mTM',
      );
    });

    test('YTS-007 www.youtube.com/shorts also works', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/shorts/ld4K5nw9gsk'),
        ),
        'ld4K5nw9gsk',
      );
    });

    test('YTS-008 Shorts URL is recognized as YouTube platform', () {
      for (final url in [
        'https://youtube.com/shorts/ld4K5nw9gsk',
        'https://youtube.com/shorts/XFM4tCakAXY',
        'https://youtube.com/shorts/BxXzzAEEhCA',
        'https://youtube.com/shorts/LNv4y3wPQA0',
        'https://youtube.com/shorts/hvmIZAvt3jE',
        'https://youtube.com/shorts/MNRgAw45mTM',
      ]) {
        final uri = Uri.parse(url);
        expect(
          SocialPlatform.fromUri(uri),
          SocialPlatform.youtube,
          reason: '$url should be detected as YouTube',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 8 — URL variations resolve to same video ID
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 8 — URL variations all resolve to same video ID', () {
    const expectedId = 'YE7VzlLtp-4';

    final variations = [
      'https://www.youtube.com/watch?v=YE7VzlLtp-4',
      'https://youtu.be/YE7VzlLtp-4',
      'https://www.youtube.com/watch?v=YE7VzlLtp-4&t=30s',
      'https://www.youtube.com/watch?v=YE7VzlLtp-4&feature=youtu.be',
    ];

    for (final url in variations) {
      test('$url → $expectedId', () {
        expect(
          YouTubeUri.videoIdFromUri(Uri.parse(url)),
          expectedId,
          reason: '$url should extract video ID $expectedId',
        );
      });
    }

    test('YT-VAR-001 all variations normalize to same watch URL', () {
      final normalized = <String>{};
      for (final url in variations) {
        final uri = Uri.parse(url);
        final id = YouTubeUri.videoIdFromUri(uri);
        normalized.add('https://www.youtube.com/watch?v=$id');
      }
      expect(normalized.length, 1,
          reason: 'All variations should normalize to the same canonical URL');
    });

    test('YT-VAR-002 SocialUrlUtils normalizes YouTube URLs', () {
      for (final url in variations) {
        final uri = Uri.parse(url);
        final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.youtube);
        expect(targets, isNotEmpty);
        expect(
          targets.first.toString(),
          'https://www.youtube.com/watch?v=$expectedId',
          reason: '$url should normalize to canonical watch URL',
        );
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Additional URL forms
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — Additional URL forms', () {
    test('YT-EMBED-001 /embed/ URL extracts video ID', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/embed/YE7VzlLtp-4'),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-LIVE-001 /live/ URL extracts video ID', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/live/YE7VzlLtp-4'),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-QUERY-001 extra query params do not break parsing', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse(
            'https://www.youtube.com/watch?v=YE7VzlLtp-4&list=RDabc&index=2',
          ),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-QUERY-002 youtu.be with si param extracts ID', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://youtu.be/YE7VzlLtp-4?si=abcdef123'),
        ),
        'YE7VzlLtp-4',
      );
    });

    test('YT-MOBILE-001 m.youtube.com extracts video ID', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://m.youtube.com/watch?v=YE7VzlLtp-4'),
        ),
        'YE7VzlLtp-4',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 12 — Invalid YouTube URLs
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 12 — Invalid YouTube URLs', () {
    test('YT-ERR-001 youtube.com homepage has no video ID', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/'),
        ),
        isNull,
      );
    });

    test('YT-ERR-002 youtube.com/watch without v= has no video ID', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/watch'),
        ),
        isNull,
      );
    });

    test('YT-ERR-003 youtube.com/watch?v= with empty v has no video ID', () {
      final id = YouTubeUri.videoIdFromUri(
        Uri.parse('https://www.youtube.com/watch?v='),
      );
      expect(id == null || id.isEmpty, isTrue);
    });

    test('YT-ERR-004 youtube.com homepage is still recognized as YouTube', () {
      final uri = Uri.parse('https://www.youtube.com/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.youtube);
    });

    test('YT-ERR-005 UrlValidator accepts YouTube URLs as valid HTTP', () {
      final validator = UrlValidator();
      expect(
        validator
            .validate('https://www.youtube.com/watch?v=INVALID_VIDEO_ID')
            .isValid,
        isTrue,
        reason: 'URL validation only checks scheme/host, not video existence',
      );
    });

    test('YT-ERR-006 UrlValidator rejects non-HTTP YouTube URLs', () {
      final validator = UrlValidator();
      expect(
        validator.validate('ftp://www.youtube.com/watch?v=abc').isValid,
        isFalse,
      );
    });

    test('YT-ERR-007 bare youtube.com/shorts/ with no ID', () {
      final uri = Uri.parse('https://youtube.com/shorts/');
      final id = YouTubeUri.videoIdFromUri(uri);
      expect(id == null || id.isEmpty, isTrue);
    });

    test('YT-ERR-008 youtu.be with no path has no video ID', () {
      final id = YouTubeUri.videoIdFromUri(
        Uri.parse('https://youtu.be/'),
      );
      expect(id == null || id.isEmpty, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — YouTube HTML extraction (offline unit tests)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — YouTubeResolver HTML extraction', () {
    test('YT-HTML-001 extracts googlevideo URL from rr prefix HTML', () {
      const html =
          'https://rr5---sn.test.googlevideo.com/videoplayback%3Fexpire%3D1%26itag%3D18%26source%3Dyt';
      final url = YouTubeResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('googlevideo.com'));
      expect(url, contains('itag=18'));
    });

    test('YT-HTML-002 extracts streamingUrl with unicode escapes', () {
      const html =
          '"streamingUrl":"https://rr7---sn.test.googlevideo.com/videoplayback?expire=1\\u0026itag=22\\u0026source=youtube\\u0026id=abc"';
      final url = YouTubeResolver.extractFromHtmlForTest(html);
      expect(url, isNotNull);
      expect(url, contains('itag=22'));
      expect(url, isNot(contains(r'\u0026')));
    });

    test('YT-HTML-003 rejects SABR streams', () {
      const html =
          '"streamingUrl":"https://rr7---sn.test.googlevideo.com/videoplayback?expire=1\\u0026sabr=1\\u0026sig=abc"';
      expect(YouTubeResolver.extractFromHtmlForTest(html), isNull);
    });

    test('YT-HTML-004 MediaExtractor extracts ytInitialPlayerResponse', () {
      const html = '''
        <script>
        var ytInitialPlayerResponse = {"streamingData":{"formats":[{"url":"https://rr1---sn.example.googlevideo.com/videoplayback?id=abc&itag=18","mimeType":"video/mp4"}]}};
        </script>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.youtube.com/watch?v=abc'),
        html: html,
        platform: SocialPlatform.youtube,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('googlevideo.com'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Content type detection (Shorts vs Standard)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — Content type detection gaps', () {
    test('YT-TYPE-001 no content type field on DiscoveredResource', () {
      // DiscoveredResource does not have a contentType or videoType field.
      // Standard videos and Shorts are not distinguished after URL parsing.
      // This documents the current limitation.
      final shortsUri = Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk');
      final watchUri =
          Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4');
      final shortsId = YouTubeUri.videoIdFromUri(shortsUri);
      final watchId = YouTubeUri.videoIdFromUri(watchUri);
      expect(shortsId, isNotNull);
      expect(watchId, isNotNull);
      // Both extract IDs but nothing distinguishes Shorts from standard
      // at the DiscoveredResource level.
    });

    test('YT-TYPE-002 /shorts/ path can be detected from original URL', () {
      final shortsUrl = 'https://youtube.com/shorts/ld4K5nw9gsk';
      final uri = Uri.parse(shortsUrl);
      final isShorts = uri.path.contains('/shorts/');
      expect(isShorts, isTrue);

      final watchUrl = 'https://www.youtube.com/watch?v=YE7VzlLtp-4';
      final watchUri = Uri.parse(watchUrl);
      final isNotShorts = watchUri.path.contains('/shorts/');
      expect(isNotShorts, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — URL normalization
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — URL normalization', () {
    test('YT-NORM-001 Shorts URL normalizes to watch URL', () {
      final shortsUri = Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk');
      final targets =
          SocialUrlUtils.fetchTargets(shortsUri, SocialPlatform.youtube);
      expect(targets.first.toString(),
          'https://www.youtube.com/watch?v=ld4K5nw9gsk');
    });

    test('YT-NORM-002 youtu.be normalizes to watch URL', () {
      final shortUri = Uri.parse('https://youtu.be/YE7VzlLtp-4');
      final targets =
          SocialUrlUtils.fetchTargets(shortUri, SocialPlatform.youtube);
      expect(targets.first.toString(),
          'https://www.youtube.com/watch?v=YE7VzlLtp-4');
    });

    test('YT-NORM-003 embed URL is included in fetch targets', () {
      final watchUri =
          Uri.parse('https://www.youtube.com/watch?v=YE7VzlLtp-4');
      final targets =
          SocialUrlUtils.fetchTargets(watchUri, SocialPlatform.youtube);
      expect(targets.length, 3);
      expect(
        targets.any((u) => u.path.contains('/embed/')),
        isTrue,
      );
    });
  });
}
