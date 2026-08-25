import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 9 — Instagram Carousel post handling.
///
/// Documents current implementation behavior: carousel posts use /p/ path,
/// only the first item is inspected, and only video items are supported.
///
/// All tests are offline unit tests with no network dependency.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Carousel URL detection (same as regular posts)
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Carousel URL detection', () {
    test('IG-CAR-001 carousel uses /p/ path — same as regular post', () {
      final uri = Uri.parse('https://www.instagram.com/p/CarouselID/');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.instagram);
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'CarouselID');
    });

    test('IG-CAR-002 carousel shortcode extraction identical to posts', () {
      final uri = Uri.parse(
        'https://www.instagram.com/p/Carousel123/?utm_source=ig_web_copy_link',
      );
      expect(InstagramGraphqlResolver.shortcodeFromUri(uri), 'Carousel123');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Multi-item payload handling (current behavior)
  // ─────────────────────────────────────────────────────────────────────────

  group('Instagram Carousel multi-item payload', () {
    test('IG-CAR-ITEMS-001 multi-item payload: only first item used', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {'url': 'https://cdn.example.com/first.mp4', 'width': 720, 'height': 1280},
                ],
                'caption': {'text': 'Carousel post'},
              },
              {
                'video_versions': [
                  {'url': 'https://cdn.example.com/second.mp4', 'width': 720, 'height': 1280},
                ],
              },
              {
                'image_versions2': {
                  'candidates': [
                    {'url': 'https://cdn.example.com/third.jpg', 'width': 1080, 'height': 1080},
                  ],
                },
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/CAR001/'),
        shortcode: 'CAR001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('first.mp4'),
          reason: 'Only first item is processed');
    });

    test('IG-CAR-ITEMS-002 carousel with image-first downloads image', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'carousel_media': [
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/first.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                  {
                    'video_versions': [
                      {'url': 'https://cdn.example.com/second.mp4', 'width': 720, 'height': 1280},
                    ],
                  },
                ],
                'caption': {'text': 'Image carousel'},
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/CAR002/'),
        shortcode: 'CAR002',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('first.jpg'));
      expect(result.mimeType, 'image/jpeg');
    });

    test('IG-CAR-ITEMS-003 all-image carousel returns first image', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'carousel_media': [
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/img1.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/img2.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                ],
              },
            ],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/CAR003/'),
        shortcode: 'CAR003',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('img1.jpg'));
      expect(result.mimeType, 'image/jpeg');
    });
  });

  group('Instagram Carousel — parseAllMedia multi-resource discovery', () {
    test('IG-CAR-ALL-001 parseAllMedia returns all carousel items', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'carousel_media': [
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/img1.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                  {
                    'video_versions': [
                      {'url': 'https://cdn.example.com/vid2.mp4', 'width': 720, 'height': 1280},
                    ],
                  },
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/img3.jpg', 'width': 1080, 'height': 1350},
                      ],
                    },
                  },
                ],
                'caption': {'text': 'Mixed carousel'},
              },
            ],
          },
        },
      };
      final results = InstagramGraphqlResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.instagram.com/p/CARALL01/'),
        shortcode: 'CARALL01',
        payload: payload,
      );
      expect(results.length, 3);
      expect(results[0].directUrl, contains('img1.jpg'));
      expect(results[0].mimeType, 'image/jpeg');
      expect(results[1].directUrl, contains('vid2.mp4'));
      expect(results[1].mimeType, 'video/mp4');
      expect(results[2].directUrl, contains('img3.jpg'));
      expect(results[2].mimeType, 'image/jpeg');
    });

    test('IG-CAR-ALL-002 parseAllMedia preserves carousel ordering', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'carousel_media': [
                  {
                    'video_versions': [
                      {'url': 'https://cdn.example.com/first.mp4', 'width': 720, 'height': 1280},
                    ],
                  },
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/second.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                  {
                    'video_versions': [
                      {'url': 'https://cdn.example.com/third.mp4', 'width': 720, 'height': 1280},
                    ],
                  },
                ],
              },
            ],
          },
        },
      };
      final results = InstagramGraphqlResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.instagram.com/p/CARALL02/'),
        shortcode: 'CARALL02',
        payload: payload,
      );
      expect(results.length, 3);
      expect(results[0].directUrl, contains('first.mp4'));
      expect(results[1].directUrl, contains('second.jpg'));
      expect(results[2].directUrl, contains('third.mp4'));
    });

    test('IG-CAR-ALL-003 parseAllMedia assigns indexed filenames', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'carousel_media': [
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/a.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/b.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                ],
              },
            ],
          },
        },
      };
      final results = InstagramGraphqlResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.instagram.com/p/CARALL03/'),
        shortcode: 'CARALL03',
        payload: payload,
      );
      expect(results.length, 2);
      // Each item gets a distinct filename (no collisions)
      expect(results[0].fileName != results[1].fileName, isTrue);
    });

    test('IG-CAR-ALL-004 single video post returns list of one', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'video_versions': [
                  {'url': 'https://cdn.example.com/single.mp4', 'width': 1080, 'height': 1920},
                ],
                'caption': {'text': 'Solo video'},
              },
            ],
          },
        },
      };
      final results = InstagramGraphqlResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.instagram.com/reel/CARALL04/'),
        shortcode: 'CARALL04',
        payload: payload,
      );
      expect(results.length, 1);
      expect(results[0].directUrl, contains('single.mp4'));
      expect(results[0].mimeType, 'video/mp4');
    });

    test('IG-CAR-ALL-005 empty carousel returns empty list', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'carousel_media': <dynamic>[],
              },
            ],
          },
        },
      };
      final results = InstagramGraphqlResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.instagram.com/p/CARALL05/'),
        shortcode: 'CARALL05',
        payload: payload,
      );
      expect(results, isEmpty);
    });

    test('IG-CAR-ALL-006 skips carousel items with no valid media URL', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': [
              {
                'carousel_media': [
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'https://cdn.example.com/good.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                  {
                    'image_versions2': {
                      'candidates': [
                        {'url': 'file:///invalid.jpg', 'width': 1080, 'height': 1080},
                      ],
                    },
                  },
                  {
                    'video_versions': [
                      {'url': 'https://cdn.example.com/good.mp4', 'width': 720, 'height': 1280},
                    ],
                  },
                ],
              },
            ],
          },
        },
      };
      final results = InstagramGraphqlResolver.parseAllMedia(
        pageUrl: Uri.parse('https://www.instagram.com/p/CARALL06/'),
        shortcode: 'CARALL06',
        payload: payload,
      );
      expect(results.length, 2);
      expect(results[0].directUrl, contains('good.jpg'));
      expect(results[1].directUrl, contains('good.mp4'));
    });
  });
}
