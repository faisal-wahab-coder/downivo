import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vimeo_fixtures.dart';

void main() {
  group('Vimeo metadata mapping', () {
    test('VM-META-001 public video fields', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.videoId, '76979871');
      expect(info.title, 'The New Vimeo Player');
      expect(info.author, 'Vimeo Staff');
      expect(info.authorId, '928647');
      expect(info.durationSeconds, 62);
      expect(info.width, 1920);
      expect(info.height, 1080);
      expect(info.videoUrl, contains('vimeo.com/76979871'));
      expect(info.mimeType, 'video/mp4');
      expect(info.createdAt, isNotNull);
    });

    test('VM-META-002 missing title is not fabricated', () {
      final config = vimeoPlayerConfig();
      (config['video'] as Map).remove('title');
      final info = VimeoResolver.parseVideoInfo(config)!;
      expect(info.title, isNull);
    });

    test('VM-META-003 missing description is not fabricated', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.description, isNull);
    });

    test('VM-META-004 description is used when present', () {
      final info = VimeoResolver.parseVideoInfo(
        vimeoPlayerConfig(description: 'A public demo video'),
      )!;
      expect(info.description, 'A public demo video');
    });

    test('VM-META-005 thumbnail prefers largest thumbs size', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.thumbnailUrl, contains('_1280.jpg'));
    });

    test('VM-META-006 aspect ratio matches selected dimensions', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.aspectRatio, closeTo(16 / 9, 0.01));
    });

    test('VM-META-007 frame rate comes from selected quality', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.frameRate, 30);
    });

    test('VM-META-008 resource title and platform', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
      )!;
      expect(resource.title, 'The New Vimeo Player');
      expect(resource.platform, 'Vimeo');
      expect(resource.pageUrl, 'https://vimeo.com/76979871');
      expect(resource.thumbnailUrl, contains('vimeocdn.com'));
    });

    test('VM-META-009 MIME mapping', () {
      expect(
        VimeoResolver.mimeFromUrl(
          'https://vod-progressive.akamaized.net/file.mp4',
        ),
        'video/mp4',
      );
      expect(
        VimeoResolver.mimeFromUrl(
          'https://skyfire.vimeocdn.com/master.m3u8',
        ),
        'application/vnd.apple.mpegurl',
      );
      expect(VimeoResolver.normalizeMime('video/x-m4v'), 'video/mp4');
    });

    test('VM-META-010 author id is stringified from int', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.authorId, '928647');
    });
  });
}
