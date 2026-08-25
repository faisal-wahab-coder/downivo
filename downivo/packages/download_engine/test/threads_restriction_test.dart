import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'threads_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = ThreadsMockAdapter();
    ThreadsMockAdapter.reset();
  });

  group('Threads restricted content', () {
    test('TH-REST-001 private HTML is RESTRICTED', () {
      expect(
        ThreadsResolver.classifyHtml(threadsPrivateHtml()),
        ThreadsHtmlStatus.restricted,
      );
      expect(
        ThreadsResolver.accessFor(
          Uri.parse(threadsPostUrl),
          html: threadsPrivateHtml(),
        ),
        ThreadsAccess.restricted,
      );
      expect(
        ThreadsResolver.userFacingError(
          Uri.parse(threadsPostUrl),
          html: threadsPrivateHtml(),
        ),
        contains('restricted'),
      );
    });

    test('TH-REST-002 private HTML is not parsed as media', () {
      expect(
        ThreadsResolver.parseHtmlResources(
          html: threadsPrivateHtml(),
          pageUrl: Uri.parse(threadsPostUrl),
        ),
        isEmpty,
      );
    });

    test('TH-REST-003 resolver throws restricted for private HTML', () async {
      ThreadsMockAdapter.htmlResponse = threadsPrivateHtml();
      expect(
        () => ThreadsResolver(dio: mockDio).discoverAll(Uri.parse(threadsPostUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('restricted'),
          ),
        ),
      );
    });

    test('TH-REST-004 unavailable HTML is CONTENT_UNAVAILABLE', () {
      expect(
        ThreadsResolver.classifyHtml(threadsUnavailableHtml()),
        ThreadsHtmlStatus.unavailable,
      );
      expect(
        ThreadsResolver.userFacingError(
          Uri.parse(threadsPostUrl),
          html: threadsUnavailableHtml(),
        ),
        contains('no longer available'),
      );
    });

    test('TH-REST-005 unavailable HTML is not parsed as media', () {
      expect(
        ThreadsResolver.parseHtmlResources(
          html: threadsUnavailableHtml(),
          pageUrl: Uri.parse(threadsPostUrl),
        ),
        isEmpty,
      );
    });
  });
}
