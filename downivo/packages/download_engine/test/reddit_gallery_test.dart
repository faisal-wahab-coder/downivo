import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'reddit_fixtures.dart';

void main() {
  final pageUrl =
      Uri.parse('https://www.reddit.com/r/pics/comments/gal123/album/');

  group('Reddit gallery extraction', () {
    test('RD-GAL-001 extracts all gallery items', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(redditGalleryPost()),
      );
      expect(results.length, 3);
    });

    test('RD-GAL-002 preserves gallery ordering', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(redditGalleryPost()),
      );
      expect(results[0].directUrl, contains('a.jpg'));
      expect(results[1].directUrl, contains('b.png'));
      expect(results[2].directUrl, contains('c.webp'));
    });

    test('RD-GAL-003 gallery items have unique filenames', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(redditGalleryPost()),
      );
      final names = results.map((r) => r.fileName).toSet();
      expect(names.length, results.length);
    });

    test('RD-GAL-004 mixed MIME types are preserved independently', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(
          redditGalleryPost(
            items: [
              (
                id: 'i1',
                url: 'https://preview.redd.it/one.jpg',
                mime: 'image/jpg',
                kind: 'Image',
              ),
              (
                id: 'v1',
                url: 'https://i.redd.it/clip.mp4',
                mime: 'video/mp4',
                kind: 'Image',
              ),
              (
                id: 'g1',
                url: 'https://i.redd.it/loop.gif',
                mime: 'image/gif',
                kind: 'AnimatedImage',
              ),
            ],
          ),
        ),
      );
      expect(results.length, 3);
      expect(results[0].mimeType, 'image/jpeg');
      expect(results[1].mimeType, 'video/mp4');
      expect(results[2].mimeType, 'image/gif');
    });

    test('RD-GAL-005 image/jpg metadata maps to jpeg extension', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(redditGalleryPost()),
      );
      expect(results.first.fileName, endsWith('.jpg'));
    });

    test('RD-GAL-006 no duplicate media URLs', () {
      final results = RedditResolver.parseAllMedia(
        pageUrl: pageUrl,
        payload: redditListing(redditGalleryPost()),
      );
      final urls = results.map((r) => r.directUrl).toSet();
      expect(urls.length, results.length);
    });

    test('RD-GAL-007 parsePostJson returns first gallery item', () {
      final first = RedditResolver.parsePostJson(
        pageUrl: pageUrl,
        payload: redditListing(redditGalleryPost()),
      );
      expect(first!.directUrl, contains('a.jpg'));
    });

    test('RD-GAL-008 gallery count is in post info', () {
      final info = RedditResolver.parsePostInfo(
        payload: redditListing(redditGalleryPost()),
      );
      expect(info!.isGallery, isTrue);
      expect(info.galleryCount, 3);
    });
  });

  group('Reddit gallery via HTTP discoverAll', () {
    late Dio mockDio;

    setUp(() {
      mockDio = Dio();
      mockDio.httpClientAdapter = RedditMockAdapter();
      RedditMockAdapter.reset();
    });

    test('RD-GAL-020 discoverAll returns ordered gallery', () async {
      RedditMockAdapter.jsonResponse = encodeListing(redditGalleryPost());
      final resolver = RedditResolver(dio: mockDio);
      final results = await resolver.discoverAll(pageUrl);
      expect(results.length, 3);
      expect(results[0].directUrl, contains('a.jpg'));
      expect(results[2].directUrl, contains('c.webp'));
    });
  });
}
