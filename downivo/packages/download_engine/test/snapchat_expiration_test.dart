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

  group('Snapchat expiration', () {
    test('SC-EXP-001 expired HTML is EXPIRED', () {
      expect(
        SnapchatResolver.classifyHtml(snapchatExpiredHtml()),
        SnapchatHtmlStatus.expired,
      );
      expect(
        SnapchatResolver.accessFor(
          Uri.parse(snapchatSpotlightUrl),
          html: snapchatExpiredHtml(),
        ),
        SnapchatAccess.expired,
      );
    });

    test('SC-EXP-002 expired user message', () {
      expect(
        SnapchatResolver.userFacingError(
          Uri.parse(snapchatSpotlightUrl),
          html: snapchatExpiredHtml(),
        ),
        contains('expired'),
      );
    });

    test('SC-EXP-003 expired HTML is not downloaded', () async {
      SnapchatMockAdapter.htmlResponse = snapchatExpiredHtml();
      expect(
        () => SnapchatResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(snapchatSpotlightUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('expired'),
          ),
        ),
      );
    });

    test('SC-EXP-004 expired HTML yields no media items', () {
      expect(
        SnapchatResolver.parseHtmlResources(
          html: snapchatExpiredHtml(),
          pageUrl: Uri.parse(snapchatSpotlightUrl),
        ),
        isEmpty,
      );
    });
  });
}
