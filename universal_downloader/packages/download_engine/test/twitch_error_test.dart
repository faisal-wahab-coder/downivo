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

  group('Twitch HTTP errors', () {
    test('TW-ERR-001 HTTP 403 returns null', () async {
      TwitchMockAdapter.statusCode = 403;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-002 HTTP 404 returns null', () async {
      TwitchMockAdapter.statusCode = 404;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-003 HTTP 429 returns null', () async {
      TwitchMockAdapter.statusCode = 429;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-004 HTTP 500 returns null', () async {
      TwitchMockAdapter.statusCode = 500;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-005 HTTP 502 returns null', () async {
      TwitchMockAdapter.statusCode = 502;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-006 HTTP 503 returns null', () async {
      TwitchMockAdapter.statusCode = 503;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-007 network error returns null', () async {
      TwitchMockAdapter.throwError = true;
      TwitchMockAdapter.exceptionType = DioExceptionType.connectionError;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-008 timeout returns null', () async {
      TwitchMockAdapter.throwError = true;
      TwitchMockAdapter.exceptionType = DioExceptionType.connectionTimeout;
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });
  });

  group('Twitch availability errors', () {
    test('TW-ERR-010 deleted clip is not downloaded', () async {
      TwitchMockAdapter.gqlResponse = jsonEncode(twitchMissingClipPayload());
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });

    test('TW-ERR-011 restricted clip is not downloaded', () {
      expect(
        TwitchResolver.restrictionFromClipPayload(twitchRestrictedClipPayload()),
        TwitchRestriction.restricted,
      );
    });

    test('TW-ERR-012 INVALID VOD path is empty', () async {
      final results = await TwitchResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.twitch.tv/videos/INVALID'),
      );
      expect(results, isEmpty);
    });

    test('TW-ERR-013 home discoverAll is empty', () async {
      final results = await TwitchResolver(dio: mockDio).discoverAll(
        Uri.parse('https://www.twitch.tv/'),
      );
      expect(results, isEmpty);
    });

    test('TW-ERR-014 empty GQL returns null', () async {
      TwitchMockAdapter.gqlResponse = '{}';
      final result = await TwitchResolver(dio: mockDio).discover(
        Uri.parse('https://clips.twitch.tv/$twitchClipSlug'),
      );
      expect(result, isNull);
    });
  });

  group('Twitch error formatter', () {
    test('TW-ERR-020 403 message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('403'));
    });

    test('TW-ERR-021 404 message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 404,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('404'));
    });

    test('TW-ERR-022 429 message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        response: Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 429,
        ),
        type: DioExceptionType.badResponse,
      );
      expect(DownloadErrorFormatter.fromDio(error), contains('429'));
    });

    test('TW-ERR-023 timeout message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('timed out'),
      );
    });

    test('TW-ERR-024 network message', () {
      final error = DioException(
        requestOptions: RequestOptions(path: '/'),
        type: DioExceptionType.connectionError,
      );
      expect(
        DownloadErrorFormatter.fromDio(error).toLowerCase(),
        contains('network'),
      );
    });

    test('TW-ERR-025 no stack traces in formatter', () {
      final text = DownloadErrorFormatter.fromObject(StateError('boom'));
      expect(text, isNot(contains('StateError')));
      expect(text.contains('\n'), isFalse);
    });
  });
}
