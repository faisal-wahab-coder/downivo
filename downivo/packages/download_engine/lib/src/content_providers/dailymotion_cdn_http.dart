import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'dailymotion_cdn_get.dart'
    if (dart.library.io) 'dailymotion_cdn_get_io.dart'
    if (dart.library.html) 'dailymotion_cdn_get_web.dart'
    if (dart.library.js_interop) 'dailymotion_cdn_get_web.dart' as cdn_get;

/// Cookie-less HTTP GET for Dailymotion CDN (`cdndirector` / `dmcdn`).
///
/// On VM, a raw TLS socket that only advertises `http/1.1` is used because
/// `dart:io` [HttpClient] is fingerprint-blocked (HTTP 403). On web the
/// request goes through Dio (and the CORS proxy when enabled).
class DailymotionCdnHttp {
  const DailymotionCdnHttp._();

  static Map<String, String> withoutCookie(Map<String, String> headers) {
    return {
      for (final entry in headers.entries)
        if (entry.key.toLowerCase() != 'cookie' &&
            entry.key.toLowerCase() != 'accept-encoding')
          entry.key: entry.value,
    };
  }

  /// Origin-form request target, preserving `sec` / `sec2(...)` encoding.
  static String requestTarget(String url) {
    final withoutHash = url.split('#').first;
    final scheme = withoutHash.indexOf('://');
    final pathStart = scheme < 0
        ? withoutHash.indexOf('/')
        : withoutHash.indexOf('/', scheme + 3);
    if (pathStart < 0) return '/';
    final path = withoutHash.substring(pathStart);
    return path.isEmpty ? '/' : path;
  }

  static Future<DailymotionCdnResponse> get(
    String url, {
    required Map<String, String> headers,
    CancelToken? cancelToken,
  }) {
    return cdn_get.dailymotionCdnGet(
      url,
      headers: headers,
      cancelToken: cancelToken,
    );
  }
}

class DailymotionCdnResponse {
  const DailymotionCdnResponse({
    required this.statusCode,
    required this.bytes,
    this.contentType,
    this.location,
  });

  final int statusCode;
  final String? contentType;
  final Uint8List bytes;
  final String? location;

  String get text => utf8.decode(bytes, allowMalformed: true);
}
