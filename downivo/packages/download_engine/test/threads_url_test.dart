import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  group('Phase 1 — Threads platform detection', () {
    test('TH-URL-001 threads.net is Threads', () {
      final uri = Uri.parse(threadsPostUrl);
      expect(SocialPlatform.fromUri(uri), SocialPlatform.threads);
      expect(ContentProviderRegistry.canHandle(uri), isTrue);
      expect(ContentProviderRegistry.platformLabel(uri), 'Threads');
    });

    test('TH-URL-002 www.threads.net is Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(threadsHomeUrl)),
        SocialPlatform.threads,
      );
    });

    test('TH-URL-003 threads.com is Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(threadsPostComUrl)),
        SocialPlatform.threads,
      );
    });

    test('TH-URL-004 www.threads.com is Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse(threadsHomeComUrl)),
        SocialPlatform.threads,
      );
    });

    test('TH-URL-005 l.threads.net share host is Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://l.threads.net/$threadsShareCode')),
        SocialPlatform.threads,
      );
    });

    test('TH-URL-006 example.com is not Threads', () {
      final uri = Uri.parse('https://example.com/video.mp4');
      expect(SocialPlatform.fromUri(uri), isNull);
      expect(ContentProviderRegistry.canHandle(uri), isFalse);
    });

    test('TH-URL-007 youtube.com is NOT Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.youtube.com/watch?v=abc')),
        isNot(SocialPlatform.threads),
      );
    });

    test('TH-URL-008 instagram.com is NOT Threads', () {
      expect(
        SocialPlatform.fromUri(Uri.parse('https://www.instagram.com/p/AbC123/')),
        isNot(SocialPlatform.threads),
      );
    });
  });

  group('Phase 2 — Content type classification', () {
    test('TH-URL-020 home is HOME', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsHomeUrl)),
        ThreadsContentType.home,
      );
      expect(
        ThreadsResolver.classifyUrl(Uri.parse(threadsHomeComUrl)),
        ThreadsContentType.home,
      );
    });

    test('TH-URL-021 profile is PROFILE', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsProfileUrl)),
        ThreadsContentType.profile,
      );
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsProfileComUrl)),
        ThreadsContentType.profile,
      );
    });

    test('TH-URL-022 post is POST', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsPostUrl)),
        ThreadsContentType.post,
      );
    });

    test('TH-URL-023 threads.com post is POST', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsPostComUrl)),
        ThreadsContentType.post,
      );
    });

    test('TH-URL-024 /t/{id} is POST', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsShortPostUrl)),
        ThreadsContentType.post,
      );
    });

    test('TH-URL-025 embed is EMBED', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsEmbedUrl)),
        ThreadsContentType.embed,
      );
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsBareEmbedUrl)),
        ThreadsContentType.embed,
      );
    });

    test('TH-URL-026 share host is SHARE', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse('https://l.threads.net/$threadsShareCode')),
        ThreadsContentType.share,
      );
    });

    test('TH-URL-027 login is AUTHENTICATION', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsLoginUrl)),
        ThreadsContentType.authentication,
      );
    });

    test('TH-URL-028 /INVALID is NON_CONTENT', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsInvalidPathUrl)),
        ThreadsContentType.nonContent,
      );
    });

    test('TH-URL-029 search is NON_CONTENT', () {
      expect(
        ThreadsUri.classifyUrl(Uri.parse('https://www.threads.net/search')),
        ThreadsContentType.nonContent,
      );
    });
  });

  group('Phase 3 — ID and username extraction', () {
    test('TH-URL-040 post ID from /@user/post/{id}', () {
      expect(ThreadsUri.postIdFromUri(Uri.parse(threadsPostUrl)), threadsPostId);
    });

    test('TH-URL-041 post ID from /t/{id}', () {
      expect(
        ThreadsUri.postIdFromUri(Uri.parse(threadsShortPostUrl)),
        threadsPostId,
      );
    });

    test('TH-URL-042 username from profile and post', () {
      expect(
        ThreadsUri.usernameFromUri(Uri.parse(threadsProfileUrl)),
        threadsUsername,
      );
      expect(
        ThreadsUri.usernameFromUri(Uri.parse(threadsPostUrl)),
        threadsUsername,
      );
    });

    test('TH-URL-043 home has no post ID', () {
      expect(ThreadsUri.postIdFromUri(Uri.parse(threadsHomeUrl)), isNull);
    });
  });

  group('Phase 4 — Normalization and identity', () {
    test('TH-URL-050 tracking params collapse to the same identity', () {
      final a = ThreadsUri.contentIdentity(ThreadsUri.normalize(Uri.parse(threadsPostUrl)));
      final b = ThreadsUri.contentIdentity(ThreadsUri.normalize(Uri.parse(threadsTrackedUrl)));
      final c = ThreadsUri.contentIdentity(ThreadsUri.normalize(Uri.parse(threadsShareUrl)));
      expect(a, 'threads:post:$threadsPostId');
      expect(b, a);
      expect(c, a);
    });

    test('TH-URL-051 threads.com normalizes to threads.net', () {
      expect(
        ThreadsUri.normalize(Uri.parse(threadsPostComUrl)).toString(),
        threadsPostUrl,
      );
    });

    test('TH-URL-052 fragment is stripped', () {
      expect(
        ThreadsUri.normalize(Uri.parse('$threadsPostUrl#comments')).toString(),
        threadsPostUrl,
      );
    });

    test('TH-URL-053 profile identity is username-based', () {
      expect(
        ThreadsUri.contentIdentity(Uri.parse(threadsProfileUrl)),
        'threads:profile:$threadsUsername',
      );
      expect(
        ThreadsUri.contentIdentity(Uri.parse(threadsProfileComUrl)),
        'threads:profile:$threadsUsername',
      );
    });

    test('TH-URL-054 home identity is stable', () {
      expect(ThreadsUri.contentIdentity(Uri.parse(threadsHomeUrl)), 'threads:home');
      expect(
        ThreadsUri.contentIdentity(Uri.parse(threadsHomeComUrl)),
        'threads:home',
      );
    });

    test('TH-URL-055 downloadable only for post/embed/share', () {
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsPostUrl)), isTrue);
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsEmbedUrl)), isTrue);
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsProfileUrl)), isFalse);
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsHomeUrl)), isFalse);
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsLoginUrl)), isFalse);
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsInvalidPathUrl)), isFalse);
    });
  });
}
