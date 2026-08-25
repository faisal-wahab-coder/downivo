import 'package:dio/dio.dart';

import 'social_http_headers.dart';

/// Resolves a short-link [pageUrl] to its final location when possible.
class SocialUrlResolver {
  SocialUrlResolver({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  Future<Uri> resolveRedirects(Uri pageUrl) async {
    try {
      final response = await _dio.get<void>(
        pageUrl.toString(),
        options: Options(
          followRedirects: false,
          validateStatus: (status) => status != null && status >= 300 && status < 400,
          headers: {'User-Agent': SocialHttpHeaders.userAgent},
        ),
      );
      final location = response.headers.value('location');
      if (location == null || location.isEmpty) return pageUrl;
      final resolved = Uri.parse(location);
      if (!resolved.hasScheme) {
        return resolveRedirects(pageUrl.resolveUri(resolved));
      }
      return resolveRedirects(resolved);
    } on DioException {
      return pageUrl;
    }
  }
}
