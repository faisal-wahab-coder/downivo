import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Facebook URL parsing, content ID extraction, content type classification,
/// URL normalization, fetch targets, and security validation.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ───────────────────────────────────────────────────────────────────────
  // Phase 1 — Platform detection
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 1 — Facebook platform detection', () {
    test('FB-URL-001 www.facebook.com is Facebook', () {
      final uri = Uri.parse('https://www.facebook.com/watch/?v=123456');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Facebook');
    });

    test('FB-URL-002 facebook.com (no www) is Facebook', () {
      final uri = Uri.parse('https://facebook.com/reel/123456/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('FB-URL-003 m.facebook.com is Facebook', () {
      final uri = Uri.parse('https://m.facebook.com/watch/?v=123456');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('FB-URL-004 mbasic.facebook.com is Facebook', () {
      final uri = Uri.parse('https://mbasic.facebook.com/watch/?v=123456');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('FB-URL-005 l.facebook.com is Facebook', () {
      final uri = Uri.parse('https://l.facebook.com/l.php?u=test');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('FB-URL-006 fb.watch is Facebook', () {
      final uri = Uri.parse('https://fb.watch/abc123/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('FB-URL-007 web.facebook.com is Facebook', () {
      final uri = Uri.parse('https://web.facebook.com/watch/?v=123456');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
    });

    test('FB-URL-008 non-Facebook host is rejected', () {
      final uri = Uri.parse('https://www.example.com/facebook/video');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('FB-URL-009 youtube.com is NOT Facebook', () {
      final uri = Uri.parse('https://www.youtube.com/watch?v=abc');
      expect(SocialPlatform.fromUri(uri), isNot(SocialPlatform.facebook));
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 2 — Content ID extraction
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 2 — Facebook content ID extraction', () {
    test('FB-URL-010 /watch/?v= extracts video ID', () {
      final uri = Uri.parse('https://www.facebook.com/watch/?v=987654321');
      expect(FacebookUri.contentIdFromUri(uri), '987654321');
    });

    test('FB-URL-011 /video.php?v= extracts video ID', () {
      final uri =
          Uri.parse('https://www.facebook.com/video.php?v=123456789');
      expect(FacebookUri.contentIdFromUri(uri), '123456789');
    });

    test('FB-URL-012 /<page>/videos/<id>/ extracts video ID', () {
      final uri =
          Uri.parse('https://www.facebook.com/pagename/videos/111222333/');
      expect(FacebookUri.contentIdFromUri(uri), '111222333');
    });

    test('FB-URL-013 /reel/<id> extracts reel ID', () {
      final uri = Uri.parse('https://www.facebook.com/reel/444555666/');
      expect(FacebookUri.contentIdFromUri(uri), '444555666');
    });

    test('FB-URL-014 /reels/<id> extracts reel ID', () {
      final uri = Uri.parse('https://www.facebook.com/reels/777888999/');
      expect(FacebookUri.contentIdFromUri(uri), '777888999');
    });

    test('FB-URL-015 /photo/?fbid= extracts photo ID', () {
      final uri =
          Uri.parse('https://www.facebook.com/photo/?fbid=111222333');
      expect(FacebookUri.contentIdFromUri(uri), '111222333');
    });

    test('FB-URL-016 /photo.php?fbid= extracts photo ID', () {
      final uri =
          Uri.parse('https://www.facebook.com/photo.php?fbid=444555666');
      expect(FacebookUri.contentIdFromUri(uri), '444555666');
    });

    test('FB-URL-017 /permalink.php?story_fbid= extracts ID', () {
      final uri = Uri.parse(
        'https://www.facebook.com/permalink.php?story_fbid=999888777&id=12345',
      );
      expect(FacebookUri.contentIdFromUri(uri), '999888777');
    });

    test('FB-URL-018 fb.watch/<shortcode> extracts shortcode', () {
      final uri = Uri.parse('https://fb.watch/abc123/');
      expect(FacebookUri.contentIdFromUri(uri), 'abc123');
    });

    test('FB-URL-019 bare page URL returns null', () {
      final uri = Uri.parse('https://www.facebook.com/pagename/');
      expect(FacebookUri.contentIdFromUri(uri), isNull);
    });

    test('FB-URL-020 home URL returns null', () {
      final uri = Uri.parse('https://www.facebook.com/');
      expect(FacebookUri.contentIdFromUri(uri), isNull);
    });

    test('FB-URL-021 /watch/ with no v= returns null', () {
      final uri = Uri.parse('https://www.facebook.com/watch/');
      expect(FacebookUri.contentIdFromUri(uri), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 3 — Content type classification
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 3 — Facebook content type classification', () {
    test('FB-URL-030 / is HOME', () {
      final uri = Uri.parse('https://www.facebook.com/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.home);
    });

    test('FB-URL-031 /watch/?v= is VIDEO', () {
      final uri = Uri.parse('https://www.facebook.com/watch/?v=123456');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.video);
    });

    test('FB-URL-032 /video.php?v= is VIDEO', () {
      final uri =
          Uri.parse('https://www.facebook.com/video.php?v=123456');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.video);
    });

    test('FB-URL-033 /<page>/videos/<id>/ is VIDEO', () {
      final uri =
          Uri.parse('https://www.facebook.com/page/videos/123456/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.video);
    });

    test('FB-URL-034 /reel/<id> is REEL', () {
      final uri = Uri.parse('https://www.facebook.com/reel/123456/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.reel);
    });

    test('FB-URL-035 /reels/<id> is REEL', () {
      final uri = Uri.parse('https://www.facebook.com/reels/123456/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.reel);
    });

    test('FB-URL-036 /photo/?fbid= is PHOTO', () {
      final uri =
          Uri.parse('https://www.facebook.com/photo/?fbid=123456');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
    });

    test('FB-URL-037 /<page>/photos/<id>/ is PHOTO', () {
      final uri =
          Uri.parse('https://www.facebook.com/page/photos/a.123/456/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
    });

    test('FB-URL-038 fb.watch is VIDEO', () {
      final uri = Uri.parse('https://fb.watch/abc123/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.video);
    });

    test('FB-URL-039 /<pagename>/ is PAGE', () {
      final uri = Uri.parse('https://www.facebook.com/facebook/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.page);
    });

    test('FB-URL-040 /reel/ with no ID is UNKNOWN', () {
      final uri = Uri.parse('https://www.facebook.com/reel/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.unknown);
    });

    test('FB-URL-041 /watch/ with no v= is VIDEO', () {
      final uri = Uri.parse('https://www.facebook.com/watch/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.video);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 4 — URL classification helpers
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 4 — FacebookUri helper methods', () {
    test('FB-URL-050 isReel detects /reel/<id>', () {
      expect(
        FacebookUri.isReel(Uri.parse('https://www.facebook.com/reel/123456/')),
        isTrue,
      );
    });

    test('FB-URL-051 isReel rejects /watch/', () {
      expect(
        FacebookUri.isReel(
          Uri.parse('https://www.facebook.com/watch/?v=123'),
        ),
        isFalse,
      );
    });

    test('FB-URL-052 isVideo detects /watch/?v=', () {
      expect(
        FacebookUri.isVideo(
          Uri.parse('https://www.facebook.com/watch/?v=123'),
        ),
        isTrue,
      );
    });

    test('FB-URL-053 isVideo detects fb.watch', () {
      expect(
        FacebookUri.isVideo(Uri.parse('https://fb.watch/abc/')),
        isTrue,
      );
    });

    test('FB-URL-054 isVideo detects /video.php', () {
      expect(
        FacebookUri.isVideo(
          Uri.parse('https://www.facebook.com/video.php?v=123'),
        ),
        isTrue,
      );
    });

    test('FB-URL-055 isPhoto detects /photo/?fbid=', () {
      expect(
        FacebookUri.isPhoto(
          Uri.parse('https://www.facebook.com/photo/?fbid=123'),
        ),
        isTrue,
      );
    });

    test('FB-URL-056 isPhoto detects /photos/', () {
      expect(
        FacebookUri.isPhoto(
          Uri.parse('https://www.facebook.com/page/photos/a.1/2/'),
        ),
        isTrue,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 5 — URL normalization
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 5 — Facebook URL normalization', () {
    test('FB-URL-060 strips tracking parameters', () {
      final uri = Uri.parse(
        'https://www.facebook.com/watch/?v=123&mibextid=abc&ref=share',
      );
      final normalized = FacebookUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('v'), isTrue);
      expect(normalized.queryParameters.containsKey('mibextid'), isFalse);
      expect(normalized.queryParameters.containsKey('ref'), isFalse);
    });

    test('FB-URL-061 normalizes bare facebook.com to www', () {
      final uri = Uri.parse('https://facebook.com/reel/123456/');
      final normalized = FacebookUri.normalize(uri);
      expect(normalized.host, 'www.facebook.com');
    });

    test('FB-URL-062 preserves fb.watch as-is', () {
      final uri = Uri.parse('https://fb.watch/abc/');
      final normalized = FacebookUri.normalize(uri);
      expect(normalized.host, 'fb.watch');
    });

    test('FB-URL-063 preserves content parameters (v, fbid)', () {
      final uri = Uri.parse(
        'https://www.facebook.com/watch/?v=123&mibextid=abc',
      );
      final normalized = FacebookUri.normalize(uri);
      expect(normalized.queryParameters['v'], '123');
    });

    test('FB-URL-064 strips __cft__ and __tn__ parameters', () {
      final uri = Uri.parse(
        'https://www.facebook.com/reel/123/?__cft__[0]=abc&__tn__=test',
      );
      final normalized = FacebookUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('__cft__'), isFalse);
      expect(normalized.queryParameters.containsKey('__tn__'), isFalse);
    });

    test('FB-URL-065 SocialUrlUtils.fetchTargets includes mobile', () {
      final uri = Uri.parse('https://www.facebook.com/watch/?v=123456');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.facebook);
      expect(targets.length, greaterThanOrEqualTo(2));
      expect(
        targets.any((t) => t.host == 'm.facebook.com'),
        isTrue,
      );
    });

    test('FB-URL-066 SocialUrlUtils.fetchTargets includes mbasic for reels', () {
      final uri = Uri.parse('https://www.facebook.com/reel/123456/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.facebook);
      expect(
        targets.any((t) => t.host == 'mbasic.facebook.com'),
        isTrue,
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 6 — Invalid / edge case URLs
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 6 — Invalid and edge-case Facebook URLs', () {
    test('FB-URL-070 https://www.facebook.com/ is HOME, no download', () {
      final uri = Uri.parse('https://www.facebook.com/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.home);
      expect(FacebookUri.contentIdFromUri(uri), isNull);
    });

    test('FB-URL-071 /watch/ without v= classifies as VIDEO', () {
      final uri = Uri.parse('https://www.facebook.com/watch/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.video);
      expect(FacebookUri.contentIdFromUri(uri), isNull);
    });

    test('FB-URL-072 /reel/ without ID is UNKNOWN', () {
      final uri = Uri.parse('https://www.facebook.com/reel/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.unknown);
    });

    test('FB-URL-073 /reel/INVALID (non-numeric) is UNKNOWN', () {
      final uri = Uri.parse('https://www.facebook.com/reel/INVALID/');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.unknown);
    });

    test('FB-URL-074 /video.php without v= classifies as VIDEO', () {
      final uri = Uri.parse('https://www.facebook.com/video.php');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.video);
    });

    test('FB-URL-075 /video.php?v=INVALID extracts INVALID as ID', () {
      final uri =
          Uri.parse('https://www.facebook.com/video.php?v=INVALID');
      expect(FacebookUri.contentIdFromUri(uri), 'INVALID');
    });

    test('FB-URL-076 /INVALID path is classified as PAGE', () {
      final uri = Uri.parse('https://www.facebook.com/INVALID');
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.page);
    });

    test('FB-URL-077 example.com is not Facebook', () {
      final uri = Uri.parse('https://example.com/test');
      expect(SocialPlatform.fromUri(uri), isNull);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 7 — Security
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 7 — Facebook URL security', () {
    test('FB-SEC-001 javascript: scheme is rejected by UrlValidator', () {
      final validator = UrlValidator();
      final result = validator.validate('javascript:alert(1)');
      expect(result.isValid, isFalse);
    });

    test('FB-SEC-002 file: scheme is rejected by UrlValidator', () {
      final validator = UrlValidator();
      final result = validator.validate('file:///test');
      expect(result.isValid, isFalse);
    });

    test('FB-SEC-003 localhost is not Facebook', () {
      final uri = Uri.parse('http://localhost/watch/?v=123');
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('FB-SEC-004 127.0.0.1 is not Facebook', () {
      final uri = Uri.parse('http://127.0.0.1/watch/?v=123');
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('FB-SEC-005 private IP 192.168.1.1 is not Facebook', () {
      final uri = Uri.parse('http://192.168.1.1/watch/?v=123');
      expect(SocialPlatform.fromUri(uri), isNull);
    });

    test('FB-SEC-006 path traversal in filename is sanitized', () {
      final sanitized = FileNameResolver.sanitize('../../../../etc/passwd');
      // sanitize converts path separators to underscores and uses basename
      expect(sanitized, isNot(contains('/')));
      expect(sanitized, isNot(equals('../../../../etc/passwd')));
    });

    test('FB-SEC-007 unicode filename is sanitized', () {
      final sanitized = FileNameResolver.sanitize('téstfile™.mp4');
      expect(sanitized.contains('™') || sanitized.endsWith('.mp4'), isTrue);
    });

    test('FB-SEC-008 excessively long URL is parseable', () {
      final longPath = 'a' * 2000;
      final uri = Uri.parse('https://www.facebook.com/$longPath');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.facebook);
    });

    test('FB-SEC-009 empty URL is rejected', () {
      final validator = UrlValidator();
      expect(validator.validate('').isValid, isFalse);
    });

    test('FB-SEC-010 data: scheme is rejected', () {
      final validator = UrlValidator();
      expect(validator.validate('data:text/html,test').isValid, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 8 — Duplicate detection via normalization
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 8 — Duplicate detection', () {
    test('FB-URL-080 same video with/without tracking params normalizes same', () {
      final url1 = Uri.parse('https://www.facebook.com/watch/?v=123');
      final url2 = Uri.parse(
        'https://www.facebook.com/watch/?v=123&mibextid=abc&ref=share',
      );
      final n1 = FacebookUri.normalize(url1);
      final n2 = FacebookUri.normalize(url2);
      expect(n1.queryParameters['v'], n2.queryParameters['v']);
      expect(
        FacebookUri.contentIdFromUri(n1),
        FacebookUri.contentIdFromUri(n2),
      );
    });

    test('FB-URL-081 same reel with different tracking params has same ID', () {
      final url1 = Uri.parse('https://www.facebook.com/reel/123456/');
      final url2 = Uri.parse(
        'https://www.facebook.com/reel/123456/?mibextid=abc',
      );
      expect(
        FacebookUri.contentIdFromUri(url1),
        FacebookUri.contentIdFromUri(url2),
      );
    });

    test('FB-URL-082 mobile and desktop URLs have same content ID', () {
      final desktop =
          Uri.parse('https://www.facebook.com/watch/?v=123456');
      final mobile =
          Uri.parse('https://m.facebook.com/watch/?v=123456');
      expect(
        FacebookUri.contentIdFromUri(desktop),
        FacebookUri.contentIdFromUri(mobile),
      );
    });
  });

  // ───────────────────────────────────────────────────────────────────────
  // Phase 9 — /posts/ and pfbid URL support
  // ───────────────────────────────────────────────────────────────────────

  group('Phase 9 — /posts/ and pfbid URL support', () {
    test('FB-URL-090 /posts/pfbid... is classified as POST', () {
      final uri = Uri.parse(
        'https://www.facebook.com/kevinloveofficial/posts/'
        'pfbid0nWhZeiMVjzLHVjzR6QngXeVug8Nw4YxncbbZrquMu72r3H'
        'M8a73k55keRWiaWNLTl/',
      );
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.post);
    });

    test('FB-URL-091 /posts/ with numeric ID is classified as POST', () {
      final uri = Uri.parse(
        'https://www.facebook.com/username/posts/123456789012345/',
      );
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.post);
    });

    test('FB-URL-092 pfbid content ID is extracted from /posts/', () {
      final uri = Uri.parse(
        'https://www.facebook.com/kevinloveofficial/posts/'
        'pfbid0nWhZeiMVjzLHVjzR6QngXeVug8Nw4YxncbbZrquMu72r3H'
        'M8a73k55keRWiaWNLTl/',
      );
      final id = FacebookUri.contentIdFromUri(uri);
      expect(id, isNotNull);
      expect(id, startsWith('pfbid'));
    });

    test('FB-URL-093 numeric ID in /posts/ is extracted', () {
      final uri = Uri.parse(
        'https://www.facebook.com/username/posts/123456789012345/',
      );
      expect(FacebookUri.contentIdFromUri(uri), '123456789012345');
    });

    test('FB-URL-094 /photo/?fbid= with set param is PHOTO', () {
      final uri = Uri.parse(
        'https://www.facebook.com/photo/?fbid=1361297415358305'
        '&set=a.274295957391795',
      );
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
      expect(FacebookUri.contentIdFromUri(uri), '1361297415358305');
    });

    test('FB-URL-095 standalone fbid= query (no /photo path) is PHOTO', () {
      final uri = Uri.parse(
        'https://www.facebook.com/permalink.php?fbid=123456789',
      );
      expect(FacebookResolver.classifyUrl(uri), FacebookContentType.photo);
    });

    test('FB-URL-096 mbasic target added for photo URLs', () {
      final uri = Uri.parse(
        'https://www.facebook.com/photo/?fbid=1361297415358305',
      );
      final targets = SocialUrlUtils.fetchTargets(
        uri,
        SocialPlatform.facebook,
      );
      expect(
        targets.any((t) => t.host == 'mbasic.facebook.com'),
        isTrue,
      );
    });

    test('FB-URL-097 mbasic target added for /posts/ URLs', () {
      final uri = Uri.parse(
        'https://www.facebook.com/user/posts/pfbid0test123/',
      );
      final targets = SocialUrlUtils.fetchTargets(
        uri,
        SocialPlatform.facebook,
      );
      expect(
        targets.any((t) => t.host == 'mbasic.facebook.com'),
        isTrue,
      );
    });

    test('FB-URL-098 /posts/ with tracking params normalizes correctly', () {
      final uri = Uri.parse(
        'https://www.facebook.com/user/posts/pfbid0test123/'
        '?mibextid=abc&ref=share',
      );
      final normalized = FacebookUri.normalize(uri);
      expect(normalized.queryParameters.containsKey('mibextid'), isFalse);
      expect(normalized.queryParameters.containsKey('ref'), isFalse);
    });
  });
}
