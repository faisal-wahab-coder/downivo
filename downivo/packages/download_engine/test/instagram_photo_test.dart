import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 4 / 8 — Instagram photo post download: image extraction,
/// image_versions2 quality selection, display_url fallback, and MIME handling.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Photo extraction from modern payload
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram photo extraction — modern payload', () {
    test('IG-PHOTO-001 image_versions2 candidates → best width image', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://cdn.example.com/img_150.jpg', 'width': 150, 'height': 150},
                    {'url': 'https://cdn.example.com/img_640.jpg', 'width': 640, 'height': 640},
                    {'url': 'https://cdn.example.com/img_1080.jpg', 'width': 1080, 'height': 1080},
                  ],
                },
                'caption': {'text': 'Beautiful photo'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO01/'),
        shortcode: 'PHOTO01',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('img_1080'));
      expect(result.mimeType, 'image/jpeg');
      expect(result.title, 'Beautiful photo');
      expect(result.platform, 'Instagram');
    });

    test('IG-PHOTO-002 single image candidate selected', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://cdn.example.com/only.jpg', 'width': 1080, 'height': 1350},
                  ],
                },
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO02/'),
        shortcode: 'PHOTO02',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/only.jpg');
    });

    test('IG-PHOTO-003 video takes priority over image', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {'url': 'https://cdn.example.com/video.mp4', 'width': 720, 'height': 1280},
                ],
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://cdn.example.com/thumb.jpg', 'width': 1080, 'height': 1080},
                  ],
                },
                'caption': {'text': 'Video post with thumb'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO03/'),
        shortcode: 'PHOTO03',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('video.mp4'));
      expect(result.mimeType, 'video/mp4');
    });

    test('IG-PHOTO-004 empty image_versions2 candidates returns null', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': <dynamic>[],
                },
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO04/'),
        shortcode: 'PHOTO04',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-PHOTO-005 non-HTTP image URL rejected', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': [
                    {'url': 'file:///local/image.jpg', 'width': 1080, 'height': 1080},
                  ],
                },
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO05/'),
        shortcode: 'PHOTO05',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-PHOTO-006 display_url fallback when no image_versions2', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'display_url': 'https://cdn.example.com/display.jpg',
                'caption': {'text': 'Fallback display'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO06/'),
        shortcode: 'PHOTO06',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/display.jpg');
      expect(result.mimeType, 'image/jpeg');
    });

    test('IG-PHOTO-007 thumbnail_src fallback', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'thumbnail_src': 'https://cdn.example.com/thumb_src.jpg',
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO07/'),
        shortcode: 'PHOTO07',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/thumb_src.jpg');
    });

    test('IG-PHOTO-008 prefers full-aspect image over square crop', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'original_width': 1080,
                'original_height': 1350,
                'image_versions2': {
                  'candidates': [
                    {
                      'url': 'https://cdn.example.com/img_full.jpg',
                      'width': 1080,
                      'height': 1350,
                    },
                    {
                      'url':
                          'https://cdn.example.com/img_square.jpg?stp=dst-jpg_e35_s1080x1080',
                      'width': 1080,
                      'height': 1080,
                    },
                  ],
                },
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO08/'),
        shortcode: 'PHOTO08',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('img_full'));
    });

    test('IG-PHOTO-009 prefers display_url over cropped thumbnail_src', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'display_url': 'https://cdn.example.com/display.jpg',
                'thumbnail_src': 'https://cdn.example.com/thumb_src.jpg',
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PHOTO09/'),
        shortcode: 'PHOTO09',
        payload: payload,
      );
      expect(result!.directUrl, 'https://cdn.example.com/display.jpg');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Photo extraction from legacy payload
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram photo extraction — legacy payload', () {
    test('IG-PHOTO-LEGACY-001 legacy display_url returns image', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'LEG01',
            'display_url': 'https://cdn.example.com/legacy_img.jpg',
            'edge_media_to_caption': {
              'edges': [
                {'node': {'text': 'Legacy photo'}},
              ],
            },
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/LEG01/'),
        shortcode: 'LEG01',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/legacy_img.jpg');
      expect(result.mimeType, 'image/jpeg');
      expect(result.title, 'Legacy photo');
    });

    test('IG-PHOTO-LEGACY-002 legacy thumbnail_src returns image', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'LEG02',
            'thumbnail_src': 'https://cdn.example.com/thumb.jpg',
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/LEG02/'),
        shortcode: 'LEG02',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/thumb.jpg');
    });

    test('IG-PHOTO-LEGACY-003 legacy video_url takes priority over display_url', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'LEG03',
            'video_url': 'https://cdn.example.com/video.mp4',
            'display_url': 'https://cdn.example.com/image.jpg',
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/LEG03/'),
        shortcode: 'LEG03',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('video.mp4'));
      expect(result.mimeType, 'video/mp4');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Photo filename and MIME
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram photo filename and MIME', () {
    test('IG-PHOTO-FN-001 photo filename has image extension', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://cdn.example.com/photo_abc.jpg', 'width': 1080, 'height': 1080},
                  ],
                },
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PFILE01/'),
        shortcode: 'PFILE01',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.fileName, isNotNull);
      expect(
        result.fileName!.endsWith('.jpg') || result.fileName!.endsWith('.jpeg'),
        isTrue,
      );
    });

    test('IG-PHOTO-FN-002 photo MIME is image/jpeg', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://cdn.example.com/img.jpg', 'width': 1080, 'height': 1080},
                  ],
                },
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/PFILE02/'),
        shortcode: 'PFILE02',
        payload: payload,
      );
      expect(result?.mimeType, 'image/jpeg');
    });
  });
}
