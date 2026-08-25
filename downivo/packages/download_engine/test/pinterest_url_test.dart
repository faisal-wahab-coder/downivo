import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinterest URL parsing, classification, normalization, pin ID extraction,
/// and platform detection. Offline — no network.
void main() {
  group('Phase 1 — Pinterest platform detection', () {
    test('PT-URL-001 www.pinterest.com is Pinterest', () {
      final uri = Uri.parse('https://www.pinterest.com/pin/123456789/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Pinterest');
    });

    test('PT-URL-002 pinterest.com (no www) is Pinterest', () {
      final uri = Uri.parse('https://pinterest.com/pin/123456789/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
    });

    test('PT-URL-003 m.pinterest.com is Pinterest', () {
      final uri = Uri.parse('https://m.pinterest.com/pin/123456789/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
    });

    test('PT-URL-004 pin.it short URL is Pinterest', () {
      final uri = Uri.parse('https://pin.it/AbCdEfG');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('PT-URL-005 i.pinimg.com direct image is Pinterest', () {
      final uri = Uri.parse(
        'https://i.pinimg.com/originals/ab/cd/ef/photo.jpg',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
    });

    test('PT-URL-006 v1.pinimg.com direct video is Pinterest', () {
      final uri = Uri.parse(
        'https://v1.pinimg.com/videos/mc/720p/clip.mp4',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
    });

    test('PT-URL-007 pinterest.co.uk is Pinterest', () {
      final uri = Uri.parse('https://www.pinterest.co.uk/pin/123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
    });

    test('PT-URL-008 pinterest.com.au is Pinterest', () {
      final uri = Uri.parse('https://www.pinterest.com.au/pin/123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
    });

    test('PT-URL-009 ar.pinterest.com is Pinterest', () {
      final uri = Uri.parse('https://ar.pinterest.com/pin/123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.pinterest);
    });

    test('PT-URL-010 non-Pinterest host is rejected', () {
      final uri = Uri.parse('https://www.example.com/pin/123/');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('PT-URL-011 youtube.com is NOT Pinterest', () {
      final uri = Uri.parse('https://www.youtube.com/watch?v=abc');
      expect(SocialPlatform.fromUri(uri), isNot(SocialPlatform.pinterest));
    });
  });

  group('Phase 2 — Content type classification', () {
    test('PT-URL-020 home page is HOME', () {
      expect(
        PinterestUri.classifyUrl(Uri.parse('https://www.pinterest.com/')),
        PinterestContentType.home,
      );
      expect(
        PinterestResolver.classifyUrl(Uri.parse('https://www.pinterest.com/')),
        PinterestContentType.home,
      );
    });

    test('PT-URL-021 canonical pin URL is PIN', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse('https://www.pinterest.com/pin/123456789/a-slug/'),
        ),
        PinterestContentType.pin,
      );
    });

    test('PT-URL-022 /pin/ without ID is non-content', () {
      expect(
        PinterestUri.classifyUrl(Uri.parse('https://www.pinterest.com/pin/')),
        PinterestContentType.nonContent,
      );
    });

    test('PT-URL-023 board URL is BOARD', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse('https://www.pinterest.com/user/my-board/'),
        ),
        PinterestContentType.board,
      );
    });

    test('PT-URL-024 profile URL is PROFILE', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse('https://www.pinterest.com/someuser/'),
        ),
        PinterestContentType.profile,
      );
    });

    test('PT-URL-025 profile _saved is PROFILE', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse('https://www.pinterest.com/someuser/_saved/'),
        ),
        PinterestContentType.profile,
      );
    });

    test('PT-URL-026 pin.it is SHORT_URL', () {
      expect(
        PinterestUri.classifyUrl(Uri.parse('https://pin.it/AbCdEfG')),
        PinterestContentType.shortUrl,
      );
    });

    test('PT-URL-027 i.pinimg.com is DIRECT_MEDIA', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse('https://i.pinimg.com/736x/ab/cd/ef/x.jpg'),
        ),
        PinterestContentType.directMedia,
      );
    });

    test('PT-URL-028 search is SEARCH', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse('https://www.pinterest.com/search/pins/?q=cats'),
        ),
        PinterestContentType.search,
      );
    });

    test('PT-URL-029 ideas hub is non-content', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse('https://www.pinterest.com/ideas/'),
        ),
        PinterestContentType.nonContent,
      );
    });

    test('PT-URL-030 share /sent/ path is still PIN', () {
      expect(
        PinterestUri.classifyUrl(
          Uri.parse(
            'https://www.pinterest.com/pin/123456789/sent/?invite_code=abc',
          ),
        ),
        PinterestContentType.pin,
      );
    });
  });

  group('Phase 3 — Pin ID extraction (slug ignored)', () {
    test('PT-URL-040 extracts pin ID from canonical URL', () {
      final uri = Uri.parse(
        'https://www.pinterest.com/pin/580547278694592554/this-slug-ignored/',
      );
      expect(PinterestUri.pinIdFromUri(uri), '580547278694592554');
    });

    test('PT-URL-041 extracts pin ID without slug', () {
      final uri = Uri.parse('https://www.pinterest.com/pin/580547278694592554/');
      expect(PinterestUri.pinIdFromUri(uri), '580547278694592554');
    });

    test('PT-URL-042 extracts pin ID from /sent/ share URL', () {
      final uri = Uri.parse(
        'https://www.pinterest.com/pin/580547278694592554/sent/?invite_code=x',
      );
      expect(PinterestUri.pinIdFromUri(uri), '580547278694592554');
    });

    test('PT-URL-043 pin.it has no pin ID until redirect', () {
      expect(
        PinterestUri.pinIdFromUri(Uri.parse('https://pin.it/AbCdEfG')),
        isNull,
      );
    });

    test('PT-URL-044 home has no pin ID', () {
      expect(
        PinterestUri.pinIdFromUri(Uri.parse('https://www.pinterest.com/')),
        isNull,
      );
    });

    test('PT-URL-045 INVALID token is still extracted (resolver fails later)', () {
      expect(
        PinterestUri.pinIdFromUri(
          Uri.parse('https://www.pinterest.com/pin/INVALID/'),
        ),
        'INVALID',
      );
    });

    test('PT-URL-046 short code from pin.it', () {
      expect(
        PinterestUri.shortCodeFromUri(Uri.parse('https://pin.it/AbCdEfG')),
        'AbCdEfG',
      );
    });
  });

  group('Phase 4 — Board / profile extraction', () {
    test('PT-URL-050 extracts username from profile', () {
      expect(
        PinterestUri.usernameFromUri(
          Uri.parse('https://www.pinterest.com/designuser/'),
        ),
        'designuser',
      );
    });

    test('PT-URL-051 extracts username and board slug', () {
      final uri = Uri.parse('https://www.pinterest.com/designuser/home-ideas/');
      expect(PinterestUri.usernameFromUri(uri), 'designuser');
      expect(PinterestUri.boardSlugFromUri(uri), 'home-ideas');
    });

    test('PT-URL-052 pin URL has no board slug', () {
      expect(
        PinterestUri.boardSlugFromUri(
          Uri.parse('https://www.pinterest.com/pin/123/'),
        ),
        isNull,
      );
    });

    test('PT-URL-053 pin URL has no username', () {
      expect(
        PinterestUri.usernameFromUri(
          Uri.parse('https://www.pinterest.com/pin/123/'),
        ),
        isNull,
      );
    });
  });

  group('Phase 5 — URL normalization', () {
    test('PT-URL-060 strips tracking params and slug', () {
      final uri = Uri.parse(
        'https://www.pinterest.com/pin/123456789/pretty-slug/'
        '?utm_source=share&fbclid=abc',
      );
      final normalized = PinterestUri.normalize(uri);
      expect(normalized.host, 'www.pinterest.com');
      expect(normalized.path, '/pin/123456789/');
      expect(normalized.query, isEmpty);
    });

    test('PT-URL-061 mobile host canonicalizes to www', () {
      final uri = Uri.parse('https://m.pinterest.com/pin/123456789/');
      expect(
        PinterestUri.normalize(uri).toString(),
        'https://www.pinterest.com/pin/123456789/',
      );
    });

    test('PT-URL-062 regional host canonicalizes pin URL', () {
      final uri = Uri.parse('https://www.pinterest.co.uk/pin/123456789/');
      expect(
        PinterestUri.normalize(uri).toString(),
        'https://www.pinterest.com/pin/123456789/',
      );
    });

    test('PT-URL-063 pin.it is left for redirect resolution', () {
      final uri = Uri.parse('https://pin.it/AbCdEfG');
      expect(PinterestUri.normalize(uri).host, 'pin.it');
    });

    test('PT-URL-064 share /sent/ normalizes to pin path', () {
      final uri = Uri.parse(
        'https://www.pinterest.com/pin/123456789/sent/?invite_code=zz',
      );
      expect(
        PinterestUri.normalize(uri).toString(),
        'https://www.pinterest.com/pin/123456789/',
      );
    });

    test('PT-URL-065 query-only pin keeps identity', () {
      final a = PinterestUri.normalize(
        Uri.parse('https://www.pinterest.com/pin/123/?utm_medium=ios'),
      );
      final b = PinterestUri.normalize(
        Uri.parse('https://www.pinterest.com/pin/123/'),
      );
      expect(a, b);
    });
  });

  group('Phase 6 — Duplicate identity', () {
    test('PT-URL-070 canonical and slug URLs share pin identity', () {
      final a = Uri.parse('https://www.pinterest.com/pin/123456789/');
      final b = Uri.parse(
        'https://www.pinterest.com/pin/123456789/a-pretty-slug/?utm_source=x',
      );
      expect(
        PinterestUri.contentIdentity(a),
        PinterestUri.contentIdentity(PinterestUri.normalize(b)),
      );
      expect(PinterestUri.contentIdentity(a), 'pinterest:pin:123456789');
    });

    test('PT-URL-071 different pins have different identities', () {
      expect(
        PinterestUri.contentIdentity(
          Uri.parse('https://www.pinterest.com/pin/111/'),
        ),
        isNot(
          PinterestUri.contentIdentity(
            Uri.parse('https://www.pinterest.com/pin/222/'),
          ),
        ),
      );
    });

    test('PT-URL-072 pin.it identity uses short code until resolved', () {
      expect(
        PinterestUri.contentIdentity(Uri.parse('https://pin.it/AbCdEfG')),
        'pinterest:short:AbCdEfG',
      );
    });

    test('PT-URL-073 board identity uses user/board', () {
      expect(
        PinterestUri.contentIdentity(
          Uri.parse('https://www.pinterest.com/user/my-board/'),
        ),
        'pinterest:board:user/my-board',
      );
    });

    test('PT-URL-074 profile identity', () {
      expect(
        PinterestUri.contentIdentity(
          Uri.parse('https://www.pinterest.com/user/'),
        ),
        'pinterest:profile:user',
      );
    });

    test('PT-URL-075 home identity is null', () {
      expect(
        PinterestUri.contentIdentity(Uri.parse('https://www.pinterest.com/')),
        isNull,
      );
    });
  });

  group('Phase 7 — Downloadable vs not', () {
    test('PT-URL-080 pins are downloadable', () {
      expect(
        PinterestUri.isDownloadable(
          Uri.parse('https://www.pinterest.com/pin/123/'),
        ),
        isTrue,
      );
    });

    test('PT-URL-081 home is not downloadable', () {
      expect(
        PinterestUri.isDownloadable(Uri.parse('https://www.pinterest.com/')),
        isFalse,
      );
    });

    test('PT-URL-082 board is not downloadable', () {
      expect(
        PinterestUri.isDownloadable(
          Uri.parse('https://www.pinterest.com/user/board/'),
        ),
        isFalse,
      );
    });

    test('PT-URL-083 profile is not downloadable', () {
      expect(
        PinterestUri.isDownloadable(
          Uri.parse('https://www.pinterest.com/user/'),
        ),
        isFalse,
      );
    });

    test('PT-URL-084 pin.it is downloadable (after redirect)', () {
      expect(
        PinterestUri.isDownloadable(Uri.parse('https://pin.it/AbCdEfG')),
        isTrue,
      );
    });

    test('PT-URL-085 direct media is downloadable', () {
      expect(
        PinterestUri.isDownloadable(
          Uri.parse('https://i.pinimg.com/originals/a.jpg'),
        ),
        isTrue,
      );
    });
  });

  group('Phase 8 — Image URL upgrade', () {
    test('PT-URL-090 736x upgrades to originals', () {
      expect(
        PinterestUri.upgradeImageUrl(
          'https://i.pinimg.com/736x/ab/cd/ef/photo.jpg',
        ),
        'https://i.pinimg.com/originals/ab/cd/ef/photo.jpg',
      );
    });

    test('PT-URL-091 originals is unchanged', () {
      const url = 'https://i.pinimg.com/originals/ab/cd/ef/photo.jpg';
      expect(PinterestUri.upgradeImageUrl(url), url);
    });

    test('PT-URL-092 video CDN path is not rewritten as originals', () {
      const url = 'https://v1.pinimg.com/videos/mc/720p/clip.mp4';
      expect(PinterestUri.upgradeImageUrl(url), url);
    });

    test('PT-URL-093 non-pinimg URL is unchanged', () {
      const url = 'https://example.com/736x/photo.jpg';
      expect(PinterestUri.upgradeImageUrl(url), url);
    });
  });

  group('Phase 9 — Fetch targets', () {
    test('PT-URL-100 pin URL includes www and m targets', () {
      final targets = SocialUrlUtils.fetchTargets(
        Uri.parse('https://www.pinterest.com/pin/123/'),
        SocialPlatform.pinterest,
      );
      expect(targets.map((u) => u.toString()), contains(contains('/pin/123')));
    });
  });
}
