import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'whatsapp_fixtures.dart';

void main() {
  late Dio mockDio;

  setUp(() {
    mockDio = Dio();
    mockDio.httpClientAdapter = WhatsAppMockAdapter();
    WhatsAppMockAdapter.reset();
  });

  group('WhatsApp resolver', () {
    test('WA-RES-001 channel HTML yields a public image', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelHtml(),
        pageUrl: Uri.parse(whatsappChannelUrl),
        contentId: 'whatsapp:channel:$whatsappChannelId',
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, whatsappImageUrl);
      expect(results.single.platform, 'WhatsApp');
      expect(results.single.mimeType, 'image/jpeg');
    });

    test('WA-RES-002 discover uses public channel HTML', () async {
      WhatsAppMockAdapter.htmlResponse = whatsappChannelHtml();
      final result = await WhatsAppResolver(dio: mockDio).discover(
        Uri.parse(whatsappChannelUrl),
      );
      expect(result, isNotNull);
      expect(result!.directUrl, whatsappImageUrl);
    });

    test('WA-RES-003 chat link is not discovered', () async {
      WhatsAppMockAdapter.htmlResponse = whatsappChannelHtml();
      final results = await WhatsAppResolver(dio: mockDio).discoverAll(
        Uri.parse(whatsappChatUrl),
      );
      expect(results, isEmpty);
    });

    test('WA-RES-004 invite URL is not fetched', () async {
      WhatsAppMockAdapter.htmlResponse = whatsappChannelHtml();
      final results = await WhatsAppResolver(dio: mockDio).discoverAll(
        Uri.parse(whatsappInviteUrl),
      );
      expect(results, isEmpty);
    });

    test('WA-RES-005 registry skips non-downloadable WhatsApp pages', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      WhatsAppMockAdapter.htmlResponse = whatsappChannelHtml();
      expect(await registry.discover(Uri.parse(whatsappHomeUrl)), isNull);
      expect(await registry.discover(Uri.parse(whatsappChatUrl)), isNull);
      expect(await registry.discover(Uri.parse(whatsappInviteUrl)), isNull);
      expect(await registry.discover(Uri.parse(whatsappWebUrl)), isNull);
    });

    test('WA-RES-006 registry discovers a public channel image', () async {
      final registry = ContentProviderRegistry(dio: mockDio);
      WhatsAppMockAdapter.htmlResponse = whatsappChannelHtml();
      final result = await registry.discover(Uri.parse(whatsappChannelUrl));
      expect(result, isNotNull);
      expect(result!.platform, 'WhatsApp');
    });

    test('WA-RES-007 filename is sanitized from title', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelHtml(title: 'Hello World'),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results.single.fileName, isNot(contains('/')));
      expect(results.single.fileName.toLowerCase(), contains('.jpg'));
    });

    test('WA-RES-008 public CDN URL is downloadable', () async {
      final results = await WhatsAppResolver(dio: mockDio).discoverAll(
        Uri.parse(whatsappImageUrl),
      );
      expect(results, hasLength(1));
      expect(results.single.directUrl, whatsappImageUrl);
    });

    test('WA-RES-009 text-only channel HTML yields no media', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappChannelTextHtml(),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results, isEmpty);
      expect(
        WhatsAppResolver.detectMediaType(whatsappChannelTextHtml()),
        WhatsAppMediaType.text,
      );
    });

    test('WA-RES-010 private HTML is not parsed as media', () {
      final results = WhatsAppResolver.parseHtmlResources(
        html: whatsappPrivateHtml(),
        pageUrl: Uri.parse(whatsappChannelUrl),
      );
      expect(results, isEmpty);
      expect(
        WhatsAppResolver.classifyHtml(whatsappPrivateHtml()),
        WhatsAppHtmlStatus.restricted,
      );
    });

    test('WA-RES-011 encrypted mmg URL is not downloaded', () async {
      final results = await WhatsAppResolver(dio: mockDio).discoverAll(
        Uri.parse(whatsappPrivateMediaUrl),
      );
      expect(results, isEmpty);
    });
  });
}
