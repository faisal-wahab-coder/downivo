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

  group('Snapchat authentication', () {
    test('SC-AUTH-001 login URL is AUTHENTICATION_REQUIRED', () {
      final uri = Uri.parse(snapchatLoginUrl);
      expect(SnapchatUri.requiresAuthentication(uri), isTrue);
      expect(
        SnapchatResolver.accessFor(uri),
        SnapchatAccess.authenticationRequired,
      );
      expect(
        SnapchatResolver.userFacingError(uri),
        contains('authentication'),
      );
    });

    test('SC-AUTH-002 login wall HTML is AUTHENTICATION_REQUIRED', () {
      expect(
        SnapchatResolver.classifyHtml(snapchatAuthHtml()),
        SnapchatHtmlStatus.authenticationRequired,
      );
      expect(
        SnapchatResolver.accessFor(
          Uri.parse(snapchatSpotlightUrl),
          html: snapchatAuthHtml(),
        ),
        SnapchatAccess.authenticationRequired,
      );
    });

    test('SC-AUTH-003 resolver does not fetch login URLs', () async {
      SnapchatMockAdapter.htmlResponse = snapchatVideoHtml();
      final results = await SnapchatResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse(snapchatLoginUrl));
      expect(results, isEmpty);
    });

    test('SC-AUTH-004 login HTML on a public URL is not downloaded', () async {
      SnapchatMockAdapter.htmlResponse = snapchatAuthHtml();
      expect(
        () => SnapchatResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(snapchatSpotlightUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('authentication'),
          ),
        ),
      );
    });

    test('SC-AUTH-005 public Spotlight is PUBLIC', () {
      expect(
        SnapchatResolver.accessFor(
          Uri.parse(snapchatSpotlightUrl),
          html: snapchatVideoHtml(),
        ),
        SnapchatAccess.public,
      );
    });

    test('SC-AUTH-006 accounts host is authentication', () {
      final uri = Uri.parse('https://accounts.snapchat.com/accounts/login');
      expect(SnapchatUri.requiresAuthentication(uri), isTrue);
    });

    test('SC-AUTH-007 no official Snapchat login exists in the app', () {
      expect(SnapchatUri.requiresAuthentication(Uri.parse(snapchatLoginUrl)), isTrue);
      expect(
        SnapchatUri.isDownloadable(Uri.parse(snapchatLoginUrl)),
        isFalse,
      );
    });
  });
}
