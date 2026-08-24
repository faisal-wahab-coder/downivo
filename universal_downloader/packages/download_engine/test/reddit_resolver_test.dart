import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = RedditMockAdapter();
    RedditMockAdapter.reset();
  });

  group('Phase 1 — JSON video discovery', () {
    test('RD-RES-001 discovers video from reddit_video fallback_url', () async {
      RedditMockAdapter.jsonResponse = encodeListing(redditVideoPost());
      final resolver = RedditResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.reddit.com/r/videos/comments/abc123/clip/'),
      );

      expect(result, isNotNull);
      expect(result!.directUrl, contains('v.redd.it'));
      expect(result.directUrl, contains('DASH_720.mp4'));
      expect(result.platform, 'Reddit');
      expect(result.mimeType, 'video/mp4');
      expect(result.title, 'A Reddit Video');
    });

    test('RD-RES-002 does not use HLS playlist as direct URL', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/videos/comments/abc123/x/'),
        payload: redditListing(redditVideoPost()),
      );
      expect(result!.directUrl.contains('.m3u8'), isFalse);
      expect(result.directUrl.contains('.mpd'), isFalse);
    });

    test('RD-RES-003 filename ends with .mp4', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/videos/comments/abc123/x/'),
        payload: redditListing(redditVideoPost()),
      );
      expect(result!.fileName, endsWith('.mp4'));
    });
  });

  group('Phase 2 — Image discovery', () {
    test('RD-RES-010 discovers jpg image post', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/img123/x/'),
        payload: redditListing(redditImagePost()),
      );
      expect(result, isNotNull);
      expect(result!.mimeType, 'image/jpeg');
      expect(result.directUrl, contains('i.redd.it'));
    });

    test('RD-RES-011 discovers png image post', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/img123/x/'),
        payload: redditListing(
          redditImagePost(url: 'https://i.redd.it/photo.png'),
        ),
      );
      expect(result!.mimeType, 'image/png');
    });

    test('RD-RES-012 discovers webp image post', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/img123/x/'),
        payload: redditListing(
          redditImagePost(url: 'https://i.redd.it/photo.webp'),
        ),
      );
      expect(result!.mimeType, 'image/webp');
    });
  });

  group('Phase 3 — Non-downloadable pages', () {
    test('RD-RES-020 home returns null', () async {
      final resolver = RedditResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.reddit.com/'));
      expect(result, isNull);
    });

    test('RD-RES-021 subreddit returns null', () async {
      final resolver = RedditResolver(dio: mockDio);
      final result =
          await resolver.discover(Uri.parse('https://www.reddit.com/r/pics/'));
      expect(result, isNull);
    });

    test('RD-RES-022 user profile returns null', () async {
      final resolver = RedditResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.reddit.com/user/spez/'),
      );
      expect(result, isNull);
    });

    test('RD-RES-023 text-only self post returns null', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse(
          'https://www.reddit.com/r/askreddit/comments/text1/x/',
        ),
        payload: redditListing(redditSelfPost()),
      );
      expect(result, isNull);
    });
  });

  group('Phase 4 — Direct media URLs', () {
    test('RD-RES-030 i.redd.it jpg is discovered as image', () async {
      final resolver = RedditResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://i.redd.it/direct.jpg'),
      );
      expect(result, isNotNull);
      expect(result!.mimeType, 'image/jpeg');
      expect(result.directUrl, contains('i.redd.it/direct.jpg'));
    });

    test('RD-RES-031 v.redd.it DASH mp4 is discovered as video', () async {
      final resolver = RedditResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://v.redd.it/abc/DASH_720.mp4'),
      );
      expect(result, isNotNull);
      expect(result!.mimeType, 'video/mp4');
    });
  });

  group('Phase 5 — Share URL redirect', () {
    test('RD-RES-040 share URL resolves via redirect then JSON', () async {
      RedditMockAdapter.redirectLocation =
          'https://www.reddit.com/r/pics/comments/img123/slug/';
      RedditMockAdapter.jsonResponse = encodeListing(redditImagePost());

      final resolver = RedditResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.reddit.com/r/pics/s/ShareCode'),
      );

      expect(result, isNotNull);
      expect(result!.platform, 'Reddit');
      expect(result.mimeType, 'image/jpeg');
    });
  });

  group('Phase 6 — HTML fallback', () {
    test('RD-RES-050 extracts fallback_url from HTML when JSON empty', () async {
      RedditMockAdapter.jsonResponse = '[]';
      RedditMockAdapter.htmlResponse =
          '<html><script>{"fallback_url":"https://v.redd.it/htmlvid/DASH_720.mp4"}</script></html>';

      final resolver = RedditResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse('https://www.reddit.com/r/videos/comments/abc123/x/'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('htmlvid'));
      expect(result.mimeType, 'video/mp4');
    });
  });

  group('Phase 7 — Registry integration', () {
    test('RD-RES-060 registry discovers Reddit video', () async {
      RedditMockAdapter.jsonResponse = encodeListing(redditVideoPost());
      final registry = ContentProviderRegistry(dio: mockDio);
      final result = await registry.discover(
        Uri.parse('https://www.reddit.com/r/videos/comments/abc123/x/'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Reddit');
    });

    test('RD-RES-061 registry discoverAll returns gallery items', () async {
      RedditMockAdapter.jsonResponse = encodeListing(redditGalleryPost());
      final registry = ContentProviderRegistry(dio: mockDio);
      final results = await registry.discoverAll(
        Uri.parse('https://www.reddit.com/r/pics/comments/gal123/x/'),
      );
      expect(results.length, 3);
      expect(results.every((r) => r.platform == 'Reddit'), isTrue);
    });

    test('RD-RES-062 registry does not scrape homepage HTML', () async {
      RedditMockAdapter.htmlResponse =
          '<html><script>{"fallback_url":"https://v.redd.it/nope/DASH_720.mp4"}</script></html>';
      final registry = ContentProviderRegistry(dio: mockDio);
      final result =
          await registry.discover(Uri.parse('https://www.reddit.com/'));
      expect(result, isNull);
    });
  });

  group('Phase 8 — File naming', () {
    test('RD-RES-070 path traversal in title is sanitized', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
        payload: redditListing(
          redditImagePost(title: '../../../../etc/passwd'),
        ),
      );
      expect(result, isNotNull);
      expect(result!.fileName, isNot(contains('..')));
      expect(result.fileName, isNot(contains('/')));
    });

    test('RD-RES-071 unicode title does not crash', () {
      final result = RedditResolver.parsePostJson(
        pageUrl: Uri.parse('https://www.reddit.com/r/pics/comments/abc/x/'),
        payload: redditListing(
          redditImagePost(title: 'مرحبا بالعالم 🎉'),
        ),
      );
      expect(result, isNotNull);
      expect(result!.fileName, isNotEmpty);
    });
  });

  group('Phase 9 — MIME helpers', () {
    test('RD-RES-080 image/jpg normalizes to image/jpeg', () {
      expect(RedditResolver.normalizeMime('image/jpg'), 'image/jpeg');
    });

    test('RD-RES-081 mimeFromUrl maps extensions', () {
      expect(RedditResolver.mimeFromUrl('https://i.redd.it/a.jpg'), 'image/jpeg');
      expect(RedditResolver.mimeFromUrl('https://i.redd.it/a.png'), 'image/png');
      expect(RedditResolver.mimeFromUrl('https://i.redd.it/a.webp'), 'image/webp');
      expect(RedditResolver.mimeFromUrl('https://i.redd.it/a.gif'), 'image/gif');
      expect(
        RedditResolver.mimeFromUrl('https://v.redd.it/x/DASH_720.mp4'),
        'video/mp4',
      );
    });
  });

  group('Phase 10 — Off-platform link posts', () {
    test('RD-RES-090 extracts YouTube URL from r/videos 3wbg49-style post', () {
      final payload = redditListing(redditYouTubeLinkPost());
      expect(RedditResolver.parsePostJson(
        pageUrl: Uri.parse(
          'https://www.reddit.com/r/videos/comments/3wbg49/dude_has_epic_meltdown_over_bad_haircut/',
        ),
        payload: payload,
      ), isNull);
      expect(
        RedditResolver.linkedUrlFromPayload(payload).toString(),
        'https://www.youtube.com/watch?v=TzBDpdhC8Hs',
      );
    });

    test('RD-RES-091 does not treat i.redd.it as an off-platform link', () {
      expect(
        RedditResolver.linkedUrlFromPayload(
          redditListing(redditImagePost()),
        ),
        isNull,
      );
    });

    test('RD-RES-092 discoverAll follows YouTube via resolveLinkedPage', () async {
      RedditMockAdapter.jsonResponse =
          encodeListing(redditYouTubeLinkPost());
      final resolver = RedditResolver(
        dio: mockDio,
        resolveLinkedPage: (uri) async {
          expect(uri.host, 'www.youtube.com');
          expect(uri.queryParameters['v'], 'TzBDpdhC8Hs');
          return [
            DiscoveredResource(
              directUrl: 'https://example.googlevideo.com/video.mp4',
              fileName: 'meltdown.mp4',
              platform: 'YouTube',
              mimeType: 'video/mp4',
            ),
          ];
        },
      );
      final result = await resolver.discover(
        Uri.parse(
          'https://www.reddit.com/r/videos/comments/3wbg49/dude_has_epic_meltdown_over_bad_haircut/',
        ),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'YouTube');
      expect(result.directUrl, contains('googlevideo.com'));
    });

    test('RD-RES-093 youtube link post without callback returns null', () async {
      RedditMockAdapter.jsonResponse =
          encodeListing(redditYouTubeLinkPost());
      final resolver = RedditResolver(dio: mockDio);
      final result = await resolver.discover(
        Uri.parse(
          'https://www.reddit.com/r/videos/comments/3wbg49/x/',
        ),
      );
      expect(result, isNull);
    });
  });
}
