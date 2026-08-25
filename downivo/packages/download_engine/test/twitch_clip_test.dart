import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'twitch_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = TwitchMockAdapter();
    TwitchMockAdapter.reset();
  });

  group('Twitch Clips', () {
    test('TW-CLIP-001 clip slug extracted', () {
      expect(
        TwitchResolver.clipIdFromUri(
          Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
        ),
        twitchClipSlug,
      );
    });

    test('TW-CLIP-002 highest MP4 is selected', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchClipPayload());
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result!.directUrl, contains('clip_1080.mp4'));
      expect(result.directUrl, isNot(contains('.m3u8')));
    });

    test('TW-CLIP-003 HLS clip renditions are skipped', () {
      final info = TwitchResolver.parseClipInfo(twitchHlsOnlyClipPayload());
      expect(info, isNull);
      expect(
        TwitchResolver.restrictionFromClipPayload(twitchHlsOnlyClipPayload()),
        TwitchRestriction.hlsOnly,
      );
    });

    test('TW-CLIP-004 embed query clip= is CLIP', () {
      final uri = Uri.parse(
        'https://clips.twitch.tv/embed?clip=$twitchClipSlug',
      );
      expect(TwitchUri.classifyUrl(uri), TwitchContentType.clip);
      expect(TwitchUri.clipIdFromUri(uri), twitchClipSlug);
    });

    test('TW-CLIP-005 deleted clip is unavailable', () {
      expect(
        TwitchResolver.restrictionFromClipPayload(twitchMissingClipPayload()),
        TwitchRestriction.unavailable,
      );
    });

    test('TW-CLIP-006 restricted token is not downloaded', () {
      expect(
        TwitchResolver.restrictionFromClipPayload(
          twitchRestrictedClipPayload(),
        ),
        TwitchRestriction.restricted,
      );
      expect(
        TwitchResolver.parseClipInfo(twitchRestrictedClipPayload()),
        isNull,
      );
    });
  });
}
