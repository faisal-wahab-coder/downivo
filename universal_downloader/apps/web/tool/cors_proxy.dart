import 'dart:async';
import 'dart:io';

import 'package:download_engine/src/web_request_proxy_protocol.dart';

/// Reverse proxy so Flutter Web can resolve the same social URLs as Android.
///
/// Binds loopback only. Start before `flutter run -d chrome`:
///
/// ```bash
/// dart run tool/cors_proxy.dart
/// ```
Future<void> main(List<String> args) async {
  final port = int.tryParse(
        Platform.environment['UD_WEB_PROXY_PORT'] ?? '',
      ) ??
      WebRequestProxyProtocol.defaultPort;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln(
    'Universal Downloader web proxy listening on '
    'http://${WebRequestProxyProtocol.defaultHost}:$port',
  );

  final client = HttpClient()
    ..autoUncompress = true
    ..connectionTimeout = const Duration(seconds: 30)
    ..idleTimeout = const Duration(seconds: 15)
    ..userAgent = null;

  await for (final request in server) {
    unawaited(_handle(request, client));
  }
}

const _hopByHop = {
  'connection',
  'keep-alive',
  'proxy-authenticate',
  'proxy-authorization',
  'te',
  'trailers',
  'transfer-encoding',
  'upgrade',
  'host',
  'content-length',
  'accept-encoding',
};

Future<void> _handle(HttpRequest request, HttpClient client) async {
  _applyCors(request.response);
  try {
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    if (request.method == 'GET' && request.uri.path == '/health') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write('ok');
      await request.response.close();
      return;
    }

    final target = WebRequestProxyProtocol.targetFromProxyRequest(request.uri);
    if (target == null) {
      request.response.statusCode = HttpStatus.badRequest;
      request.response.write('Missing ${WebRequestProxyProtocol.targetQueryParam} query parameter.');
      await request.response.close();
      return;
    }
    if (WebRequestProxyProtocol.isForbiddenProxyTarget(target)) {
      request.response.statusCode = HttpStatus.forbidden;
      request.response.write('Proxy target is not allowed.');
      await request.response.close();
      return;
    }

    final outbound = await client.openUrl(request.method, target);
    outbound.followRedirects = true;
    outbound.maxRedirects = 8;
    request.headers.forEach((name, values) {
      if (_hopByHop.contains(name.toLowerCase())) return;
      if (name.toLowerCase() == WebRequestProxyProtocol.markerHeader) return;
      outbound.headers.removeAll(name);
      for (final value in values) {
        outbound.headers.add(name, value);
      }
    });

    if (request.method != 'GET' && request.method != 'HEAD') {
      await outbound.addStream(request);
    }

    final upstream = await outbound.close().timeout(
      const Duration(minutes: 30),
    );
    request.response.statusCode = upstream.statusCode;
    upstream.headers.forEach((name, values) {
      if (_hopByHop.contains(name.toLowerCase())) return;
      for (final value in values) {
        request.response.headers.add(name, value);
      }
    });
    _applyCors(request.response);
    await request.response.addStream(upstream);
    await request.response.close();
  } on Object catch (error) {
    if (request.response.headers.value('access-control-allow-origin') == null) {
      _applyCors(request.response);
    }
    try {
      request.response.statusCode = HttpStatus.badGateway;
      request.response.write('Proxy error: $error');
      await request.response.close();
    } on Object {
      // Client already disconnected.
    }
  }
}

void _applyCors(HttpResponse response) {
  response.headers
    ..set(HttpHeaders.accessControlAllowOriginHeader, '*')
    ..set(HttpHeaders.accessControlAllowMethodsHeader, 'GET, POST, PUT, HEAD, OPTIONS')
    ..set(HttpHeaders.accessControlAllowHeadersHeader, '*')
    ..set(HttpHeaders.accessControlExposeHeadersHeader, '*')
    ..set('Access-Control-Max-Age', '86400');
}
