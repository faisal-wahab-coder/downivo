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

  group('Threads profile', () {
    test('TH-PROF-001 profile is not downloadable', () {
      expect(ThreadsUri.isDownloadable(Uri.parse(threadsProfileUrl)), isFalse);
      expect(
        ThreadsUri.classifyUrl(Uri.parse(threadsProfileUrl)),
        ThreadsContentType.profile,
      );
    });

    test('TH-PROF-002 profile metadata is extracted without download', () {
      final info = ThreadsResolver.parseProfileInfo(
        html: threadsProfileHtml(),
        pageUrl: Uri.parse(threadsProfileUrl),
      );
      expect(info.username, threadsUsername);
      expect(info.displayName, threadsDisplayName);
      expect(info.description, isNotNull);
    });

    test('TH-PROF-003 resolver does not download a profile', () async {
      ThreadsMockAdapter.htmlResponse = threadsProfileHtml();
      final results = await ThreadsResolver(dio: mockDio).discoverAll(
        Uri.parse(threadsProfileUrl),
      );
      expect(results, isEmpty);
    });

    test('TH-PROF-004 profile error mentions profile', () {
      expect(
        ThreadsResolver.userFacingError(Uri.parse(threadsProfileUrl)),
        contains('profile'),
      );
    });

    test('TH-PROF-005 threads.com profile matches threads.net identity', () {
      expect(
        ThreadsUri.contentIdentity(Uri.parse(threadsProfileComUrl)),
        ThreadsUri.contentIdentity(Uri.parse(threadsProfileUrl)),
      );
    });
  });
}
