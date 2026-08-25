import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'web_request_proxy_protocol.dart';

export 'web_request_proxy_protocol.dart';

/// Routes browser HTTP through a same-machine reverse proxy so social URL
/// resolvers can send User-Agent / Referer and are not blocked by CORS.
class WebRequestProxy {
  const WebRequestProxy._();

  static const configuredBase = String.fromEnvironment(
    WebRequestProxyProtocol.dartDefineKey,
    defaultValue: WebRequestProxyProtocol.defaultBaseUrl,
  );

  static bool get isEnabled => kIsWeb && configuredBase.isNotEmpty;

  static Uri get proxyBase => Uri.parse(
        configuredBase.isEmpty
            ? WebRequestProxyProtocol.defaultBaseUrl
            : configuredBase,
      );
}

void attachWebRequestProxy(Dio dio) {
  if (!WebRequestProxy.isEnabled) return;
  if (dio.interceptors.any((i) => i is WebRequestProxyInterceptor)) return;
  dio.interceptors.insert(0, WebRequestProxyInterceptor());
}

Dio createEngineDio({
  Duration connectTimeout = const Duration(seconds: 30),
  Duration receiveTimeout = const Duration(minutes: 30),
}) {
  final dio = Dio()
    ..options.connectTimeout = connectTimeout
    ..options.receiveTimeout = receiveTimeout;
  attachWebRequestProxy(dio);
  return dio;
}

class WebRequestProxyInterceptor extends Interceptor {
  WebRequestProxyInterceptor({
    Uri? proxyBase,
    bool? enabled,
  })  : _proxyBase = proxyBase ?? WebRequestProxy.proxyBase,
        _enabled = enabled ?? WebRequestProxy.isEnabled;

  final Uri _proxyBase;
  final bool _enabled;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!_enabled) {
      handler.next(options);
      return;
    }
    final target = options.uri;
    if (WebRequestProxyProtocol.isProxiedUri(target, _proxyBase)) {
      handler.next(options);
      return;
    }
    options
      ..baseUrl = '${_proxyBase.scheme}://${_proxyBase.authority}'
      ..path = _proxyBase.path.isEmpty ? '/' : _proxyBase.path
      ..queryParameters.clear()
      ..queryParameters[WebRequestProxyProtocol.targetQueryParam] =
          target.toString()
      ..headers[WebRequestProxyProtocol.markerHeader] = '1';
    handler.next(options);
  }
}
