import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 1 / 2 / 13 / 16 / 17 — TikTok URL parsing, normalization, short URL
/// host recognition, player URL classification, invalid URLs, and security.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Platform detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — TikTok platform detection', () {
    test('TT-URL-001 www.tiktok.com/@user/video is TikTok', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'TikTok');
    });

    test('TT-URL-002 m.tiktok.com is TikTok', () {
      final uri = Uri.parse(
        'https://m.tiktok.com/v/6718335390845095173.html',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('TT-URL-003 vm.tiktok.com is TikTok', () {
      final uri = Uri.parse('https://vm.tiktok.com/ZMabcdef/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('TT-URL-004 vt.tiktok.com is TikTok', () {
      final uri = Uri.parse('https://vt.tiktok.com/ZSabcdef/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('TT-URL-005 t.tiktok.com is TikTok', () {
      final uri = Uri.parse('https://t.tiktok.com/ZSabcdef/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('TT-URL-006 bare tiktok.com is TikTok', () {
      final uri = Uri.parse('https://tiktok.com/@user/video/123');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-URL-007 player URL is TikTok platform', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/player/v1/6718335390845095173',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('TT-URL-008 non-TikTok host is not TikTok', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.youtube.com/watch?v=abc')),
        isNot(SocialPlatform.tiktok),
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.example.com/test')),
        isNull,
      );
      expect(
        ContentProviderRegistry.canHandle(Uri.parse('https://www.example.com/test')),
        isFalse,
      );
    });

    test('TT-URL-009 TikTok homepage is still recognized as TikTok', () {
      final uri = Uri.parse('https://www.tiktok.com/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-URL-010 TikTok profile URL is still recognized as TikTok', () {
      final uri = Uri.parse('https://www.tiktok.com/@scout2015');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Video ID extraction
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — TikTok video ID extraction', () {
    test('TT-001 standard video URL → 6718335390845095173', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://www.tiktok.com/@scout2015/video/6718335390845095173'),
        ),
        '6718335390845095173',
      );
    });

    test('TT-ID-002 TikTokResolver.videoIdFromUri matches TikTokUri', () {
      final url = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      expect(
        TikTokResolver.videoIdFromUri(url),
        TikTokUri.videoIdFromUri(url),
      );
    });

    test('TT-003 URL with query parameters → same video ID', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse(
            'https://www.tiktok.com/@scout2015/video/6718335390845095173?_r=1&_t=8ZqWxYvBmN3',
          ),
        ),
        '6718335390845095173',
      );
    });

    test('TT-ID-004 URL with is_from_webapp query → video ID preserved', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse(
            'https://www.tiktok.com/@hshs63690/video/7673099286178958610?is_from_webapp=1&sender_device=pc',
          ),
        ),
        '7673099286178958610',
      );
    });

    test('TT-ID-005 mobile /v/ path → video ID', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://m.tiktok.com/v/6718335390845095173.html'),
        ),
        '6718335390845095173',
      );
    });

    test('TT-ID-006 bare tiktok.com with /video/ path → video ID', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://tiktok.com/@user/video/7643276616088440071'),
        ),
        '7643276616088440071',
      );
    });

    test('TT-ID-007 different username same video ID pattern', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse(
            'https://www.tiktok.com/@twice_tiktok_official/video/7334344147525963015',
          ),
        ),
        '7334344147525963015',
      );
    });

    test('TT-002 player URL does not yield video ID via /video/ regex', () {
      final id = TikTokUri.videoIdFromUri(
        Uri.parse('https://www.tiktok.com/player/v1/6718335390845095173'),
      );
      // The /player/v1/{id} path does not match /video/(\d+) or /v/(\d+)
      // because the path is /player/v1/... not /video/... or /v/...
      // v1 is parsed as text "1" by /v/(\d+) — but the full path is /player/v1/{id}
      // This depends on whether the regex matches a sub-path.
      // Current regex: RegExp(r'/v/(\d+)') will match /v/1 in /player/v1/...
      // Let's verify actual behavior.
      if (id != null) {
        // If it extracts something, it would be '1' from /v/1 not the actual video ID
        expect(id, isNot('6718335390845095173'),
            reason: 'Player URL should not extract the full video ID from /video/ pattern');
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Username extraction
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — TikTok username extraction', () {
    test('TT-USER-001 username from standard URL path', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      final match = RegExp(r'/@([^/]+)/').firstMatch(uri.path);
      expect(match?.group(1), 'scout2015');
    });

    test('TT-USER-002 username with underscores', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@twice_tiktok_official/video/7334344147525963015',
      );
      final match = RegExp(r'/@([^/]+)/').firstMatch(uri.path);
      expect(match?.group(1), 'twice_tiktok_official');
    });

    test('TT-USER-003 username with mixed characters', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@hshs63690/video/7673099286178958610',
      );
      final match = RegExp(r'/@([^/]+)/').firstMatch(uri.path);
      expect(match?.group(1), 'hshs63690');
    });

    test('TT-USER-004 no username in short URL', () {
      final uri = Uri.parse('https://vm.tiktok.com/ZMabcdef/');
      final match = RegExp(r'/@([^/]+)/').firstMatch(uri.path);
      expect(match, isNull);
    });

    test('TT-USER-005 no username in mobile URL', () {
      final uri = Uri.parse('https://m.tiktok.com/v/6718335390845095173.html');
      final match = RegExp(r'/@([^/]+)/').firstMatch(uri.path);
      expect(match, isNull);
    });

    test('TT-USER-006 no username in player URL', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/player/v1/6718335390845095173',
      );
      final match = RegExp(r'/@([^/]+)/').firstMatch(uri.path);
      expect(match, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Short URL host recognition
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — Short URL host recognition', () {
    test('TT-SHORT-001 vm.tiktok.com detected as TikTok', () {
      final uri = Uri.parse('https://vm.tiktok.com/ZMabcdef/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-SHORT-002 vt.tiktok.com detected as TikTok', () {
      final uri = Uri.parse('https://vt.tiktok.com/ZSabcdef/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-SHORT-003 t.tiktok.com detected as TikTok', () {
      final uri = Uri.parse('https://t.tiktok.com/ZSabcdef/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-SHORT-004 short URL has no video ID before redirect', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://vm.tiktok.com/ZMabcdef/'),
        ),
        isNull,
      );
    });

    test('TT-SHORT-005 vt short URL has no video ID before redirect', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://vt.tiktok.com/ZSabcdef/'),
        ),
        isNull,
      );
    });

    test('TT-SHORT-006 t short URL has no video ID before redirect', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://t.tiktok.com/ZSabcdef/'),
        ),
        isNull,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 2 — URL normalization
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 2 — URL normalization', () {
    const expectedId = '6718335390845095173';

    final variations = [
      'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      'https://www.tiktok.com/@scout2015/video/6718335390845095173?_r=1&_t=8ZqWxYvBmN3',
    ];

    for (final url in variations) {
      test('$url → $expectedId', () {
        expect(
          TikTokUri.videoIdFromUri(Uri.parse(url)),
          expectedId,
          reason: '$url should extract video ID $expectedId',
        );
      });
    }

    test('TT-NORM-001 both URL variations extract same video ID', () {
      final ids = <String>{};
      for (final url in variations) {
        final id = TikTokUri.videoIdFromUri(Uri.parse(url));
        if (id != null) ids.add(id);
      }
      expect(ids.length, 1,
          reason: 'All variations should extract the same video ID');
      expect(ids.first, expectedId);
    });

    test('TT-NORM-002 fetchTargets includes canonical URL', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.tiktok);
      expect(targets, isNotEmpty);
      expect(
        targets.any((t) => t.path.contains('/video/$expectedId')),
        isTrue,
      );
    });

    test('TT-NORM-003 fetchTargets includes mobile URL', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.tiktok);
      expect(
        targets.any((t) =>
            t.host == 'm.tiktok.com' && t.path.contains('/v/$expectedId')),
        isTrue,
      );
    });

    test('TT-NORM-004 fetchTargets includes generic @_ URL', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.tiktok);
      expect(
        targets.any((t) => t.path.contains('/@_/video/$expectedId')),
        isTrue,
      );
    });

    test('TT-NORM-005 URL with query params produces same fetch targets as clean URL', () {
      final cleanUri = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173',
      );
      final queryUri = Uri.parse(
        'https://www.tiktok.com/@scout2015/video/6718335390845095173?_r=1&_t=8ZqWxYvBmN3',
      );
      final cleanTargets = SocialUrlUtils.fetchTargets(cleanUri, SocialPlatform.tiktok);
      final queryTargets = SocialUrlUtils.fetchTargets(queryUri, SocialPlatform.tiktok);

      final cleanVideoTargets = cleanTargets
          .where((t) => t.path.contains('/@_/video/'))
          .map((t) => t.toString())
          .toSet();
      final queryVideoTargets = queryTargets
          .where((t) => t.path.contains('/@_/video/'))
          .map((t) => t.toString())
          .toSet();
      expect(cleanVideoTargets, queryVideoTargets);
    });

    test('TT-NORM-006 short URL without video ID produces no extra targets', () {
      final uri = Uri.parse('https://vm.tiktok.com/ZMabcdef/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.tiktok);
      // Without a video ID, targets should only contain the original URI
      expect(targets.length, 1);
      expect(targets.first.toString(), uri.toString());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 13 — Invalid TikTok URLs
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 13 — Invalid TikTok URLs', () {
    test('TT-ERR-001 tiktok.com homepage has no video ID', () {
      expect(
        TikTokUri.videoIdFromUri(Uri.parse('https://www.tiktok.com/')),
        isNull,
      );
    });

    test('TT-ERR-002 profile URL has no video ID', () {
      expect(
        TikTokUri.videoIdFromUri(Uri.parse('https://www.tiktok.com/@scout2015')),
        isNull,
      );
    });

    test('TT-ERR-003 /video/ with no ID returns null', () {
      final id = TikTokUri.videoIdFromUri(
        Uri.parse('https://www.tiktok.com/@scout2015/video/'),
      );
      expect(id, isNull);
    });

    test('TT-ERR-004 /video/INVALID (non-numeric) returns null', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://www.tiktok.com/@scout2015/video/INVALID'),
        ),
        isNull,
      );
    });

    test('TT-ERR-005 invalid short URL is still recognized as TikTok host', () {
      final uri = Uri.parse('https://vm.tiktok.com/INVALID');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-ERR-006 non-TikTok URL returns null for platform', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://example.com/test')),
        isNull,
      );
    });

    test('TT-ERR-007 UrlValidator accepts TikTok URLs as valid HTTP', () {
      final validator = UrlValidator();
      expect(
        validator.validate(
          'https://www.tiktok.com/@scout2015/video/6718335390845095173',
        ).isValid,
        isTrue,
      );
    });

    test('TT-ERR-008 UrlValidator accepts short TikTok URLs', () {
      final validator = UrlValidator();
      expect(
        validator.validate('https://vm.tiktok.com/ZMabcdef/').isValid,
        isTrue,
      );
    });

    test('TT-ERR-009 /video/ followed by letters is not a valid video ID', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse('https://www.tiktok.com/@invalid/video/abc123'),
        ),
        isNull,
        reason: r'Regex /video/(\d+) requires all digits',
      );
    });

    test('TT-ERR-010 /video/123 with tiny numeric ID still extracts', () {
      // The regex does not enforce minimum length — any digits match
      final id = TikTokUri.videoIdFromUri(
        Uri.parse('https://www.tiktok.com/@invalid/video/123'),
      );
      expect(id, '123');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 16 — Security
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 16 — Security: malformed and dangerous URLs', () {
    test('TT-SEC-001 javascript: URL not recognized as TikTok', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('javascript:alert(1)')),
        isNull,
      );
    });

    test('TT-SEC-002 file: URL not recognized as TikTok', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('file:///etc/passwd')),
        isNull,
      );
    });

    test('TT-SEC-003 localhost URL not recognized as TikTok', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://localhost/video/123')),
        isNull,
      );
    });

    test('TT-SEC-004 private IP URL not recognized as TikTok', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('http://192.168.1.1/video/123')),
        isNull,
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('http://10.0.0.1/video/123')),
        isNull,
      );
    });

    test('TT-SEC-005 ftp: URL rejected by UrlValidator', () {
      final validator = UrlValidator();
      expect(
        validator.validate('ftp://www.tiktok.com/@user/video/123').isValid,
        isFalse,
      );
    });

    test('TT-SEC-006 excessively long URL still parses without crash', () {
      final longPath = 'a' * 5000;
      final uri = Uri.tryParse('https://www.tiktok.com/$longPath');
      if (uri != null) {
        // Should not crash, may or may not detect as TikTok
        SocialPlatform.fromUri(uri);
        TikTokUri.videoIdFromUri(uri);
      }
    });

    test('TT-SEC-007 URL with null bytes does not crash', () {
      final uri = Uri.tryParse('https://www.tiktok.com/@user/video/123%00evil');
      if (uri != null) {
        expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
        // Video ID extraction should handle this gracefully
        TikTokUri.videoIdFromUri(uri);
      }
    });

    test('TT-SEC-008 URL with fragment does not break video ID extraction', () {
      expect(
        TikTokUri.videoIdFromUri(
          Uri.parse(
            'https://www.tiktok.com/@scout2015/video/6718335390845095173#comments',
          ),
        ),
        '6718335390845095173',
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 17 — Player/embed URL classification
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 17 — Player/embed URL classification', () {
    test('TT-PLAYER-001 player URL detected as TikTok platform', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/player/v1/6718335390845095173',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-PLAYER-002 player URL path does not contain /video/', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/player/v1/6718335390845095173',
      );
      expect(uri.path.contains('/video/'), isFalse);
    });

    test('TT-PLAYER-003 player URL video ID not in /video/ position', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/player/v1/6718335390845095173',
      );
      final id = TikTokUri.videoIdFromUri(uri);
      // /player/v1/{id} — the regex /video/(\d+) won't match this
      // but /v/(\d+) could match /v/1 — extracting '1' not the real ID
      if (id != null) {
        expect(id, isNot('6718335390845095173'),
            reason: '/player/v1/ path should not extract the target video ID');
      }
    });

    test('TT-PLAYER-004 /embed/ path detected as TikTok platform', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/embed/v2/6718335390845095173',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });
  });
}
