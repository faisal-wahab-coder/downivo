import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'telegram_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = TelegramMockAdapter();
    TelegramMockAdapter.reset();
  });

  group('Telegram authentication and restrictions', () {
    test('TG-AUTH-001 private /c/ is RESTRICTED and not downloaded', () {
      final uri = Uri.parse('https://t.me/c/1234567890/12');
      expect(TelegramUri.isRestricted(uri), isTrue);
      expect(TelegramResolver.accessFor(uri), TelegramAccess.restricted);
      expect(TelegramResolver.userFacingError(uri), contains('restricted'));
    });

    test('TG-AUTH-002 invite link is RESTRICTED', () {
      final uri = Uri.parse('https://t.me/+AbCdEfGhIjKl');
      expect(TelegramUri.isRestricted(uri), isTrue);
      expect(TelegramResolver.userFacingError(uri), contains('restricted'));
    });

    test('TG-AUTH-003 private HTML is RESTRICTED', () {
      expect(
        TelegramResolver.classifyHtml(telegramPrivateHtml()),
        TelegramHtmlStatus.restricted,
      );
      expect(
        TelegramResolver.accessFor(
          Uri.parse(telegramMessageUrl),
          html: telegramPrivateHtml(),
        ),
        TelegramAccess.restricted,
      );
    });

    test('TG-AUTH-004 login wall is AUTHENTICATION_REQUIRED', () {
      expect(
        TelegramResolver.classifyHtml(telegramAuthHtml()),
        TelegramHtmlStatus.authenticationRequired,
      );
      expect(
        TelegramResolver.accessFor(
          Uri.parse(telegramMessageUrl),
          html: telegramAuthHtml(),
        ),
        TelegramAccess.authenticationRequired,
      );
      expect(
        TelegramResolver.userFacingError(
          Uri.parse(telegramMessageUrl),
          html: telegramAuthHtml(),
        ),
        contains('authentication'),
      );
    });

    test('TG-AUTH-005 resolver does not fetch private URLs', () async {
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final results = await TelegramResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse('https://t.me/c/1234567890/12'));
      expect(results, isEmpty);
    });

    test('TG-AUTH-006 resolver does not fetch invite URLs', () async {
      TelegramMockAdapter.htmlResponse = telegramPhotoHtml();
      final results = await TelegramResolver(
        dio: mockDio,
      ).discoverAll(Uri.parse('https://t.me/joinchat/AbCdEf'));
      expect(results, isEmpty);
    });

    test('TG-AUTH-007 deleted post is UNAVAILABLE', () {
      expect(
        TelegramResolver.classifyHtml(telegramUnavailableHtml()),
        TelegramHtmlStatus.unavailable,
      );
      expect(
        TelegramResolver.userFacingError(
          Uri.parse(telegramMessageUrl),
          html: telegramUnavailableHtml(),
        ),
        contains('unavailable'),
      );
    });

    test('TG-AUTH-008 public photo is PUBLIC', () {
      expect(
        TelegramResolver.accessFor(
          Uri.parse(telegramMessageUrl),
          html: telegramPhotoHtml(),
        ),
        TelegramAccess.public,
      );
    });

    test(
      'TG-AUTH-009 login HTML on a public message URL is not downloaded',
      () async {
        TelegramMockAdapter.htmlResponse = telegramAuthHtml();
        expect(
          () => TelegramResolver(
            dio: mockDio,
          ).discoverAll(Uri.parse(telegramMessageUrl)),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message.toString().toLowerCase(),
              'message',
              contains('authentication'),
            ),
          ),
        );
      },
    );

    test('TG-AUTH-010 unavailable HTML is not downloaded', () async {
      TelegramMockAdapter.htmlResponse = telegramUnavailableHtml();
      expect(
        () => TelegramResolver(
          dio: mockDio,
        ).discoverAll(Uri.parse(telegramMessageUrl)),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message.toString().toLowerCase(),
            'message',
            contains('unavailable'),
          ),
        ),
      );
    });

    test('TG-AUTH-011 /login is AUTHENTICATION_REQUIRED', () {
      final uri = Uri.parse('https://t.me/login');
      expect(TelegramUri.requiresAuthentication(uri), isTrue);
      expect(
        TelegramResolver.accessFor(uri),
        TelegramAccess.authenticationRequired,
      );
    });
  });
}
