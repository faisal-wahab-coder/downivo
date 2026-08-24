/// Shared contract between the Flutter web Dio interceptor and the local
/// CORS reverse proxy (`apps/web/tool/cors_proxy.dart`).
class WebRequestProxyProtocol {
  const WebRequestProxyProtocol._();

  static const defaultHost = '127.0.0.1';
  static const defaultPort = 8787;
  static const defaultBaseUrl = 'http://$defaultHost:$defaultPort';
  static const targetQueryParam = 'u';
  static const markerHeader = 'x-ud-proxy';

  static const dartDefineKey = 'UD_WEB_PROXY';

  static Uri defaultProxyBase() => Uri.parse(defaultBaseUrl);

  static bool isProxiedUri(Uri uri, Uri proxyBase) {
    return uri.host == proxyBase.host &&
        uri.hasPort == proxyBase.hasPort &&
        (!uri.hasPort || uri.port == proxyBase.port) &&
        uri.queryParameters.containsKey(targetQueryParam);
  }

  static Uri rewrite(Uri target, {required Uri proxyBase}) {
    return proxyBase.replace(
      queryParameters: {
        ...proxyBase.queryParameters,
        targetQueryParam: target.toString(),
      },
    );
  }

  static Uri? targetFromProxyRequest(Uri proxyRequest) {
    final raw = proxyRequest.queryParameters[targetQueryParam];
    if (raw == null || raw.isEmpty) return null;
    return Uri.tryParse(raw);
  }

  /// Rejects non-http(s) URLs and loopback/private targets (SSRF).
  static bool isForbiddenProxyTarget(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') return true;
    if (!uri.hasAuthority || uri.host.isEmpty) return true;

    final host = uri.host.toLowerCase();
    if (host == 'localhost' ||
        host == '::1' ||
        host == '[::1]' ||
        host == '0.0.0.0' ||
        host == '::' ||
        host.endsWith('.localhost') ||
        host.endsWith('.local') ||
        host.endsWith('.internal')) {
      return true;
    }
    if (host.startsWith('fe80:') ||
        host.startsWith('fc') ||
        host.startsWith('fd')) {
      return true;
    }

    final ipv4 = RegExp(r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$')
        .firstMatch(host);
    if (ipv4 == null) return false;
    final parts = [
      int.parse(ipv4.group(1)!),
      int.parse(ipv4.group(2)!),
      int.parse(ipv4.group(3)!),
      int.parse(ipv4.group(4)!),
    ];
    if (parts.any((part) => part > 255)) return true;
    final a = parts[0];
    final b = parts[1];
    if (a == 0 || a == 10 || a == 127) return true;
    if (a == 169 && b == 254) return true;
    if (a == 192 && b == 168) return true;
    if (a == 172 && b >= 16 && b <= 31) return true;
    return false;
  }
}
