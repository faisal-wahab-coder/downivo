import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  group('Twitch live / channel', () {
    test('TW-LIVE-001 live user has stream title and category', () {
      final info = TwitchResolver.parseChannelInfo(
        twitchUserPayload(user: twitchUser(live: true)),
      )!;
      expect(info.isLive, isTrue);
      expect(info.streamTitle, 'Radiant only');
      expect(info.category, 'VALORANT');
      expect(info.thumbnailUrl, isNotNull);
      expect(info.viewerCount, 12000);
    });

    test('TW-LIVE-002 offline user is not live', () {
      final info = TwitchResolver.parseChannelInfo(twitchUserPayload())!;
      expect(info.isLive, isFalse);
      expect(info.streamTitle, isNull);
      expect(info.streamId, isNull);
    });

    test('TW-LIVE-003 missing user is null', () {
      expect(
        TwitchResolver.parseChannelInfo(twitchMissingUserPayload()),
        isNull,
      );
    });

    test('TW-LIVE-004 live channel URL is not downloadable', () {
      expect(
        TwitchUri.isDownloadable(Uri.parse('https://www.twitch.tv/shroud')),
        isFalse,
      );
    });

    test('TW-LIVE-005 discover never starts a live recording', () async {
      final result = await TwitchResolver().discover(
        Uri.parse('https://www.twitch.tv/shroud'),
      );
      expect(result, isNull);
    });
  });
}
