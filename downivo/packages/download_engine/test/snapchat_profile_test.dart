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

  group('Snapchat public profile', () {
    test('SC-PROF-001 @username is PUBLIC_PROFILE and not downloadable', () {
      final uri = Uri.parse(snapchatProfileUrl);
      expect(SnapchatUri.classifyUrl(uri), SnapchatContentType.publicProfile);
      expect(SnapchatUri.isDownloadable(uri), isFalse);
      expect(SnapchatUri.usernameFromUri(uri), snapchatUsername);
    });

    test('SC-PROF-002 /add/username is the same profile', () {
      expect(
        SnapchatUri.contentIdentity(Uri.parse(snapchatAddUrl)),
        SnapchatUri.contentIdentity(Uri.parse(snapchatProfileUrl)),
      );
    });

    test('SC-PROF-003 profile is not auto-downloaded', () async {
      SnapchatMockAdapter.htmlResponse = snapchatPhotoHtml();
      final results = await ContentProviderRegistry(dio: mockDio).discoverAll(
        Uri.parse(snapchatProfileUrl),
      );
      expect(results, isEmpty);
    });

    test('SC-PROF-004 profile metadata is extracted from public HTML', () {
      final info = SnapchatResolver.parseProfileInfo(
        html: snapchatProfileHtml(),
        pageUrl: Uri.parse(snapchatAddUrl),
      );
      expect(info.username, snapchatUsername);
      expect(info.displayName, isNotNull);
      expect(info.description, 'Public Snapchat profile');
    });

    test('SC-PROF-005 user error explains profile is not media', () {
      expect(
        SnapchatResolver.userFacingError(Uri.parse(snapchatProfileUrl)),
        contains('profile'),
      );
    });
  });
}
