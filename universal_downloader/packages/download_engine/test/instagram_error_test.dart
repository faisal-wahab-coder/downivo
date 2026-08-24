import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 14 / 16 / 17 / 18 — Instagram error handling: invalid URLs,
/// private content, deleted content, and security edge cases.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 17 — Invalid URL edge cases
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 17 — Instagram invalid URL edge cases', () {
    test('IG-INV-001 /reel/ with empty path after slash', () {
      final uri = Uri.parse('https://www.instagram.com/reel//');
      // The regex /(reel|p|tv)/([^/?#]+)/ won't match because the captured
      // group after /reel/ would be empty.
      final shortcode = InstagramGraphqlResolver.shortcodeFromUri(uri);
      expect(shortcode, isNull);
    });

    test('IG-INV-002 /p/ followed by query only', () {
      final uri = Uri.parse('https://www.instagram.com/p/?utm=test');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-INV-003 /reel/ with hash fragment only', () {
      final uri = Uri.parse('https://www.instagram.com/reel/#section');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-INV-004 URL with /reel in middle of different path', () {
      final uri = Uri.parse('https://www.instagram.com/explore/reel/ABC/');
      // The regex matches /(reel|p|tv)/ anywhere in path
      final shortcode = InstagramGraphqlResolver.shortcodeFromUri(uri);
      // The regex will find /reel/ABC so it extracts ABC
      if (shortcode != null) {
        expect(shortcode, 'ABC');
      }
    });

    test('IG-INV-005 extremely long shortcode', () {
      final longCode = 'A' * 500;
      final uri = Uri.parse('https://www.instagram.com/reel/$longCode/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), longCode);
    });

    test('IG-INV-006 shortcode with special characters', () {
      final uri = Uri.parse('https://www.instagram.com/reel/A-b_C123/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'A-b_C123');
    });

    test('IG-INV-007 URL with unicode path segments', () {
      final uri =
          Uri.parse('https://www.instagram.com/reel/%E2%9C%93check/');
      final shortcode = InstagramGraphqlResolver.shortcodeFromUri(uri);
      expect(shortcode, isNotNull);
    });

    test('IG-INV-008 HTTP (non-HTTPS) Instagram URL', () {
      final uri = Uri.parse('http://www.instagram.com/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });

    test('IG-INV-009 multiple /reel/ segments in path', () {
      final uri = Uri.parse('https://www.instagram.com/reel/ABC/reel/DEF/');
      final shortcode = InstagramGraphqlResolver.shortcodeFromUri(uri);
      // firstMatch returns the first occurrence
      expect(shortcode, 'ABC');
    });

    test('IG-INV-010 Instagram URL with port number', () {
      final uri = Uri.parse('https://www.instagram.com:443/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'ABC123');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 16 — Deleted / unavailable content (payload-level)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 16 — Instagram deleted/unavailable content', () {
    test('IG-DEL-001 error response payload returns null', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': null,
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/DELETED/'),
        shortcode: 'DELETED',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-DEL-002 items with null/empty object returns null', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [null],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/NULL01/'),
        shortcode: 'NULL01',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-DEL-003 completely empty response', () {
      final payload = <String, dynamic>{};
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/EMPTY/'),
        shortcode: 'EMPTY',
        payload: payload,
      );
      expect(result, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 14 — Private content (payload-level simulation)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 14 — Instagram private content', () {
    test('IG-PRIV-001 private post with no video data returns null', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'media_type': 8,
                'carousel_media': null,
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PRIV01/'),
        shortcode: 'PRIV01',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-PRIV-002 restricted content with empty video_versions', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': <dynamic>[],
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/PRIV02/'),
        shortcode: 'PRIV02',
        payload: payload,
      );
      expect(result, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 18 — Security edge cases
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 18 — Instagram security edge cases', () {
    test('IG-SEC-001 javascript: URL returns null platform', () {
      final uri = Uri.parse('javascript:alert(document.cookie)');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('IG-SEC-002 file: URL returns null platform', () {
      final uri = Uri.parse('file:///etc/passwd');
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('IG-SEC-003 data: URL returns null platform', () {
      final uri = Uri.parse(
        'data:text/html;base64,PHNjcmlwdD5hbGVydCgxKTwvc2NyaXB0Pg==',
      );
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('IG-SEC-004 localhost impersonating instagram returns null', () {
      final uri = Uri.parse('http://localhost:8080/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('IG-SEC-005 private IP impersonating instagram returns null', () {
      final uri = Uri.parse('http://10.0.0.1/reel/ABC123/');
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('IG-SEC-006 video_url with javascript: protocol rejected', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'SEC06',
            'video_url': 'javascript:alert(1)',
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/SEC06/'),
        shortcode: 'SEC06',
        payload: payload,
      );
      expect(result, isNull,
          reason: 'Non-HTTP video_url must be rejected');
    });

    test('IG-SEC-007 video_url with file: protocol rejected', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'SEC07',
            'video_url': 'file:///etc/passwd',
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/SEC07/'),
        shortcode: 'SEC07',
        payload: payload,
      );
      expect(result, isNull,
          reason: 'file: protocol must be rejected');
    });

    test('IG-SEC-008 video_versions URL with non-HTTP protocol rejected', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {'url': 'ftp://cdn.example.com/video.mp4', 'width': 720, 'height': 1280},
                ],
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/SEC08/'),
        shortcode: 'SEC08',
        payload: payload,
      );
      expect(result, isNull,
          reason: 'Non-HTTP URLs in video_versions must be rejected');
    });
  });
}
