import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 1 / 2 / 17 / 18 — Instagram URL parsing, shortcode extraction,
/// content kind detection, URL normalization, embed targets, invalid URLs,
/// and security.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Platform detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — Instagram platform detection', () {
    test('IG-URL-001 www.instagram.com/reel/ is Instagram', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Instagram');
    });

    test('IG-URL-002 www.instagram.com/p/ is Instagram', () {
      final uri = Uri.parse('https://www.instagram.com/p/XYZ789/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('IG-URL-003 www.instagram.com/tv/ is Instagram', () {
      final uri = Uri.parse('https://www.instagram.com/tv/DEF456/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('IG-URL-004 www.instagram.com/stories/ is Instagram', () {
      final uri =
          Uri.parse('https://www.instagram.com/stories/username/12345/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('IG-URL-005 www.instagram.com/<username>/ is Instagram', () {
      final uri = Uri.parse('https://www.instagram.com/instagram/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('IG-URL-006 bare instagram.com is Instagram', () {
      final uri = Uri.parse('https://instagram.com/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('IG-URL-007 subdomain (l.instagram.com) is Instagram', () {
      final uri = Uri.parse('https://l.instagram.com/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('IG-URL-008 m.instagram.com is Instagram', () {
      final uri = Uri.parse('https://m.instagram.com/p/XYZ789/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
    });

    test('IG-URL-009 non-Instagram host is not Instagram', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.youtube.com/watch?v=abc')),
        isNot(SocialPlatform.instagram),
      );
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.example.com/reel/ABC/')),
        isNull,
      );
      expect(
        ContentProviderRegistry.canHandle(
          Uri.parse('https://www.example.com/reel/ABC/'),
        ),
        isFalse,
      );
    });

    test('IG-URL-010 Instagram homepage is still recognized as Instagram', () {
      final uri = Uri.parse('https://www.instagram.com/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Shortcode extraction
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — Instagram shortcode extraction', () {
    test('IG-SC-001 /reel/<shortcode>/ extracts shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/reel/CxY1aBcDeF/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CxY1aBcDeF');
    });

    test('IG-SC-002 /p/<shortcode>/ extracts shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/p/BcDeFgHiJk/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'BcDeFgHiJk');
    });

    test('IG-SC-003 /tv/<shortcode>/ extracts shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/tv/LmNoPqRsTu/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'LmNoPqRsTu');
    });

    test('IG-SC-004 shortcode with trailing slash', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });

    test('IG-SC-005 shortcode without trailing slash', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });

    test('IG-SC-006 shortcode with query parameters preserved', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?utm_source=ig_web_copy_link',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });

    test('IG-SC-007 shortcode with igsh parameter preserved', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?igsh=MXRhY2Z0dG8=',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });

    test('IG-SC-008 shortcode with multiple query params', () {
      final uri = Uri.parse(
        'https://www.instagram.com/p/XYZ789/?utm_source=ig_web_copy_link&igsh=abc',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'XYZ789');
    });

    test('IG-SC-013 share URL with igsi query still extracts shortcode', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/DcLtDEhx5pd/?igsi=MXdlZHZ5bWh3a3NuYg==',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'DcLtDEhx5pd');
    });

    test('IG-SC-014 /reels/ plural path extracts shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/reels/DcLtDEhx5pd/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'DcLtDEhx5pd');
    });

    test('IG-SC-015 carousel share URL with img_index and igsi', () {
      final uri = Uri.parse(
        'https://www.instagram.com/p/Dck28qujwLv/?img_index=2&igsi=aXdwZDlwaTZwd3J3',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'Dck28qujwLv');
    });

    test('IG-SC-009 profile URL returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/instagram/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-SC-010 story URL returns null shortcode', () {
      final uri =
          Uri.parse('https://www.instagram.com/stories/username/12345/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-SC-011 homepage returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-SC-012 alphanumeric shortcodes with hyphens/underscores', () {
      final uri = Uri.parse('https://www.instagram.com/reel/C_x-Y1a2B3/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'C_x-Y1a2B3');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 1 — Content kind detection from URL path
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 1 — Instagram content kind detection', () {
    test('IG-KIND-001 /reel/ path detected as reel', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final match = RegExp(r'/(reel|p|tv)/').firstMatch(uri.path);
      expect(match?.group(1), 'reel');
    });

    test('IG-KIND-002 /p/ path detected as post', () {
      final uri = Uri.parse('https://www.instagram.com/p/ABC123/');
      final match = RegExp(r'/(reel|p|tv)/').firstMatch(uri.path);
      expect(match?.group(1), 'p');
    });

    test('IG-KIND-003 /tv/ path detected as IGTV', () {
      final uri = Uri.parse('https://www.instagram.com/tv/ABC123/');
      final match = RegExp(r'/(reel|p|tv)/').firstMatch(uri.path);
      expect(match?.group(1), 'tv');
    });

    test('IG-KIND-004 /stories/ NOT matched by reel|p|tv regex', () {
      final uri =
          Uri.parse('https://www.instagram.com/stories/username/12345/');
      final match = RegExp(r'/(reel|p|tv)/').firstMatch(uri.path);
      expect(match, isNull);
    });

    test('IG-KIND-005 profile path NOT matched by reel|p|tv regex', () {
      final uri = Uri.parse('https://www.instagram.com/instagram/');
      final match = RegExp(r'/(reel|p|tv)/').firstMatch(uri.path);
      expect(match, isNull);
    });

    test('IG-KIND-006 homepage NOT matched by reel|p|tv regex', () {
      final uri = Uri.parse('https://www.instagram.com/');
      final match = RegExp(r'/(reel|p|tv)/').firstMatch(uri.path);
      expect(match, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 2 — URL normalization (canonical URL)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 2 — Instagram URL normalization', () {
    test('IG-NORM-001 canonical URL strips query params', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?utm_source=ig_web_copy_link',
      );
      final canonical = InstagramGraphqlResolver.canonicalPageUrl(uri, 'ABC123');
      expect(canonical.toString(), 'https://www.instagram.com/reel/ABC123/');
      expect(canonical.hasQuery, isFalse);
    });

    test('IG-NORM-002 canonical URL preserves content kind', () {
      final reelUri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final postUri = Uri.parse('https://www.instagram.com/p/ABC123/');
      final tvUri = Uri.parse('https://www.instagram.com/tv/ABC123/');

      expect(
        InstagramGraphqlResolver.canonicalPageUrl(reelUri, 'ABC123').path,
        '/reel/ABC123/',
      );
      expect(
        InstagramGraphqlResolver.canonicalPageUrl(postUri, 'ABC123').path,
        '/p/ABC123/',
      );
      expect(
        InstagramGraphqlResolver.canonicalPageUrl(tvUri, 'ABC123').path,
        '/tv/ABC123/',
      );
    });

    test('IG-NORM-003 same shortcode with different params → same canonical', () {
      final url1 = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final url2 = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?utm_source=ig_web_copy_link',
      );
      final url3 = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?igsh=MXRhY2Z0',
      );

      final can1 = InstagramGraphqlResolver.canonicalPageUrl(url1, 'ABC123');
      final can2 = InstagramGraphqlResolver.canonicalPageUrl(url2, 'ABC123');
      final can3 = InstagramGraphqlResolver.canonicalPageUrl(url3, 'ABC123');

      expect(can1, can2);
      expect(can2, can3);
    });

    test('IG-NORM-008 /reels/ canonicalizes to /reel/', () {
      final uri = Uri.parse('https://www.instagram.com/reels/DcLtDEhx5pd/');
      final canonical = InstagramGraphqlResolver.canonicalPageUrl(
        uri,
        'DcLtDEhx5pd',
      );
      expect(canonical.path, '/reel/DcLtDEhx5pd/');
    });

    test('IG-NORM-004 canonical always uses www.instagram.com host', () {
      final uri = Uri.parse('https://m.instagram.com/reel/ABC123/');
      final canonical = InstagramGraphqlResolver.canonicalPageUrl(uri, 'ABC123');
      expect(canonical.host, 'www.instagram.com');
    });

    test('IG-NORM-005 canonical always has trailing slash', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123');
      final canonical = InstagramGraphqlResolver.canonicalPageUrl(uri, 'ABC123');
      expect(canonical.path.endsWith('/'), isTrue);
    });

    test('IG-NORM-006 fetch targets include embed URL for reel', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(targets.length, greaterThanOrEqualTo(2));
      expect(
        targets.any((t) => t.path.contains('/embed/')),
        isTrue,
      );
    });

    test('IG-NORM-007 fetch targets include embed URL for /p/ post', () {
      final uri = Uri.parse('https://www.instagram.com/p/XYZ789/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(targets.length, greaterThanOrEqualTo(2));
      expect(
        targets.any((t) => t.path.contains('/embed/')),
        isTrue,
      );
    });

    test('IG-NORM-008 fetch targets for profile URL (no embed)', () {
      final uri = Uri.parse('https://www.instagram.com/instagram/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(
        targets.any((t) => t.path.contains('/embed/')),
        isFalse,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 2 — Embed URL generation
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 2 — Instagram embed URL generation', () {
    test('IG-EMBED-001 reel embed URL structure', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      final embed = targets.firstWhere((t) => t.path.contains('/embed/'));
      expect(
        embed.toString(),
        'https://www.instagram.com/reel/ABC123/embed/',
      );
    });

    test('IG-EMBED-002 post embed URL structure', () {
      final uri = Uri.parse('https://www.instagram.com/p/XYZ789/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      final embed = targets.firstWhere((t) => t.path.contains('/embed/'));
      expect(embed.toString(), 'https://www.instagram.com/p/XYZ789/embed/');
    });

    test('IG-EMBED-003 tv embed URL structure', () {
      final uri = Uri.parse('https://www.instagram.com/tv/DEF456/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      final embed = targets.firstWhere((t) => t.path.contains('/embed/'));
      expect(embed.toString(), 'https://www.instagram.com/tv/DEF456/embed/');
    });

    test('IG-EMBED-004 reel with query params → clean embed URL', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?utm_source=ig_web_copy_link',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      final embed = targets.firstWhere((t) => t.path.contains('/embed/'));
      expect(embed.hasQuery, isFalse);
    });

    test('IG-EMBED-005 story URL produces no embed target', () {
      final uri =
          Uri.parse('https://www.instagram.com/stories/username/12345/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(
        targets.any((t) => t.path.contains('/embed/')),
        isFalse,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 17 — Invalid URLs
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 17 — Invalid Instagram URLs', () {
    test('IG-ERR-001 instagram.com homepage has no shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-002 /reel/ with no shortcode returns null', () {
      final uri = Uri.parse('https://www.instagram.com/reel/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-003 /p/ with no shortcode returns null', () {
      final uri = Uri.parse('https://www.instagram.com/p/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-004 /tv/ with no shortcode returns null', () {
      final uri = Uri.parse('https://www.instagram.com/tv/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-005 /stories/ with no ID returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/stories/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-006 /stories/username/ returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/stories/username/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-007 profile URL returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/someuser/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-008 explore page returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/explore/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-009 direct messages path returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/direct/inbox/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-010 accounts path returns null shortcode', () {
      final uri = Uri.parse('https://www.instagram.com/accounts/login/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-011 non-Instagram URL returns null platform', () {
      final uri = Uri.parse('https://www.example.com/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), isNull);
      // shortcodeFromUri only inspects the path — it does not validate the host.
      // Platform gating happens at SocialPlatform.fromUri level.
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });

    test('IG-ERR-012 empty path on instagram.com', () {
      final uri = Uri.parse('https://www.instagram.com');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-ERR-013 UrlValidator accepts Instagram URLs as valid HTTP', () {
      final validator = UrlValidator();
      final result = validator.validate('https://www.instagram.com/reel/ABC123/');
      expect(result.isValid, isTrue);
    });

    test('IG-ERR-014 UrlValidator rejects non-HTTP Instagram-like URLs', () {
      final validator = UrlValidator();
      final result = validator.validate('ftp://www.instagram.com/reel/ABC/');
      expect(result.isValid, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 18 — Security: malformed and dangerous URLs
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 18 — Security: malformed and dangerous URLs', () {
    test('IG-SEC-001 javascript: URL not recognized as Instagram', () {
      final uri = Uri.parse('javascript:alert(1)');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('IG-SEC-002 file: URL not recognized as Instagram', () {
      final uri = Uri.parse('file:///etc/passwd');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('IG-SEC-003 localhost URL not recognized as Instagram', () {
      final uri = Uri.parse('http://localhost/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('IG-SEC-004 private IP URL not recognized as Instagram', () {
      final uri = Uri.parse('http://192.168.1.1/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('IG-SEC-005 data: URL not recognized as Instagram', () {
      final uri = Uri.parse('data:text/html,<script>alert(1)</script>');
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('IG-SEC-006 excessively long URL still parses shortcode correctly', () {
      final longParam = 'x' * 2000;
      final uri = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?param=$longParam',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });
  });
}
