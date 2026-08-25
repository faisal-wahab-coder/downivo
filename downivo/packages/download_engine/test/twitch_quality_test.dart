import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  group('Twitch quality mapping', () {
    test('TW-QUAL-001 clip lists only actual MP4 qualities', () {
      final qualities = TwitchResolver.parseClipQualities(twitchClip());
      expect(
        qualities.map((q) => q.quality).toList(),
        ['1080p', '720p', '480p', '360p', '160p'],
      );
    });

    test('TW-QUAL-002 best quality is highest height', () {
      final best = TwitchResolver.bestQuality(
        TwitchResolver.parseClipQualities(twitchClip()),
      )!;
      expect(best.quality, '1080p');
      expect(best.height, 1080);
    });

    test('TW-QUAL-003 qualityByLabel finds 720p', () {
      final qualities = TwitchResolver.parseClipQualities(twitchClip());
      expect(
        TwitchResolver.qualityByLabel(qualities, '720p')!.url,
        contains('clip_720.mp4'),
      );
    });

    test('TW-QUAL-004 4K is not fabricated', () {
      final qualities = TwitchResolver.parseClipQualities(twitchClip());
      expect(qualities.any((q) => q.quality.contains('2160')), isFalse);
      expect(qualities.any((q) => q.quality.contains('4K')), isFalse);
    });

    test('TW-QUAL-005 HLS renditions are not listed as clip MP4s', () {
      final clip = twitchClip(includeQualities: true, includeHls: true);
      final qualities = TwitchResolver.parseClipQualities(clip);
      expect(qualities.any((q) => q.url.contains('.m3u8')), isFalse);
    });

    test('TW-QUAL-006 HLS master does not invent extra heights', () {
      final qualities = TwitchResolver.parseHlsMaster(
        twitchHlsMaster(includeSource: false, heights: ['720', '480']),
      );
      expect(qualities.map((q) => q.quality).toSet(), {'720p', '480p'});
    });

    test('TW-QUAL-007 unknown label is not used as a download', () {
      expect(TwitchResolver.qualityByLabel(const [], '1080p'), isNull);
    });
  });
}
