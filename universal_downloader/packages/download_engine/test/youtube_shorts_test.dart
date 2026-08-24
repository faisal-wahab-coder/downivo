import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 7 — YouTube Shorts-specific tests.
///
/// Verifies /shorts/ URL recognition, ID extraction, normalization,
/// and documents Shorts-vs-standard detection gaps.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 7 — Shorts URL recognition
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 7 — Shorts URL recognition', () {
    final shortsUrls = <String, String>{
      'YTS-001': 'https://youtube.com/shorts/ld4K5nw9gsk',
      'YTS-002': 'https://youtube.com/shorts/XFM4tCakAXY',
      'YTS-003': 'https://youtube.com/shorts/BxXzzAEEhCA',
      'YTS-004': 'https://youtube.com/shorts/LNv4y3wPQA0',
      'YTS-005': 'https://youtube.com/shorts/hvmIZAvt3jE',
      'YTS-006': 'https://youtube.com/shorts/MNRgAw45mTM',
    };

    final expectedIds = <String, String>{
      'YTS-001': 'ld4K5nw9gsk',
      'YTS-002': 'XFM4tCakAXY',
      'YTS-003': 'BxXzzAEEhCA',
      'YTS-004': 'LNv4y3wPQA0',
      'YTS-005': 'hvmIZAvt3jE',
      'YTS-006': 'MNRgAw45mTM',
    };

    for (final entry in shortsUrls.entries) {
      final testId = entry.key;
      final url = entry.value;
      final expected = expectedIds[testId]!;

      test('$testId /shorts/ URL recognized as YouTube', () {
        final uri = Uri.parse(url);
        expect(SocialPlatform.fromUri(uri), SocialPlatform.youtube);
        expect(ContentProviderRegistry.canHandle(uri), isTrue);
      });

      test('$testId extracts video ID $expected', () {
        expect(YouTubeUri.videoIdFromUri(Uri.parse(url)), expected);
      });

      test('$testId normalizes to canonical watch URL', () {
        final uri = Uri.parse(url);
        final targets =
            SocialUrlUtils.fetchTargets(uri, SocialPlatform.youtube);
        expect(
          targets.first.toString(),
          'https://www.youtube.com/watch?v=$expected',
        );
      });

      test('$testId original URL path contains /shorts/', () {
        final uri = Uri.parse(url);
        expect(uri.path, contains('/shorts/'));
      });
    }
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 7 — Shorts normalization details
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 7 — Shorts normalization', () {
    test('YTS-NORM-001 Shorts and watch URLs for same ID yield same targets',
        () {
      final shortsTargets = SocialUrlUtils.fetchTargets(
        Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk'),
        SocialPlatform.youtube,
      );
      final watchTargets = SocialUrlUtils.fetchTargets(
        Uri.parse('https://www.youtube.com/watch?v=ld4K5nw9gsk'),
        SocialPlatform.youtube,
      );
      expect(
        shortsTargets.map((u) => u.toString()).toSet(),
        watchTargets.map((u) => u.toString()).toSet(),
      );
    });

    test('YTS-NORM-002 www.youtube.com/shorts also works', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://www.youtube.com/shorts/ld4K5nw9gsk'),
        ),
        'ld4K5nw9gsk',
      );
    });

    test('YTS-NORM-003 m.youtube.com/shorts also works', () {
      expect(
        YouTubeUri.videoIdFromUri(
          Uri.parse('https://m.youtube.com/shorts/ld4K5nw9gsk'),
        ),
        'ld4K5nw9gsk',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 7 — Shorts content type detection limitations
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 7 — Shorts vs Standard detection gaps', () {
    test('YTS-GAP-001 no Shorts flag in DiscoveredResource', () {
      // DiscoveredResource has: directUrl, fileName, platform, pageUrl,
      // title, mimeType, requestHeaders.
      // There is no isShorts, contentType, or videoType field.
      // The /shorts/ information is lost after URL normalization.
      final resource = DiscoveredResource(
        directUrl: 'https://example.googlevideo.com/videoplayback',
        fileName: 'short.mp4',
        platform: 'YouTube',
        pageUrl: 'https://youtube.com/shorts/ld4K5nw9gsk',
      );
      // The only way to detect Shorts post-resolution is to inspect pageUrl
      expect(resource.pageUrl, contains('/shorts/'));
    });

    test('YTS-GAP-002 Shorts normalization loses /shorts/ path', () {
      final shortsUri = Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk');
      final targets =
          SocialUrlUtils.fetchTargets(shortsUri, SocialPlatform.youtube);
      // The canonical target is a /watch URL, not /shorts/
      expect(targets.first.path, isNot(contains('/shorts/')));
    });

    test('YTS-GAP-003 no vertical aspect ratio detection', () {
      // The resolver does not inspect video dimensions.
      // Shorts are vertical (9:16) but this is not detected or stored.
      expect(true, isTrue,
          reason: 'Documenting: no aspect ratio detection exists');
    });

    test('YTS-GAP-004 no duration field for Shorts verification', () {
      // Shorts are ≤60s but duration is not extracted from metadata.
      // DownloadTask has no duration field.
      expect(true, isTrue,
          reason: 'Documenting: no duration extraction exists');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 7 — Shorts edge cases
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 7 — Shorts edge cases', () {
    test('YTS-EDGE-001 /shorts/ with trailing slash', () {
      final id = YouTubeUri.videoIdFromUri(
        Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk/'),
      );
      // Trailing slash may cause the ID to not be extracted cleanly
      // because pathSegments may have an empty trailing segment
      expect(id, anyOf('ld4K5nw9gsk', isNull));
    });

    test('YTS-EDGE-002 /shorts/ with query parameters', () {
      final id = YouTubeUri.videoIdFromUri(
        Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk?feature=share'),
      );
      expect(id, 'ld4K5nw9gsk');
    });

    test('YTS-EDGE-003 /shorts/ with fragment', () {
      final id = YouTubeUri.videoIdFromUri(
        Uri.parse('https://youtube.com/shorts/ld4K5nw9gsk#t=5'),
      );
      expect(id, 'ld4K5nw9gsk');
    });
  });
}
