import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vimeo_fixtures.dart';

void main() {
  group('Vimeo performance / scale', () {
    test('VM-PERF-001 many qualities do not invent extra items', () {
      final progressive = [
        for (final height in [240, 360, 540, 720, 1080, 1440, 2160])
          vimeoProgressive(
            quality: '${height}p',
            width: (height * 16 / 9).round(),
            height: height,
            url:
                'https://vod-progressive.akamaized.net/file_$height.mp4',
          ),
      ];
      final qualities = VimeoResolver.parseQualities(
        vimeoPlayerConfig(progressive: progressive),
      );
      expect(qualities.length, 7);
      expect(qualities.map((q) => q.url).toSet().length, 7);
      expect(VimeoResolver.bestQuality(qualities)!.height, 2160);
    });

    test('VM-PERF-002 parse is deterministic', () {
      final config = vimeoPlayerConfig();
      final a = VimeoResolver.parseQualities(config);
      final b = VimeoResolver.parseQualities(config);
      expect(a.map((q) => q.url), b.map((q) => q.url));
    });

    test('VM-PERF-003 single video stays one resource', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
      );
      expect(resource, isNotNull);
    });

    test('VM-PERF-004 identity computation is cheap and stable', () {
      final uri = Uri.parse(
        'https://player.vimeo.com/video/76979871?utm_source=x',
      );
      String? last;
      for (var i = 0; i < 50; i++) {
        last = VimeoUri.contentIdentity(VimeoUri.normalize(uri));
      }
      expect(last, 'vimeo:video:76979871');
    });

    test('VM-PERF-005 parse does not load media bytes', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.selectedQuality!.url, startsWith('https://'));
      expect(info.qualities.every((q) => q.url.startsWith('https://')), isTrue);
    });
  });
}
