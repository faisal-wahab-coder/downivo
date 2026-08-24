import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  group('Twitch VOD handling', () {
    test('TW-VOD-001 VOD URL is classified and id extracted', () {
      final uri = Uri.parse('https://www.twitch.tv/videos/$twitchVodId');
      expect(TwitchUri.classifyUrl(uri), TwitchContentType.vod);
      expect(TwitchUri.videoIdFromUri(uri), twitchVodId);
    });

    test('TW-VOD-002 parseVideoInfo maps streamer and duration', () {
      final info = TwitchResolver.parseVideoInfo(twitchVideoPayload())!;
      expect(info.channelLogin, twitchChannel);
      expect(info.durationSeconds, 3600);
      expect(info.category, 'VALORANT');
    });

    test('TW-VOD-003 missing VOD is unavailable', () {
      expect(
        TwitchResolver.restrictionFromVideoPayload(twitchMissingVideoPayload()),
        TwitchRestriction.unavailable,
      );
      expect(
        TwitchResolver.parseVideoInfo(twitchMissingVideoPayload()),
        isNull,
      );
    });

    test('TW-VOD-004 public VOD is HLS-only, not a file download', () {
      final info = TwitchResolver.parseVideoInfo(twitchVideoPayload())!;
      expect(info.restriction, TwitchRestriction.hlsOnly);
    });

    test('TW-VOD-005 HLS master qualities are detected, not downloaded', () {
      final qualities = TwitchResolver.parseHlsMaster(twitchHlsMaster());
      expect(qualities.map((q) => q.quality), containsAll(['1080p', '720p', '480p', '360p', '160p', 'Source']));
      expect(qualities.every((q) => TwitchResolver.isHlsOrDashUrl(q.url)), isTrue);
      expect(qualities.any((q) => q.quality == 'audio_only'), isFalse);
    });

    test('TW-VOD-006 discover does not return an m3u8 as a file', () async {
      final result = await TwitchResolver().discover(
        Uri.parse('https://www.twitch.tv/videos/$twitchVodId'),
      );
      expect(result, isNull);
    });
  });
}
