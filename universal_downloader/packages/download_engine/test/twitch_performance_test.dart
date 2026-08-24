import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  group('Twitch performance / scale', () {
    test('TW-PERF-001 many clip qualities do not invent extra items', () {
      final qualities = [
        for (final height in [160, 360, 480, 720, 1080])
          twitchClipQuality(
            quality: '$height',
            url: 'https://production.assets.clips.twitchcdn.net/c_$height.mp4',
          ),
      ];
      final parsed = TwitchResolver.parseClipQualities(
        twitchClip(qualities: qualities),
      );
      expect(parsed.length, 5);
      expect(parsed.map((q) => q.url).toSet().length, 5);
      expect(TwitchResolver.bestQuality(parsed)!.height, 1080);
    });

    test('TW-PERF-002 parse is deterministic', () {
      final clip = twitchClip();
      final a = TwitchResolver.parseClipQualities(clip);
      final b = TwitchResolver.parseClipQualities(clip);
      expect(a.map((q) => q.url), b.map((q) => q.url));
    });

    test('TW-PERF-003 single clip stays one resource', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      final resource = TwitchResolver.resourceFromClip(
        pageUrl: Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
        info: info,
      );
      expect(resource, isNotNull);
    });

    test('TW-PERF-004 identity computation is cheap and stable', () {
      final uri = Uri.parse(
        'https://www.twitch.tv/lirik/clip/$twitchClipSlug?utm_source=x',
      );
      String? last;
      for (var i = 0; i < 50; i++) {
        last = TwitchUri.contentIdentity(TwitchUri.normalize(uri));
      }
      expect(last, 'twitch:clip:$twitchClipSlug');
    });

    test('TW-PERF-005 parse does not load media bytes', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      expect(info.selectedQuality!.url, startsWith('https://'));
      expect(info.qualities.every((q) => q.url.startsWith('https://')), isTrue);
    });

    test('TW-PERF-006 HLS master parse is URL-only', () {
      final qualities = TwitchResolver.parseHlsMaster(twitchHlsMaster());
      expect(qualities.length, greaterThan(3));
      expect(qualities.every((q) => q.url.startsWith('https://')), isTrue);
    });
  });
}
