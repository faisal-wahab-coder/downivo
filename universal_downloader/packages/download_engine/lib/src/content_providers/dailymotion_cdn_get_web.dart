import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../web_request_proxy.dart';
import 'dailymotion_cdn_http.dart';

Future<DailymotionCdnResponse> dailymotionCdnGet(
  String url, {
  required Map<String, String> headers,
  CancelToken? cancelToken,
}) async {
  if (cancelToken != null && cancelToken.isCancelled) {
    throw cancelToken.cancelError ??
        DioException(
          requestOptions: RequestOptions(path: url),
          type: DioExceptionType.cancel,
        );
  }

  final dio = createEngineDio(
    connectTimeout: const Duration(seconds: 25),
    receiveTimeout: const Duration(seconds: 25),
  );
  final response = await dio.get<List<int>>(
    url,
    options: Options(
      headers: DailymotionCdnHttp.withoutCookie(headers),
      responseType: ResponseType.bytes,
      followRedirects: true,
      maxRedirects: 8,
      validateStatus: (status) => status != null && status < 400,
    ),
    cancelToken: cancelToken,
  );
  return DailymotionCdnResponse(
    statusCode: response.statusCode ?? 0,
    bytes: Uint8List.fromList(response.data ?? const <int>[]),
    contentType: response.headers.value('content-type'),
    location: response.headers.value('location'),
  );
}
