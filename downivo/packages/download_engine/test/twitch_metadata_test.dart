import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  group('Twitch metadata mapping', () {
    test('TW-META-001 public clip fields', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      expect(info.slug, twitchClipSlug);
      expect(info.title, 'Perfect dodge');
      expect(info.channelName, 'LIRIK');
      expect(info.channelLogin, 'lirik');
      expect(info.channelId, '37402112');
      expect(info.creator, 'Viewer1');
      expect(info.category, 'Just Chatting');
      expect(info.durationSeconds, 32.1);
      expect(info.thumbnailUrl, contains('clips-media-assets'));
      expect(info.createdAt, isNotNull);
      expect(info.clipUrl, contains('clips.twitch.tv'));
      expect(info.mimeType, 'video/mp4');
    });

    test('TW-META-002 missing title is not fabricated', () {
      final clip = twitchClip();
      clip.remove('title');
      final info = TwitchResolver.parseClipInfo(twitchClipPayload(clip: clip))!;
      expect(info.title, isNull);
    });

    test('TW-META-003 missing description is not fabricated', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      expect(info.description, isNull);
    });

    test('TW-META-004 description is used when present', () {
      final info = TwitchResolver.parseClipInfo(
        twitchClipPayload(clip: twitchClip(description: 'A public clip')),
      )!;
      expect(info.description, 'A public clip');
    });

    test('TW-META-005 VOD metadata without inventing quality files', () {
      final info = TwitchResolver.parseVideoInfo(twitchVideoPayload())!;
      expect(info.videoId, twitchVodId);
      expect(info.title, 'Ranked grind');
      expect(info.description, 'Day 12');
      expect(info.channelName, 'shroud');
      expect(info.category, 'VALORANT');
      expect(info.durationSeconds, 3600);
      expect(info.thumbnailUrl, contains('jtvnw.net'));
      expect(info.restriction, TwitchRestriction.hlsOnly);
      expect(info.isHighlight, isFalse);
    });

    test('TW-META-006 highlight broadcastType', () {
      final info = TwitchResolver.parseVideoInfo(twitchHighlightPayload())!;
      expect(info.isHighlight, isTrue);
      expect(info.broadcastType, 'HIGHLIGHT');
      expect(info.title, 'Best play');
    });

    test('TW-META-007 live channel metadata', () {
      final info = TwitchResolver.parseChannelInfo(
        twitchUserPayload(user: twitchUser(live: true)),
      )!;
      expect(info.isLive, isTrue);
      expect(info.streamTitle, 'Radiant only');
      expect(info.category, 'VALORANT');
      expect(info.thumbnailUrl, contains('previews-ttv'));
      expect(info.displayName, 'shroud');
      expect(TwitchResolver.isLive(info), isTrue);
    });

    test('TW-META-008 offline channel does not invent a stream title as live', () {
      final info = TwitchResolver.parseChannelInfo(twitchUserPayload())!;
      expect(info.isLive, isFalse);
      expect(info.streamTitle, isNull);
      expect(TwitchResolver.isLive(info), isFalse);
    });

    test('TW-META-009 resource title and platform', () {
      final info = TwitchResolver.parseClipInfo(twitchClipPayload())!;
      final resource = TwitchResolver.resourceFromClip(
        pageUrl: Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
        info: info,
      )!;
      expect(resource.title, 'Perfect dodge');
      expect(resource.platform, 'Twitch');
      expect(resource.thumbnailUrl, contains('clips-media-assets'));
    });

    test('TW-META-010 MIME mapping', () {
      expect(
        TwitchResolver.mimeFromUrl(
          'https://production.assets.clips.twitchcdn.net/file.mp4',
        ),
        'video/mp4',
      );
      expect(
        TwitchResolver.mimeFromUrl(
          'https://usher.ttvnw.net/vod/1.m3u8',
        ),
        'application/vnd.apple.mpegurl',
      );
    });
  });
}
