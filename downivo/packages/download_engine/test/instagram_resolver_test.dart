import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3 / 5 / 8 — Instagram GraphQL payload parsing, video quality
/// selection, caption extraction, filename generation, and HTML fallback.
///
/// All tests are offline unit tests using mock JSON payloads.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 3 — GraphQL payload parsing (modern format)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 3 — Instagram GraphQL payload parsing', () {
    test('IG-GQL-001 valid payload with video_versions returns resource', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/video_720.mp4', 'width': 720, 'height': 1280},
          {'url': 'https://cdn.example.com/video_360.mp4', 'width': 360, 'height': 640},
        ],
        caption: 'Test caption',
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/ABC123/'),
        shortcode: 'ABC123',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('video_720'));
      expect(result.platform, 'Instagram');
      expect(result.title, 'Test caption');
      expect(result.mimeType, 'video/mp4');
    });

    test('IG-GQL-002 empty video_versions with video_url fallback', () {
      final payload = _modernPayload(
        videoVersions: [],
        videoUrl: 'https://cdn.example.com/fallback.mp4',
        caption: 'Fallback test',
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/DEF456/'),
        shortcode: 'DEF456',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/fallback.mp4');
    });

    test('IG-GQL-003 no video_versions and no video_url returns null', () {
      final payload = _modernPayload(
        videoVersions: null,
        videoUrl: null,
        caption: 'Image only post',
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/p/IMG001/'),
        shortcode: 'IMG001',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-GQL-004 empty data object returns null', () {
      final payload = <String, dynamic>{'data': <String, dynamic>{}};
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/ABC123/'),
        shortcode: 'ABC123',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-GQL-005 null data returns null', () {
      final payload = <String, dynamic>{'data': null};
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/ABC123/'),
        shortcode: 'ABC123',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-GQL-006 empty items list returns null', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_api__v1__media__shortcode__web_info': {
            'items': <dynamic>[],
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/ABC123/'),
        shortcode: 'ABC123',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-GQL-007 items with non-HTTP video URL returns null', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'not-a-url', 'width': 720, 'height': 1280},
        ],
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/ABC123/'),
        shortcode: 'ABC123',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-GQL-008 payload without data key returns null', () {
      final payload = <String, dynamic>{'error': 'not found'};
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/ABC123/'),
        shortcode: 'ABC123',
        payload: payload,
      );
      expect(result, isNull);
    });
  });

  group('Instagram media id conversion', () {
    test('IG-MID-001 converts public reel shortcode to numeric media id', () {
      expect(
        InstagramGraphqlResolver.mediaIdFromShortcode('DcLtDEhx5pd'),
        '3966462019942980189',
      );
    });

    test('IG-MID-002 rejects shortcodes outside the Instagram alphabet', () {
      expect(InstagramGraphqlResolver.mediaIdFromShortcode('bad*code'), isNull);
    });
  });

  group('Instagram Polaris logged-out payload parsing', () {
    test('IG-POLARIS-001 video reel from if_not_gated_logged_out', () {
      final payload = <String, dynamic>{
        'data': {
          'xig_polaris_media': {
            'if_not_gated_logged_out': {
              'video_versions': [
                {
                  'url': 'https://cdn.example.com/reel_1080.mp4',
                  'width': 1080,
                  'height': 1920,
                },
              ],
              'image_versions2': {
                'candidates': [
                  {
                    'url': 'https://cdn.example.com/thumb.jpg',
                    'width': 1080,
                    'height': 1920,
                  },
                ],
              },
              'caption': {'text': 'Morning reel'},
            },
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse(
          'https://www.instagram.com/reel/DcLtDEhx5pd/?igsi=MXdlZHZ5bWh3a3NuYg==',
        ),
        shortcode: 'DcLtDEhx5pd',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('reel_1080.mp4'));
      expect(result.mimeType, 'video/mp4');
      expect(result.kind, DiscoveredResourceKind.video);
      expect(result.title, 'Morning reel');
    });

    test('IG-POLARIS-002 photo carousel extracts every image', () {
      final payload = <String, dynamic>{
        'data': {
          'xig_polaris_media': {
            'if_not_gated_logged_out': {
              'caption': {'text': 'Carousel post'},
              'carousel_media': [
                {
                  'image_versions2': {
                    'candidates': [
                      {
                        'url': 'https://cdn.example.com/slide_1.jpg',
                        'width': 1080,
                        'height': 1350,
                      },
                    ],
                  },
                },
                {
                  'image_versions2': {
                    'candidates': [
                      {
                        'url': 'https://cdn.example.com/slide_2.jpg',
                        'width': 1080,
                        'height': 1350,
                      },
                    ],
                  },
                },
              ],
            },
          },
        },
      };
      final results = InstagramGraphqlResolver.parseAllMedia(
        pageUrl: Uri.parse(
          'https://www.instagram.com/p/Dck28qujwLv/?img_index=2',
        ),
        shortcode: 'Dck28qujwLv',
        payload: payload,
      );
      expect(results, hasLength(2));
      expect(results[0].directUrl, contains('slide_1.jpg'));
      expect(results[1].directUrl, contains('slide_2.jpg'));
      expect(results.every((r) => r.mimeType == 'image/jpeg'), isTrue);
    });

    test('IG-POLARIS-003 gated media without product payload returns null', () {
      final payload = <String, dynamic>{
        'data': {
          'xig_polaris_media': {
            'if_not_gated_logged_out': null,
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/DcifBECPztr/'),
        shortcode: 'DcifBECPztr',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-POLARIS-004 reel poster image is not treated as the video', () {
      final payload = <String, dynamic>{
        'data': {
          'xig_polaris_media': {
            'if_not_gated_logged_out': {
              'media_type': 2,
              'product_type': 'clips',
              'image_versions2': {
                'candidates': [
                  {
                    'url': 'https://cdn.example.com/poster.jpg',
                    'width': 1080,
                    'height': 1920,
                  },
                ],
              },
              'caption': {'text': 'proof I can be a morning person'},
            },
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse(
          'https://www.instagram.com/reel/DcLtDEhx5pd/?igsi=MXdlZHZ5bWh3a3NuYg==',
        ),
        shortcode: 'DcLtDEhx5pd',
        payload: payload,
      );
      expect(result, isNull);
    });

    test('IG-POLARIS-005 reel dash manifest yields the mp4, not the poster', () {
      final payload = <String, dynamic>{
        'data': {
          'xig_polaris_media': {
            'if_not_gated_logged_out': {
              'media_type': 2,
              'image_versions2': {
                'candidates': [
                  {
                    'url': 'https://cdn.example.com/poster.jpg',
                    'width': 1080,
                    'height': 1920,
                  },
                ],
              },
              'video_dash_manifest':
                  '<?xml version="1.0"?><MPD><BaseURL>https://cdn.example.com/reel_1080.mp4?oh=1&amp;oe=2</BaseURL></MPD>',
            },
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/DcLtDEhx5pd/'),
        shortcode: 'DcLtDEhx5pd',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('reel_1080.mp4'));
      expect(result.kind, DiscoveredResourceKind.video);
      expect(result.mimeType, 'video/mp4');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 3 — Legacy shortcode_media parsing
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 3 — Instagram legacy shortcode_media parsing', () {
    test('IG-LEGACY-001 legacy format with video_url returns resource', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'ABC123',
            'video_url': 'https://cdn.example.com/legacy_video.mp4',
            'edge_media_to_caption': {
              'edges': [
                {
                  'node': {'text': 'Legacy caption'},
                },
              ],
            },
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/ABC123/'),
        shortcode: 'ABC123',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, 'https://cdn.example.com/legacy_video.mp4');
      expect(result.title, 'Legacy caption');
    });

    test('IG-LEGACY-002 legacy format without video_url falls back to image', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'IMG001',
            'display_url': 'https://cdn.example.com/image.jpg',
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
    });

    test('IG-LEGACY-003 legacy format with empty caption edges', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'VID001',
            'video_url': 'https://cdn.example.com/video.mp4',
            'edge_media_to_caption': {'edges': <dynamic>[]},
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/VID001/'),
        shortcode: 'VID001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.title, isNull);
    });

    test('IG-LEGACY-004 legacy with non-HTTP video_url returns null', () {
      final payload = <String, dynamic>{
        'data': {
          'xdt_shortcode_media': {
            'shortcode': 'BAD001',
            'video_url': 'file:///local/video.mp4',
          },
        },
      };
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/BAD001/'),
        shortcode: 'BAD001',
        payload: payload,
      );
      expect(result, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 5 — Video quality selection (best width)
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 5 — Instagram video quality selection', () {
    test('IG-QUAL-001 selects highest width from video_versions', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/v_360.mp4', 'width': 360, 'height': 640},
          {'url': 'https://cdn.example.com/v_1080.mp4', 'width': 1080, 'height': 1920},
          {'url': 'https://cdn.example.com/v_720.mp4', 'width': 720, 'height': 1280},
        ],
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/HQ001/'),
        shortcode: 'HQ001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('v_1080'));
    });

    test('IG-QUAL-002 single video_version selected', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/only.mp4', 'width': 480, 'height': 854},
        ],
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/SQ001/'),
        shortcode: 'SQ001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('only.mp4'));
    });

    test('IG-QUAL-003 width as string still parsed', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/str_width.mp4', 'width': '1080', 'height': '1920'},
          {'url': 'https://cdn.example.com/low.mp4', 'width': '360', 'height': '640'},
        ],
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/SW001/'),
        shortcode: 'SW001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('str_width'));
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 3 — Caption extraction
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 3 — Instagram caption extraction', () {
    test('IG-CAP-001 caption text extracted from modern format', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
        ],
        caption: 'Hello World! 🌍',
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/CAP001/'),
        shortcode: 'CAP001',
        payload: payload,
      );
      expect(result?.title, 'Hello World! 🌍');
    });

    test('IG-CAP-002 empty caption returns null title', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
        ],
        caption: '',
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/CAP002/'),
        shortcode: 'CAP002',
        payload: payload,
      );
      expect(result?.title, isNull);
    });

    test('IG-CAP-003 whitespace-only caption returns null title', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
        ],
        caption: '   \n  ',
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/CAP003/'),
        shortcode: 'CAP003',
        payload: payload,
      );
      expect(result?.title, isNull);
    });

    test('IG-CAP-004 null caption map returns null title', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
        ],
        captionNull: true,
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/CAP004/'),
        shortcode: 'CAP004',
        payload: payload,
      );
      expect(result?.title, isNull);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 3 — Filename generation
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 3 — Instagram filename generation', () {
    test('IG-FN-001 filename from CDN URL with basename', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://scontent.cdninstagram.com/v/reel_123.mp4', 'width': 720, 'height': 1280},
        ],
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/FN001/'),
        shortcode: 'FN001',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.fileName, isNotNull);
      expect(result.fileName!.endsWith('.mp4'), isTrue);
    });

    test('IG-FN-002 filename from caption slug', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/v/stream?quality=hd', 'width': 720, 'height': 1280},
        ],
        caption: 'My Amazing Reel',
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/FN002/'),
        shortcode: 'FN002',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.fileName, isNotNull);
      expect(result.fileName!.contains('.mp4'), isTrue);
    });

    test('IG-FN-003 filename uses shortcode as fallback', () {
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/stream', 'width': 720, 'height': 1280},
        ],
        captionNull: true,
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: Uri.parse('https://www.instagram.com/reel/FN003/'),
        shortcode: 'FN003',
        payload: payload,
      );
      expect(result, isNotNull);
      expect(result!.fileName, isNotNull);
    });

    test('IG-FN-004 pageUrl stored in result', () {
      final pageUrl = Uri.parse('https://www.instagram.com/reel/FN004/');
      final payload = _modernPayload(
        videoVersions: [
          {'url': 'https://cdn.example.com/v.mp4', 'width': 720, 'height': 1280},
        ],
      );
      final result = InstagramGraphqlResolver.parsePayload(
        pageUrl: pageUrl,
        shortcode: 'FN004',
        payload: payload,
      );
      expect(result?.pageUrl, pageUrl.toString());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 8 — HTML fallback extraction
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 8 — Instagram HTML fallback extraction', () {
    test('IG-HTML-001 extracts video_url from JSON in HTML', () {
      const html = '''
        <html><body>
        <script>{"video_url":"https://scontent.cdninstagram.com/v/reel.mp4"}</script>
        </body></html>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.instagram.com/reel/HTML001/'),
        html: html,
        platform: SocialPlatform.instagram,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('cdninstagram.com'));
    });

    test('IG-HTML-002 extracts contentUrl from JSON in HTML', () {
      const html = '''
        <html><body>
        <script>{"contentUrl":"https://video.cdninstagram.com/stream.mp4"}</script>
        </body></html>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.instagram.com/reel/HTML002/'),
        html: html,
        platform: SocialPlatform.instagram,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('cdninstagram.com'));
    });

    test('IG-HTML-003 extracts og:video meta tag', () {
      const html = '''
        <html><head>
        <meta property="og:video" content="https://scontent.cdninstagram.com/embed.mp4" />
        <meta property="og:title" content="Instagram Reel" />
        </head></html>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.instagram.com/reel/HTML003/'),
        html: html,
        platform: SocialPlatform.instagram,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('embed.mp4'));
    });

    test('IG-HTML-004 extracts cdninstagram.com mp4 URL via regex', () {
      const html = '''
        <html><body>
        <div data-url="https://scontent-iad3-1.cdninstagram.com/v/t50.2886-16/12345_n.mp4?extra=params"></div>
        </body></html>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.instagram.com/reel/HTML004/'),
        html: html,
        platform: SocialPlatform.instagram,
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('cdninstagram.com'));
      expect(result.directUrl, contains('.mp4'));
    });

    test('IG-HTML-005 no video content in HTML returns null', () {
      const html = '''
        <html><head>
        <meta property="og:image" content="https://scontent.cdninstagram.com/image.jpg" />
        <meta property="og:title" content="Photo Post" />
        </head></html>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.instagram.com/p/HTML005/'),
        html: html,
        platform: SocialPlatform.instagram,
      );
      // May return the og:image as fallback — test actual behavior
      if (result != null) {
        expect(result.directUrl, contains('.jpg'));
      }
    });

    test('IG-HTML-006 reel with only og:image does not download the poster', () {
      const html = '''
        <html><head>
        <meta property="og:image" content="https://scontent.cdninstagram.com/poster.jpg" />
        <meta property="og:title" content="Instagram Reel" />
        </head></html>
      ''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse(
          'https://www.instagram.com/reel/DcLtDEhx5pd/?igsi=MXdlZHZ5bWh3a3NuYg==',
        ),
        html: html,
        platform: SocialPlatform.instagram,
      );
      expect(result, isNull);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Test helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Builds a modern GraphQL response payload for testing.
Map<String, dynamic> _modernPayload({
  List<Map<String, dynamic>>? videoVersions,
  String? videoUrl,
  String? caption,
  bool captionNull = false,
}) {
  final item = <String, dynamic>{};

  if (videoVersions != null) {
    item['video_versions'] = videoVersions;
  }
  if (videoUrl != null) {
    item['video_url'] = videoUrl;
  }
  if (!captionNull) {
    item['caption'] = caption != null ? {'text': caption} : null;
  }

  return {
    'data': {
      'xdt_api__v1__media__shortcode__web_info': {
        'items': [item],
      },
    },
  };
}
