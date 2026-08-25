import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  group('Twitch audio / video', () {
    test('TW-AV-001 clip MP4 is treated as muxed with audio', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      expect(info.hasAudio, isTrue);
      expect(info.selectedQuality!.mimeType, 'video/mp4');
      expect(info.selectedQuality!.url, isNot(contains('.m3u8')));
    });

    test('TW-AV-002 HLS-only clip is not a silent MP4 download', () {
      expect(TwitchResolver.parseClipInfo(twitchHlsOnlyClipPayload()), isNull);
    });

    test('TW-AV-003 VOD audio_only HLS is not a downloadable quality', () {
      final qualities = TwitchResolver.parseHlsMaster(twitchHlsMaster());
      expect(qualities.any((q) => q.quality.toLowerCase().contains('audio')), isFalse);
    });

    test('TW-AV-004 resource MIME is video/mp4', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      final resource = TwitchResolver.resourceFromClip(
        pageUrl: Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
        info: info,
      )!;
      expect(resource.mimeType, 'video/mp4');
    });

    test('TW-AV-005 HLS URL is never used as clip resource', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      final hls = TwitchQuality(
        quality: '1080p',
        url: 'https://usher.ttvnw.net/clip.m3u8',
        mimeType: 'application/vnd.apple.mpegurl',
        height: 1080,
      );
      expect(
        TwitchResolver.resourceFromClip(
          pageUrl: Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
          info: info,
          quality: hls,
        ),
        isNull,
      );
    });
  });
}
