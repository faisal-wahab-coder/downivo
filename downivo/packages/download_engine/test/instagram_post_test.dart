import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 1 / 8 — Instagram Post and IGTV URL detection, video/image
/// distinction, and content type handling.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Post URL detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Post URL detection', () {
    test('IG-POST-001 standard /p/ URL detected', () {
      final uri = Uri.parse('https://www.instagram.com/p/BcDeFgHiJk/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'BcDeFgHiJk');
    });

    test('IG-POST-002 /p/ URL without www', () {
      final uri = Uri.parse('https://instagram.com/p/BcDeFgHiJk/');
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'BcDeFgHiJk');
    });

    test('IG-POST-003 /p/ URL with query parameters', () {
      final uri = Uri.parse(
        'https://www.instagram.com/p/BcDeFgHiJk/?utm_source=ig_web_copy_link',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'BcDeFgHiJk');
    });

    test('IG-POST-004 /p/ URL with igsh param (mobile share)', () {
      final uri = Uri.parse(
        'https://www.instagram.com/p/BcDeFgHiJk/?igsh=abc123',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'BcDeFgHiJk');
    });

    test('IG-POST-005 /p/ canonical URL generation', () {
      final uri = Uri.parse('https://www.instagram.com/p/XYZ789/?utm=test');
      final canonical =
          InstagramGraphqlResolver.canonicalPageUrl(uri, 'XYZ789');
      expect(canonical.toString(), 'https://www.instagram.com/p/XYZ789/');
      expect(canonical.hasQuery, isFalse);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Video vs image distinction (post content type)
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Post — video vs image handling', () {
    test('IG-POST-TYPE-001 video post (video_versions) returns resource', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {
                    'url': 'https://cdn.example.com/video.mp4',
                    'width': 1080,
                    'height': 1920,
                  },
                ],
                'caption': {'text': 'Video post'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/VID001/'),
        shortcode: 'VID001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.mimeType, 'video/mp4');
    });

    test('IG-POST-TYPE-002 image-only post returns image resource', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': [
                    {
                      'url': 'https://cdn.example.com/image.jpg',
                      'width': 1080,
                      'height': 1080,
                    },
                  ],
                },
                'caption': {'text': 'Image post'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/IMG001/'),
        shortcode: 'IMG001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/image.jpg');
      expect(result.mimeType, 'image/jpeg');
      expect(result.title, 'Image post');
    });

    test('IG-POST-TYPE-003 post with video_url direct field', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_url': 'https://cdn.example.com/direct.mp4',
                'caption': {'text': 'Direct video URL'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/DIR001/'),
        shortcode: 'DIR001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/direct.mp4');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // IGTV URL detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram IGTV URL detection', () {
    test('IG-TV-001 standard /tv/ URL detected', () {
      final uri = Uri.parse('https://www.instagram.com/tv/LmNoPqRsTu/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'LmNoPqRsTu');
    });

    test('IG-TV-002 /tv/ canonical URL generation', () {
      final uri = Uri.parse('https://www.instagram.com/tv/LmNoPqRsTu/');
      final canonical =
          InstagramGraphqlResolver.canonicalPageUrl(uri, 'LmNoPqRsTu');
      expect(canonical.path, '/tv/LmNoPqRsTu/');
    });

    test('IG-TV-003 /tv/ embed URL generation', () {
      final uri = Uri.parse('https://www.instagram.com/tv/DEF456/');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.instagram);
      expect(
        targets.any((t) => t.path == '/tv/DEF456/embed/'),
        isTrue,
      );
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Post metadata
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Post metadata', () {
    test('IG-POST-META-001 platform label is Instagram', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
                ],
                'caption': {'text': 'Meta test'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/META001/'),
        shortcode: 'META001',
        payload: payload,
      );
      expect(result?.platform, 'Instagram');
    });

    test('IG-POST-META-002 pageUrl preserved in result', () {
      final pageUrl = Uri.parse('https://www.instagram.com/p/META002/');
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
                ],
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: pageUrl,
        shortcode: 'META002',
        payload: payload,
      );
      expect(result?.pageUrl, pageUrl.toString());
    });

    test('IG-POST-META-003 mimeType reflects media type', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
                ],
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/META003/'),
        shortcode: 'META003',
        payload: payload,
      );
      expect(result?.mimeType, 'video/mp4');

      // Image post returns image/jpeg
      final imgPayload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://cdn.example.com/i.jpg', 'width': 1080, 'height': 1080},
                  ],
                },
              },
            ],
          },
        },
      };
      final imgResult = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/META003B/'),
        shortcode: 'META003B',
        payload: imgPayload,
      );
      expect(imgResult?.mimeType, 'image/jpeg');
    });
  });
}
