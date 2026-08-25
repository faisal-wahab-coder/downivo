import 'package:dio/dio.dart';
import 'package:download_engine/download_engine.dart';
import 'package:download_engine/src/content_providers/social_http_headers.dart';
import 'package:download_engine/src/web_request_proxy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WebRequestProxyProtocol', () {
    final proxy = WebRequestProxyProtocol.defaultProxyBase();

    test('rewrites the target as a query parameter', () {
      final target = Uri.parse('https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      final rewritten = WebRequestProxyProtocol.rewrite(
        target,
        proxyBase: proxy,
      );
      expect(rewritten.host, '127.0.0.1');
      expect(rewritten.port, 8787);
      expect(
        rewritten.queryParameters[WebRequestProxyProtocol.targetQueryParam],
        target.toString(),
      );
      expect(WebRequestProxyProtocol.isProxiedUri(rewritten, proxy), isTrue);
      expect(WebRequestProxyProtocol.targetFromProxyRequest(rewritten), target);
    });

    test('rejects loopback and private SSRF targets', () {
      expect(
        WebRequestProxyProtocol.isForbiddenProxyTarget(
          Uri.parse('http://127.0.0.1/secret'),
        ),
        isTrue,
      );
      expect(
        WebRequestProxyProtocol.isForbiddenProxyTarget(
          Uri.parse('http://192.168.1.1/router'),
        ),
        isTrue,
      );
      expect(
        WebRequestProxyProtocol.isForbiddenProxyTarget(
          Uri.parse('file:///etc/passwd'),
        ),
        isTrue,
      );
      expect(
        WebRequestProxyProtocol.isForbiddenProxyTarget(
          Uri.parse('https://www.youtube.com/watch?v=1'),
        ),
        isFalse,
      );
    });
  });

  test('interceptor sends browser requests through the proxy', () async {
    final adapter = _CaptureAdapter();
    final dio = Dio()
      ..httpClientAdapter = adapter
      ..interceptors.add(
        WebRequestProxyInterceptor(
          enabled: true,
          proxyBase: WebRequestProxyProtocol.defaultProxyBase(),
        ),
      );

    await dio.get<void>(
      'https://www.tiktok.com/@user/video/123',
      options: Options(headers: {'User-Agent': SocialHttpHeaders.userAgent}),
    );

    final sent = adapter.last!;
    expect(sent.uri.host, '127.0.0.1');
    expect(sent.uri.port, 8787);
    expect(
      sent.uri.queryParameters[WebRequestProxyProtocol.targetQueryParam],
      'https://www.tiktok.com/@user/video/123',
    );
    expect(sent.headers['User-Agent'], SocialHttpHeaders.userAgent);
  });

  test('registry canHandle covers every social platform used on mobile', () {
    const samples = {
      SocialPlatform.youtube: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
      SocialPlatform.tiktok: 'https://www.tiktok.com/@user/video/123',
      SocialPlatform.instagram: 'https://www.instagram.com/p/AbCdef12345/',
      SocialPlatform.twitter: 'https://x.com/user/status/123',
      SocialPlatform.facebook: 'https://www.facebook.com/watch/?v=123',
      SocialPlatform.reddit: 'https://www.reddit.com/r/test/comments/abc/title/',
      SocialPlatform.pinterest: 'https://www.pinterest.com/pin/123/',
      SocialPlatform.linkedin: 'https://www.linkedin.com/posts/user-activity-123',
      SocialPlatform.threads: 'https://www.threads.net/@user/post/abc',
      SocialPlatform.soundcloud: 'https://soundcloud.com/artist/track',
      SocialPlatform.vimeo: 'https://vimeo.com/123456',
      SocialPlatform.twitch: 'https://www.twitch.tv/videos/123',
      SocialPlatform.telegram: 'https://t.me/channel/123',
      SocialPlatform.snapchat: 'https://www.snapchat.com/spotlight/abc',
      SocialPlatform.whatsapp: 'https://wa.me/15551234567',
      SocialPlatform.dailymotion: 'https://www.dailymotion.com/video/x8abcd',
    };

    for (final entry in samples.entries) {
      final uri = Uri.parse(entry.value);
      expect(
        ContentProviderRegistry.canHandle(uri),
        isTrue,
        reason: entry.value,
      );
      expect(SocialPlatform.fromUri(uri), entry.key, reason: entry.value);
    }
  });
}

class _CaptureAdapter implements HttpClientAdapter {
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString('ok', 200);
  }

  @override
  void close({bool force = false}) {}
}
