import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 1 / 2 / 4 — Instagram Reel URL detection, normalization,
/// embed generation, and canonical URL construction.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Reel URL detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Reel URL detection', () {
    test('IG-REEL-001 standard reel URL detected', () {
      final uri = Uri.parse('https://www.instagram.com/reel/CxY1aBcDeF/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CxY1aBcDeF');
    });

    test('IG-REEL-002 reel URL without www', () {
      final uri = Uri.parse('https://instagram.com/reel/CxY1aBcDeF/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CxY1aBcDeF');
    });

    test('IG-REEL-003 reel URL with mobile subdomain', () {
      final uri = Uri.parse('https://m.instagram.com/reel/CxY1aBcDeF/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CxY1aBcDeF');
    });

    test('IG-REEL-004 reel URL with utm_source query param', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/CxY1aBcDeF/?utm_source=ig_web_copy_link',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CxY1aBcDeF');
    });

    test('IG-REEL-005 reel URL with igsh query param (mobile share)', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/CxY1aBcDeF/?igsh=MXRhY2Z0dG8xODY3Yg==',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CxY1aBcDeF');
    });

    test('IG-REEL-006 reel URL with both utm_source and igsh', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/CxY1aBcDeF/?utm_source=ig_web_copy_link&igsh=abc123',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CxY1aBcDeF');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Reel URL normalization
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Reel URL normalization', () {
    test('IG-REEL-NORM-001 all reel URL variations produce same shortcode', () {
      const shortcode = 'CxY1aBcDeF';
      final urls = [
        'https://www.instagram.com/reel/$shortcode/',
        'https://www.instagram.com/reel/$shortcode/?utm_source=ig_web_copy_link',
        'https://www.instagram.com/reel/$shortcode/?igsh=MXRhY2Z0',
        'https://instagram.com/reel/$shortcode/',
        'https://m.instagram.com/reel/$shortcode/',
        'https://www.instagram.com/reel/$shortcode',
      ];

      for (final url in urls) {
        final uri = Uri.parse(url);
        expect(
          InstagramGraphqlResolver.shortcodeFromUri(uri),
          shortcode,
          reason: 'Failed for: $url',
        );
      }
    });

    test('IG-REEL-NORM-002 all reel URL variations produce same canonical', () {
      const shortcode = 'ABC123';
      final urls = [
        'https://www.instagram.com/reel/$shortcode/',
        'https://www.instagram.com/reel/$shortcode/?utm_source=ig_web_copy_link',
        'https://www.instagram.com/reel/$shortcode/?igsh=xyz',
        'https://instagram.com/reel/$shortcode/',
      ];

      final canonicals = urls.map((url) {
        final uri = Uri.parse(url);
        return InstagramGraphqlResolver.canonicalPageUrl(uri, shortcode);
      }).toSet();

      expect(canonicals.length, 1,
          reason: 'All variations should produce the same canonical URL');
      expect(
        canonicals.first.toString(),
        'https://www.instagram.com/reel/$shortcode/',
      );
    });

    test('IG-REEL-NORM-003 query params do not affect content identity', () {
      final base = Uri.parse('https://www.instagram.com/reel/TEST001/');
      final withTracking = Uri.parse(
        'https://www.instagram.com/reel/TEST001/?utm_source=ig_web_copy_link&utm_medium=copy_link',
      );

      final sc1 = InstagramGraphqlResolver.shortcodeFromUri(base);
      final sc2 = InstagramGraphqlResolver.shortcodeFromUri(withTracking);
      expect(sc1, sc2);

      final can1 = InstagramGraphqlResolver.canonicalPageUrl(base, sc1!);
      final can2 = InstagramGraphqlResolver.canonicalPageUrl(withTracking, sc2!);
      expect(can1, can2);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Reel embed URL generation
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Reel embed URL generation', () {
    test('IG-REEL-EMBED-001 reel produces /reel/<id>/embed/ target', () {
      final uri = Uri.parse('https://www.instagram.com/reel/CxY1aBcDeF/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(
        targets.any(
          (t) => t.toString() == 'https://www.instagram.com/reel/CxY1aBcDeF/embed/',
        ),
        isTrue,
      );
    });

    test('IG-REEL-EMBED-002 reel embed is first in targets list', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(targets.first.path, contains('/embed/'));
    });

    test('IG-REEL-EMBED-003 reel with query produces clean embed', () {
      final uri = Uri.parse(
        'https://www.instagram.com/reel/ABC123/?igsh=xyz',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      final embed = targets.firstWhere((t) => t.path.contains('/embed/'));
      expect(embed.hasQuery, isFalse);
      expect(embed.path, '/reel/ABC123/embed/');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Reel canonical URL
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Reel canonical URL', () {
    test('IG-REEL-CAN-001 canonical preserves reel kind', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final canonical = InstagramGraphqlResolver.canonicalPageUrl(uri, 'ABC123');
      expect(canonical.path, '/reel/ABC123/');
    });

    test('IG-REEL-CAN-002 canonical uses https', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC123/');
      final canonical = InstagramGraphqlResolver.canonicalPageUrl(uri, 'ABC123');
      expect(canonical.scheme, 'https');
    });

    test('IG-REEL-CAN-003 canonical uses www.instagram.com', () {
      final uri = Uri.parse('https://m.instagram.com/reel/ABC123/');
      final canonical = InstagramGraphqlResolver.canonicalPageUrl(uri, 'ABC123');
      expect(canonical.host, 'www.instagram.com');
    });
  });
}
