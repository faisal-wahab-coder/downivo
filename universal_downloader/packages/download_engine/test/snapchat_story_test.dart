import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'snapchat_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = SnapchatMockAdapter();
    SnapchatMockAdapter.reset();
  });

  group('Snapchat public Story', () {
    test('SC-STORY-001 story URL is PUBLIC_STORY', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatStoryUrl)),
        SnapchatContentType.publicStory,
      );
    });

    test('SC-STORY-002 saved highlights is SAVED_STORY', () {
      expect(
        SnapchatUri.classifyUrl(Uri.parse(snapchatSavedStoryUrl)),
        SnapchatContentType.savedStory,
      );
    });

    test('SC-STORY-003 multi-snap HTML is STORY', () {
      expect(
        SnapchatResolver.detectMediaType(snapchatStoryHtml()),
        SnapchatMediaType.story,
      );
    });

    test('SC-STORY-004 preserves count and order', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatStoryHtml(),
        pageUrl: Uri.parse(snapchatStoryUrl),
      );
      expect(results, hasLength(2));
      expect(results[0].directUrl, snapchatPhotoUrl);
      expect(results[1].directUrl, snapchatPhotoUrlTwo);
    });

    test('SC-STORY-005 indexed filenames for story snaps', () {
      final results = SnapchatResolver.parseHtmlResources(
        html: snapchatStoryHtml(),
        pageUrl: Uri.parse(snapchatStoryUrl),
      );
      expect(results[0].fileName, isNot(equals(results[1].fileName)));
    });

    test('SC-STORY-006 discoverAll returns every snap', () async {
      SnapchatMockAdapter.htmlResponse = snapchatStoryHtml();
      final results = await SnapchatResolver(dio: mockDio).discoverAll(
        Uri.parse(snapchatStoryUrl),
      );
      expect(results, hasLength(2));
      expect(results.every((r) => r.platform == 'Snapchat'), isTrue);
    });
  });
}
