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

  group('Threads authentication', () {
    test('TH-AUTH-001 login URL is AUTHENTICATION_REQUIRED', () {
      final uri = Uri.parse(threadsLoginUrl);
      expect(ThreadsUri.requiresAuthentication(uri), isTrue);
      expect(
        ThreadsResolver.accessFor(uri),
        ThreadsAccess.authenticationRequired,
      );
      expect(
        ThreadsResolver.userFacingError(uri),
        contains('authentication'),
      );
    });

    test('TH-AUTH-002 login wall HTML is AUTHENTICATION_REQUIRED', () {
      expect(
        ThreadsResolver.classifyHtml(threadsAuthHtml()),
        ThreadsHtmlStatus.authenticationRequired,
      );
      expect(
        ThreadsResolver.accessFor(
          Uri.parse(threadsPostUrl),
          html: threadsAuthHtml(),
        ),
        ThreadsAccess.authenticationRequired,
      );
    });

    test('TH-AUTH-003 resolver does not fetch login URLs', () async {
      ThreadsMockAdapter.htmlResponse = threadsVideoHtml();
      final results = await ThreadsResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(threadsLoginUrl));
      expect(results, isEmpty);
    });

    test('TH-AUTH-004 login HTML on a public URL is not downloaded', () async {
      ThreadsMockAdapter.htmlResponse = threadsAuthHtml();
      expect(
        () => ThreadsResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(threadsPostUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('authentication'),
          ),
        ),
      );
    });

    test('TH-AUTH-005 public post is PUBLIC', () {
      expect(
        ThreadsResolver.accessFor(
          Uri.parse(threadsPostUrl),
          html: threadsVideoHtml(),
        ),
        ThreadsAccess.public,
      );
    });

    test('TH-AUTH-007 login chrome plus public media is not a login wall', () {
      final html = threadsPublicHtmlWithLoginChrome();
      expect(ThreadsResolver.classifyHtml(html), ThreadsHtmlStatus.ok);
      expect(
        ThreadsResolver.accessFor(Uri.parse(threadsPostUrl), html: html),
        ThreadsAccess.public,
      );
      expect(
        ThreadsResolver.parseHtmlResources(
          html: html,
          pageUrl: Uri.parse(threadsPostUrl),
          contentId: threadsPostId,
        ),
        isNotEmpty,
      );
    });

    test('TH-AUTH-006 no official Threads login exists in the app', () {
      expect(ThreadsUri.requiresAuthentication(Uri.parse(threadsLoginUrl)), isTrue);
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsLoginUrl)), isFalse);
    });
  });
}
