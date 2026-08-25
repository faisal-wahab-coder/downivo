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

  group('Twitch resolver discovery', () {
    test('TW-RES-001 discovers clip MP4 from GQL', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchClipPayload());
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Twitch');
      expect(result.directUrl, contains('clip_1080.mp4'));
      expect(result.mimeType, 'video/mp4');
      expect(result.title, 'Perfect dodge');
    });

    test('TW-RES-002 home returns empty', () async {
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://www.twitch.tv/'),
      );
      expect(result, isNull);
    });

    test('TW-RES-003 channel returns empty', () async {
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://www.twitch.tv/shroud'),
      );
      expect(result, isNull);
    });

    test('TW-RES-004 VOD returns empty (HLS-only)', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchVideoPayload());
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://www.twitch.tv/videos/$twitchVodId'),
      );
      expect(result, isNull);
    });

    test('TW-RES-005 channel clip path resolves the same clip', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchClipPayload());
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://www.twitch.tv/lirik/clip/$twitchClipSlug'),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, contains('clip_1080.mp4'));
    });

    test('TW-RES-006 missing clip returns null', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchMissingClipPayload());
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-RES-007 directory returns empty', () async {
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://www.twitch.tv/directory'),
      );
      expect(result, isNull);
    });

    test('TW-RES-008 registry discover uses Twitch resolver', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchClipPayload());
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNotNull);
      expect(result!.platform, 'Twitch');
    });

    test('TW-RES-009 registry does not scrape Twitch home HTML', () async {
      final result = await ContentProviderRegistry(dio: mockDio).discover(
        Uri.parse('https://www.twitch.tv/'),
      );
      expect(result, isNull);
    });

    test('TW-RES-010 signed clip URL includes sig and token', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchClipPayload());
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result!.directUrl, contains('sig='));
      expect(result.directUrl, contains('token='));
    });

    test('TW-RES-011 discoverAll returns a single clip item', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchClipPayload());
      final results = await TwitchResolver(dio: mockDio).discoverAll(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(results, hasLength(1));
    });

    test('TW-RES-012 filename includes quality suffix', () {
      expect(
        TwitchResolver.buildFileName(
          id: twitchClipSlug,
          title: 'Perfect dodge',
          quality: '1080p',
          mimeType: 'video/mp4',
        ),
        allOf(contains('1080p'), endsWith('.mp4')),
      );
    });
  });
}
