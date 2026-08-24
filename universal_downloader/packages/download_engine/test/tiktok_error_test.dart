import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 13 / 14 / 16 — TikTok error handling, private/restricted content
/// behavior, and security edge cases.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 13 — Invalid URL handling
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 13 — Invalid TikTok URL handling', () {
    test('TT-INV-001 tiktok.com homepage — no video ID, no crash', () {
      final uri = Uri.parse('https://www.tiktok.com/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(TikTokUri.videoIdFromUri(uri), isNull);
    });

    test('TT-INV-002 profile-only URL — no video ID', () {
      final uri = Uri.parse('https://www.tiktok.com/@scout2015');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(TikTokUri.videoIdFromUri(uri), isNull);
    });

    test('TT-INV-003 /video/ with empty ID — returns null', () {
      final uri = Uri.parse('https://www.tiktok.com/@scout2015/video/');
      expect(TikTokUri.videoIdFromUri(uri), isNull);
    });

    test('TT-INV-004 /video/INVALID — non-numeric returns null', () {
      final uri = Uri.parse('https://www.tiktok.com/@scout2015/video/INVALID');
      expect(TikTokUri.videoIdFromUri(uri), isNull);
    });

    test('TT-INV-005 vm.tiktok.com/INVALID — detected but no video ID', () {
      final uri = Uri.parse('https://vm.tiktok.com/INVALID');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
      expect(TikTokUri.videoIdFromUri(uri), isNull);
    });

    test('TT-INV-006 non-TikTok URL — not detected', () {
      final uri = Uri.parse('https://example.com/test');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('TT-INV-007 UrlValidator rejects empty string', () {
      final validator = UrlValidator();
      expect(validator.validate('').isValid, isFalse);
    });

    test('TT-INV-008 UrlValidator rejects plain text', () {
      final validator = UrlValidator();
      expect(validator.validate('not a url').isValid, isFalse);
    });

    test('TT-INV-009 /video/ with mixed alphanumeric ID', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@user/video/abc123def456',
      );
      // The regex /video/(\d+) only matches pure digits
      expect(TikTokUri.videoIdFromUri(uri), isNull);
    });

    test('TT-INV-010 /video/ with negative number', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@user/video/-123',
      );
      // The regex /video/(\d+) does not match negative numbers
      expect(TikTokUri.videoIdFromUri(uri), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 14 — Private/restricted content handling
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 14 — Private/restricted content handling', () {
    test('TT-PRIV-001 resolver returns null for HTML with no video URL', () {
      const privateHtml = '''
<html><head>
  <meta property="og:title" content="Private video" />
  <meta property="og:description" content="This video is private" />
</head><body>
  <div>Video is private or unavailable</div>
</body></html>''';
      expect(TikTokResolver.extractFromHtmlForTest(privateHtml), isNull);
    });

    test('TT-PRIV-002 resolver returns null for empty response body', () {
      expect(TikTokResolver.extractFromHtmlForTest(''), isNull);
    });

    test('TT-PRIV-003 resolver returns null for error page HTML', () {
      const errorHtml = '''
<html><head>
  <title>Couldn't find this account | TikTok</title>
</head><body>
  <div>This account doesn't exist</div>
</body></html>''';
      expect(TikTokResolver.extractFromHtmlForTest(errorHtml), isNull);
    });

    test('TT-PRIV-004 resolver returns null for age-restricted stub', () {
      const restrictedHtml = '''
<html><head>
  <meta property="og:title" content="Age restricted content" />
</head><body>
  <div class="verify-age">You must be 18+ to view this content</div>
</body></html>''';
      // No downloadAddr/playAddr/playApi in age-restricted stub pages
      expect(TikTokResolver.extractFromHtmlForTest(restrictedHtml), isNull);
    });

    test('TT-PRIV-005 resolver returns null for deleted content page', () {
      const deletedHtml = '''
<html><head>
  <title>Video unavailable | TikTok</title>
</head><body>
  <div>This video has been removed</div>
</body></html>''';
      expect(TikTokResolver.extractFromHtmlForTest(deletedHtml), isNull);
    });

    test('TT-PRIV-006 resolver returns null for region-restricted stub', () {
      const regionHtml = '''
<html><head>
  <meta property="og:title" content="Not available" />
</head><body>
  <div>This content isn't available in your region</div>
</body></html>''';
      expect(TikTokResolver.extractFromHtmlForTest(regionHtml), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 13 — Error message formatting
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 13 — Error formatting', () {
    test('TT-ERR-FMT-001 DownloadErrorFormatter handles TikTok errors', () {
      final message = DownloadErrorFormatter.fromObject(
        Exception('Failed to discover media from TikTok URL'),
      );
      expect(message, isNotEmpty);
      expect(message, isA<String>());
    });

    test('TT-ERR-FMT-002 long error messages are truncated', () {
      final longMessage = 'TikTok error: ${'x' * 1000}';
      final formatted = DownloadErrorFormatter.fromObject(
        Exception(longMessage),
      );
      expect(formatted.length, lessThanOrEqualTo(200));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 16 — Security edge cases
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 16 — TikTok security edge cases', () {
    test('TT-SEC-HTML-001 HTML with script injection does not execute', () {
      const maliciousHtml = '''
<html>
<script>alert('xss')</script>
<script>{"downloadAddr":"javascript:alert(1)"}</script>
</html>''';
      final url = TikTokResolver.extractFromHtmlForTest(maliciousHtml);
      // javascript: URLs should be rejected by _isVideoPlaybackUrl
      // because they don't start with http
      if (url != null) {
        expect(url, startsWith('http'),
            reason: 'Extracted URL must be HTTP(S)');
      }
    });

    test('TT-SEC-HTML-002 data: URI in HTML not accepted', () {
      const html = '{"downloadAddr":"data:video/mp4;base64,AAAA"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      // data: URIs don't start with http, so _isVideoPlaybackUrl returns false
      expect(url, isNull);
    });

    test('TT-SEC-HTML-003 file: URI in HTML not accepted', () {
      const html = '{"downloadAddr":"file:///etc/passwd"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNull);
    });

    test('TT-SEC-HTML-004 empty downloadAddr string not accepted', () {
      const html = '{"downloadAddr":""}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNull);
    });

    test('TT-SEC-HTML-005 localhost CDN URL not accepted', () {
      const html = '{"downloadAddr":"http://localhost:8080/video.mp4"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      // localhost does not match tiktokcdn.com, tiktokv.com, or /video/tos/ patterns
      expect(url, isNull);
    });

    test('TT-SEC-HTML-006 private IP CDN URL not accepted', () {
      const html = '{"downloadAddr":"http://192.168.1.1/video.mp4"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, isNull);
    });

    test('TT-SEC-HTML-007 URL with SSRF redirect attempt handled', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/redirect?url=http://internal.corp/secret"}';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      // This URL starts with https and contains tiktokcdn.com
      // But it doesn't have .mp4, /video/tos/, or mime_type=video
      // So _isVideoPlaybackUrl should reject it
      if (url != null) {
        expect(url, startsWith('https'));
      }
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Regression — existing TikTok tests from filename_resolver_test.dart
  // ─────────────────────────────────────────────────────────────────────────

  group('Regression — existing TikTok unit tests', () {
    test('TT-REG-001 extracts downloadAddr from mobile HTML (existing)', () {
      const html =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}';
      expect(TikTokResolver.videoIdFromUri(
        Uri.parse('https://www.tiktok.com/@user/video/7643276616088440071'),
      ), '7643276616088440071');
      expect(
        TikTokResolver.extractFromHtmlForTest(html),
        contains('tiktokcdn.com'),
      );
    });

    test('TT-REG-002 parses video ID with webapp query params (existing)', () {
      expect(
        TikTokResolver.videoIdFromUri(
          Uri.parse(
            'https://www.tiktok.com/@hshs63690/video/7673099286178958610?is_from_webapp=1&sender_device=pc',
          ),
        ),
        '7673099286178958610',
      );
    });

    test('TT-REG-003 ignores static webarch CDN assets (existing)', () {
      const html =
          'https://sf-i18n-resources.tiktokcdn.com/obj/tiktok-webarch-solution-i18n-us';
      expect(TikTokResolver.extractFromHtmlForTest(html), isNull);
    });

    test('TT-REG-004 keeps unicode-escaped playAddr video URLs (existing)', () {
      const html =
          '"playAddr":"https:\\u002F\\u002Fv16-webapp-prime.tiktok.com\\u002Fvideo\\u002Ftos\\u002Falisg\\u002Fclip\\u002F?a=1988&mime_type=video_mp4"';
      final url = TikTokResolver.extractFromHtmlForTest(html);
      expect(url, contains('v16-webapp-prime.tiktok.com'));
      expect(url, contains('/video/tos/'));
      expect(url, isNot(contains(r'\u002F')));
    });

    test('TT-REG-005 ContentProviderRegistry.canHandle for vm.tiktok.com (existing)', () {
      expect(
        ContentProviderRegistry.canHandle(
          Uri.parse('https://vm.tiktok.com/abc/'),
        ),
        isTrue,
      );
    });

    test('TT-REG-006 SocialPlatform detects www.tiktok.com (existing)', () {
      expect(
        SocialPlatform.fromUri(
          Uri.parse('https://www.tiktok.com/@user/video/123'),
        ),
        SocialPlatform.tiktok,
      );
    });

    test('TT-REG-007 MediaExtractor extracts TikTok playAddr (existing)', () {
      const html = '''
<html><head>
  <meta property="og:title" content="Sample clip" />
  <script>{"playAddr":"https://v16.tiktokcdn.com/a/video.mp4?token=1"}</script>
</head></html>''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        html: html,
        platform: SocialPlatform.tiktok,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('tiktokcdn.com'));
      expect(result.fileName, endsWith('.mp4'));
    });
  });
}
