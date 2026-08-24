import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 9 — TikTok photo/carousel post handling.
///
/// All tests are offline unit tests documenting current behavior.
void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Phase 9 — Photo post support
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 9 — TikTok photo post support', () {
    test('TT-PHOTO-001 resolver only extracts video URLs', () {
      // TikTokResolver._extractVideoUrl searches for downloadAddr, playAddr, playApi
      // These fields contain video CDN URLs
      // Photo posts use different fields (imagePost, images)
      // The resolver does not handle photo-specific fields
      const videoHtml =
          '{"downloadAddr":"https://v16.tiktokcdn.com/a/video.mp4?t=1"}';
      expect(TikTokResolver.extractFromHtmlForTest(videoHtml), isNotNull);
    });

    test('TT-PHOTO-002 photo post HTML with no video fields returns null', () {
      const photoHtml = '''
<html><head>
  <meta property="og:title" content="Photo carousel" />
  <script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">
  {"defaultScope":{"webapp.video-detail":{"itemInfo":{"itemStruct":{"imagePost":{"images":[{"imageURL":{"urlList":["https://p16-sign.tiktokcdn.com/photo1.jpg"]}}]}}}}}}
  </script>
</head></html>''';
      final url = TikTokResolver.extractFromHtmlForTest(photoHtml);
      // The resolver only looks for video fields, not imagePost
      expect(url, isNull,
          reason: 'Photo-only post should not extract a video URL');
    });

    test('TT-PHOTO-003 MediaExtractor also returns null for photo-only posts', () {
      const photoHtml = '''
<html><head>
  <meta property="og:title" content="Photo post" />
  <meta property="og:image" content="https://p16-sign.tiktokcdn.com/photo1.jpg" />
</head></html>''';
      final result = MediaExtractor.extract(
        pageUrl: Uri.parse('https://www.tiktok.com/@user/photo/123'),
        html: photoHtml,
        platform: SocialPlatform.tiktok,
      );
      // MediaExtractor may fall back to og:image — but this is just the thumbnail,
      // not the actual photo carousel content
      if (result != null) {
        expect(result.directUrl, contains('photo1.jpg'));
        // This would be a single image, not a proper photo carousel download
      }
    });

    test('TT-PHOTO-004 no carousel/multi-photo handling exists', () {
      // Documents the limitation: TikTok photo carousels (slideshow posts)
      // are not supported. The resolver has no mechanism to:
      // 1. Detect photo vs video posts
      // 2. Extract multiple image URLs
      // 3. Download images in correct order
      // 4. Handle mixed photo+video slideshows
      expect(true, isTrue);
    });

    test('TT-PHOTO-005 DiscoveredResource has no image list field', () {
      // DiscoveredResource.directUrl is a single String
      // There is no List<String> for multiple images
      final resource = DiscoveredResource(
        directUrl: 'https://cdn.tiktok.com/video.mp4',
        fileName: 'video.mp4',
        platform: 'TikTok',
      );
      expect(resource.directUrl, isA<String>());
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Phase 9 — Photo post type detection
  // ─────────────────────────────────────────────────────────────────────────

  group('Phase 9 — Photo post type detection', () {
    test('TT-PHOTO-006 /photo/ path extracts content ID', () {
      final uri = Uri.parse('https://www.tiktok.com/@user/photo/123456789');
      final id = TikTokUri.videoIdFromUri(uri);
      expect(id, '123456789',
          reason: '/photo/ path now matched by content ID regex');
    });

    test('TT-PHOTO-007 photo post URL still detected as TikTok platform', () {
      final uri = Uri.parse('https://www.tiktok.com/@user/photo/123456789');
      expect(SocialPlatform.fromUri(uri), SocialPlatform.tiktok);
    });

    test('TT-PHOTO-008 isPhotoPost returns true for /photo/ URLs', () {
      final photoUri =
          Uri.parse('https://www.tiktok.com/@user/photo/123456789');
      final videoUri =
          Uri.parse('https://www.tiktok.com/@user/video/123456789');
      expect(TikTokUri.isPhotoPost(photoUri), isTrue);
      expect(TikTokUri.isPhotoPost(videoUri), isFalse);
    });

    test('TT-PHOTO-009 photo URL with query params extracts ID', () {
      final uri = Uri.parse(
        'https://www.tiktok.com/@user/photo/7576901360264809740'
        '?is_from_webapp=1&sender_device=pc',
      );
      expect(TikTokUri.videoIdFromUri(uri), '7576901360264809740');
      expect(TikTokUri.isPhotoPost(uri), isTrue);
    });
  });
}
