import 'package:dio/dio.dart';

import 'dailymotion_cdn_http.dart';

Future<DailymotionCdnResponse> dailymotionCdnGet(
  String url, {
  required Map<String, String> headers,
  CancelToken? cancelToken,
}) {
  throw UnsupportedError(
    'Dailymotion CDN GET requires dart:io or the web implementation '
    '($url, ${headers.length}, cancelled=${cancelToken?.isCancelled}).',
  );
}
