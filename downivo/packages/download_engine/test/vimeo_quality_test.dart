import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'vimeo_fixtures.dart';

void main() {
  group('Vimeo quality selection', () {
    test('VM-QUAL-001 lists only progressive qualities that exist', () {
      final qualities = VimeoResolver.parseQualities(vimeoPlayerConfig());
      expect(qualities.map((q) => q.quality), ['1080p', '720p', '360p']);
      expect(qualities.every((q) => q.url.endsWith('.mp4')), isTrue);
    });

    test('VM-QUAL-002 does not invent 4K when source max is 1080p', () {
      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      expect(info.availableQualityLabels, isNot(contains('2160p')));
      expect(info.availableQualityLabels, isNot(contains('4K')));
      expect(info.height, 1080);
    });

    test('VM-QUAL-003 best quality is highest height', () {
      final best = VimeoResolver.bestQuality(
        VimeoResolver.parseQualities(vimeoPlayerConfig()),
      )!;
      expect(best.quality, '1080p');
      expect(best.height, 1080);
    });

    test('VM-QUAL-004 720p can be selected when present', () {
      final qualities = VimeoResolver.parseQualities(vimeoPlayerConfig());
      final selected = VimeoResolver.qualityByLabel(qualities, '720p')!;
      expect(selected.height, 720);
      expect(selected.url, contains('720.mp4'));

      final info = VimeoResolver.parseVideoInfo(vimeoPlayerConfig())!;
      final resource = VimeoResolver.resourceFromInfo(
        pageUrl: Uri.parse('https://vimeo.com/76979871'),
        info: info,
        quality: selected,
      )!;
      expect(resource.directUrl, contains('720.mp4'));
      expect(resource.fileName, contains('720p'));
    });

    test('VM-QUAL-005 HLS renditions are not listed as downloadable qualities', () {
      final qualities = VimeoResolver.parseQualities(vimeoPlayerConfig());
      expect(qualities.any((q) => q.url.contains('.m3u8')), isFalse);
    });

    test('VM-QUAL-006 360p-only source does not claim 1080p', () {
      final config = vimeoPlayerConfig(
        width: 640,
        height: 360,
        progressive: [
          vimeoProgressive(
            quality: '360p',
            width: 640,
            height: 360,
            url: 'https://vod-progressive.akamaized.net/file_360.mp4',
          ),
        ],
      );
      final info = VimeoResolver.parseVideoInfo(config)!;
      expect(info.availableQualityLabels, ['360p']);
      expect(info.height, 360);
      expect(info.selectedQuality!.url, contains('360.mp4'));
    });

    test('VM-QUAL-007 unknown quality label is not selected', () {
      final qualities = VimeoResolver.parseQualities(vimeoPlayerConfig());
      expect(VimeoResolver.qualityByLabel(qualities, '2160p'), isNull);
    });
  });
}
