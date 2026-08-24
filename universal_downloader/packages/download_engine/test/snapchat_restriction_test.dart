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

  group('Snapchat restricted content', () {
    test('SC-REST-001 chat is RESTRICTED and not downloaded', () {
      final uri = Uri.parse(snapchatChatUrl);
      expect(SnapchatUri.isRestricted(uri), isTrue);
      expect(SnapchatResolver.accessFor(uri), SnapchatAccess.restricted);
      expect(SnapchatResolver.userFacingError(uri), contains('restricted'));
    });

    test('SC-REST-002 memories is RESTRICTED', () {
      final uri = Uri.parse(snapchatMemoriesUrl);
      expect(SnapchatUri.isRestricted(uri), isTrue);
      expect(SnapchatResolver.userFacingError(uri), contains('restricted'));
    });

    test('SC-REST-003 private HTML is RESTRICTED', () {
      expect(
        SnapchatResolver.classifyHtml(snapchatPrivateHtml()),
        SnapchatHtmlStatus.restricted,
      );
      expect(
        SnapchatResolver.accessFor(
          Uri.parse(snapchatSpotlightUrl),
          html: snapchatPrivateHtml(),
        ),
        SnapchatAccess.restricted,
      );
    });

    test('SC-REST-004 resolver does not fetch chat URLs', () async {
      SnapchatMockAdapter.htmlResponse = snapchatPhotoHtml();
      final results = await SnapchatResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(snapchatChatUrl));
      expect(results, isEmpty);
    });

    test('SC-REST-005 resolver does not fetch memories URLs', () async {
      SnapchatMockAdapter.htmlResponse = snapchatPhotoHtml();
      final results = await SnapchatResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(snapchatMemoriesUrl));
      expect(results, isEmpty);
    });

    test('SC-REST-006 private HTML is not parsed as media', () {
      expect(
        SnapchatResolver.parseHtmlResources(
          html: snapchatPrivateHtml(),
          pageUrl: Uri.parse(snapchatSpotlightUrl),
        ),
        isEmpty,
      );
    });
  });
}
