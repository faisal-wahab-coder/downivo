import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 10 — Instagram Story URL detection and parsing.
///
/// Stories (/stories/<username>/<id>/) are NOT currently supported by the
/// resolver. These tests document that story URLs are recognized as Instagram
/// but do not produce a downloadable resource.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Story URL detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Story URL detection', () {
    test('IG-STORY-001 story URL recognized as Instagram platform', () {
      final uri = Uri.parse(
        'https://www.instagram.com/stories/username/1234567890/',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Instagram');
    });

    test('IG-STORY-002 story URL returns null shortcode (unsupported)', () {
      final uri = Uri.parse(
        'https://www.instagram.com/stories/someuser/9876543210/',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-STORY-003 story URL without story ID', () {
      final uri = Uri.parse('https://www.instagram.com/stories/username/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });

    test('IG-STORY-004 story URL with query parameters', () {
      final uri = Uri.parse(
        'https://www.instagram.com/stories/user123/111222333/?utm_source=ig_story',
      );
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Story URL parsing — username/ID extraction (informational)
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Story URL parsing', () {
    test('IG-STORY-PARSE-001 story URL structure contains username', () {
      final uri = Uri.parse(
        'https://www.instagram.com/stories/testuser/1234567890/',
      );
      final storyMatch =
          RegExp(r'/stories/([^/]+)/(\d+)/?').firstMatch(uri.path);
      expect(storyMatch, isNotNull);
      expect(storyMatch!.group(1), 'testuser');
      expect(storyMatch.group(2), '1234567890');
    });

    test('IG-STORY-PARSE-002 story URL with underscored username', () {
      final uri = Uri.parse(
        'https://www.instagram.com/stories/test_user_123/9999999999/',
      );
      final storyMatch =
          RegExp(r'/stories/([^/]+)/(\d+)/?').firstMatch(uri.path);
      expect(storyMatch, isNotNull);
      expect(storyMatch!.group(1), 'test_user_123');
      expect(storyMatch.group(2), '9999999999');
    });

    test('IG-STORY-PARSE-003 bare /stories/ path with no segments', () {
      final uri = Uri.parse('https://www.instagram.com/stories/');
      final storyMatch =
          RegExp(r'/stories/([^/]+)/(\d+)/?').firstMatch(uri.path);
      expect(storyMatch, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Story — embed/fetch targets
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Story fetch targets', () {
    test('IG-STORY-FETCH-001 story URL produces no embed target', () {
      final uri = Uri.parse(
        'https://www.instagram.com/stories/username/1234567890/',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(
        targets.any((t) => t.path.contains('/embed/')),
        isFalse,
        reason: 'Stories have no embed path',
      );
    });

    test('IG-STORY-FETCH-002 story URL original is only target', () {
      final uri = Uri.parse(
        'https://www.instagram.com/stories/username/1234567890/',
      );
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(targets.length, 1);
      expect(targets.first, uri);
    });
  });
}
