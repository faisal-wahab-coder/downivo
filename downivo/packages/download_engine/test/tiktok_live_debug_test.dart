import 'dart:io';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:download_engine/src/content_providers/social_http_headers.dart';
import 'package:download_engine/src/content_providers/social_url_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

/// Debug test for the reported failing TikTok URL.
/// Run with: TIKTOK_LIVE_TEST=1 flutter test test/tiktok_live_debug_test.dart
void main() {
  final enabled = Platform.environment['TIKTOK_LIVE_TEST'] == '1';

  test(
    'Debug: resolve https://www.tiktok.com/@sweetieticktock2/video/7667238057346632974',
    () async {
      const targetUrl =
          'https://www.tiktok.com/@sweetieticktock2/video/7667238057346632974';
      final uri = Uri.parse(targetUrl);

      // Step 1: Verify URL parsing
      print('=== STEP 1: URL PARSING ===');
      final platform = SocialPlatform.fromUri(uri);
      print('Platform: $platform');
      expect(platform, SocialPlatform.tiktok);

      final videoId = TikTokUri.videoIdFromUri(uri);
      print('Video ID: $videoId');
      expect(videoId, '7667238057346632974');

      final canHandle = ContentProviderRegistry.canHandle(uri);
      print('canHandle: $canHandle');
      expect(canHandle, isTrue);

      // Step 2: Try redirect resolution
      print('\n=== STEP 2: REDIRECT RESOLUTION ===');
      final dio = Dio();
      final resolver = SocialUrlResolver(dio: dio);
      final resolved = await resolver.resolveRedirects(uri);
      print('Original: $uri');
      print('Resolved: $resolved');

      // Step 3: Build fetch targets
      print('\n=== STEP 3: FETCH TARGETS ===');
      final targets = SocialUrlUtils.fetchTargets(uri, SocialPlatform.tiktok);
      for (final t in targets) {
        print('Target: $t');
      }

      // Step 4: Fetch each target and inspect HTML
      print('\n=== STEP 4: FETCH HTML FROM TARGETS ===');
      final headers = SocialHttpHeaders.forPageFetch(uri, SocialPlatform.tiktok);
      print('Headers: $headers');

      for (final target in targets.toSet()) {
        print('\n--- Fetching: $target ---');
        try {
          final response = await dio.get<String>(
            target.toString(),
            options: Options(
              responseType: ResponseType.plain,
              followRedirects: true,
              validateStatus: (s) => s != null && s >= 200 && s < 400,
              headers: headers,
            ),
          );
          final html = response.data ?? '';
          print('Status: ${response.statusCode}');
          print('HTML length: ${html.length}');
          print('Contains downloadAddr: ${html.contains('downloadAddr')}');
          print('Contains playAddr: ${html.contains('playAddr')}');
          print('Contains playApi: ${html.contains('playApi')}');
          print(
              'Contains __UNIVERSAL_DATA_FOR_REHYDRATION__: ${html.contains('__UNIVERSAL_DATA_FOR_REHYDRATION__')}');
          print('Contains SIGI_STATE: ${html.contains('SIGI_STATE')}');
          print('Contains tiktokcdn: ${html.contains('tiktokcdn')}');
          print('Contains tiktokv: ${html.contains('tiktokv')}');
          print('Contains /video/tos/: ${html.contains('/video/tos/')}');
          print('Contains mime_type=video: ${html.contains('mime_type=video')}');

          // Try extraction
          final extracted = TikTokResolver.extractFromHtmlForTest(html);
          print('Extracted URL: ${extracted ?? 'NULL'}');

          if (extracted != null) {
            print('\n*** SUCCESS: Found CDN URL ***');
            print('CDN URL: $extracted');
            return;
          }

          // Dump first 500 chars of any script tags with video data
          for (final id in ['__UNIVERSAL_DATA_FOR_REHYDRATION__', 'SIGI_STATE']) {
            final scriptPattern = RegExp(
              '<script[^>]+id=[\'"]$id[\'"][^>]*>(\\{.*?\\})</script>',
              dotAll: true,
              caseSensitive: false,
            );
            final m = scriptPattern.firstMatch(html);
            if (m != null) {
              final content = m.group(1) ?? '';
              print('Script tag [$id] content (first 500 chars):');
              print(content.substring(0, content.length.clamp(0, 500)));
            }
          }
        } on DioException catch (e) {
          print('DioException: ${e.type} ${e.response?.statusCode}');
          print('Message: ${e.message}');
        }
      }

      // Step 5: Try full ContentProviderRegistry pipeline
      print('\n=== STEP 5: FULL DISCOVERY PIPELINE ===');
      final registry = ContentProviderRegistry(dio: dio);
      final result = await registry
          .discover(uri)
          .timeout(const Duration(seconds: 45));
      print('Discovery result: ${result == null ? 'NULL' : 'FOUND'}');
      if (result != null) {
        print('directUrl: ${result.directUrl}');
        print('fileName: ${result.fileName}');
        print('platform: ${result.platform}');
        print('title: ${result.title}');
        print('mimeType: ${result.mimeType}');
      } else {
        print('\n*** DISCOVERY FAILED ***');
        print(
            'The resolver could not extract a video CDN URL from any target page.');
        print('This is likely due to TikTok anti-scraping measures.');
      }
    },
    skip: enabled ? false : 'Set TIKTOK_LIVE_TEST=1 to run',
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
