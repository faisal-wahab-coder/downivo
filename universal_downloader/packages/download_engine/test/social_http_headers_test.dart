import 'package:download_engine/src/content_providers/social_http_headers.dart';
import 'package:download_engine/src/content_providers/social_platform.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SocialHttpHeaders.forMediaDownload', () {
    test('omits Chrome impersonation for generic direct files', () {
      final headers = SocialHttpHeaders.forMediaDownload(
        pageUrl: Uri.parse(
          'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
        ),
        mediaUrl:
            'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
      );

      expect(headers['User-Agent'], isNull);
      expect(headers['Origin'], isNull);
      expect(headers['Referer'], isNull);
      expect(headers['Accept'], '*/*');
      expect(headers, equals(SocialHttpHeaders.forDirectFile()));
    });

    test('still impersonates Chrome for social media downloads', () {
      final headers = SocialHttpHeaders.forMediaDownload(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/video/123'),
        mediaUrl: 'https://v16.tiktokcdn.com/a/video.mp4',
        platform: SocialPlatform.tiktok,
      );

      expect(headers['User-Agent'], SocialHttpHeaders.userAgent);
      expect(headers['Origin'], 'https://www.tiktok.com');
      expect(headers['Referer'], contains('tiktok.com'));
    });

    test('uses YouTube UA for googlevideo even without a page platform', () {
      final headers = SocialHttpHeaders.forMediaDownload(
        pageUrl: Uri.parse('https://rr1.googlevideo.com/videoplayback'),
        mediaUrl: 'https://rr1.googlevideo.com/videoplayback?itag=22',
      );

      expect(headers['User-Agent'], contains('com.google.android.youtube'));
    });
  });
}
