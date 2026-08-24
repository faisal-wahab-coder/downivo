import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'web_request_proxy.dart';

/// Converts low-level network errors into short UI messages.
class DownloadErrorFormatter {
  const DownloadErrorFormatter._();

  static String fromObject(Object error) {
    if (error is DioException) return fromDio(error);
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'Invalid download request.';
    }
    final text = error.toString();
    if (text.startsWith('DioException')) return 'Download failed. Please try again.';
    return text.length > 160 ? '${text.substring(0, 157)}...' : text;
  }

  static String fromDio(DioException error) {
    final status = error.response?.statusCode;
    if (status == 403) {
      return 'Access blocked (403). The site refused the download. '
          'Try opening the link in the in-app browser first, or use a public post.';
    }
    if (status == 404) {
      return 'Media not found (404). The link may have expired or been removed.';
    }
    if (status == 429) {
      return 'Too many requests (429). Wait a moment and try again.';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      if (_isMissingWebProxy(error)) {
        return _missingWebProxyMessage;
      }
      return 'Connection timed out. Check your network and try again.';
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      if (_isMissingWebProxy(error)) {
        return _missingWebProxyMessage;
      }
      if (_isBrowserCors(error)) {
        return 'Blocked by the browser (CORS). Start the web download proxy '
            '(apps/web/tool/cors_proxy.dart) so social URLs work like on Android.';
      }
      if (error.type == DioExceptionType.connectionError) {
        return 'Network error. Check your connection and try again.';
      }
    }
    return 'Download failed. Please try again.';
  }

  /// CORS and similar browser blocks will not succeed on retry.
  static bool isPermanent(DioException error) {
    if (_isMissingWebProxy(error)) return false;
    return _isBrowserCors(error);
  }

  static const _missingWebProxyMessage =
      'Web download proxy is not running. From apps/web run '
      '`dart run tool/cors_proxy.dart`, then try the link again.';

  static bool _isMissingWebProxy(DioException error) {
    if (!kIsWeb || !WebRequestProxy.isEnabled) return false;
    if (error.type != DioExceptionType.connectionError &&
        error.type != DioExceptionType.connectionTimeout) {
      return false;
    }
    return WebRequestProxyProtocol.isProxiedUri(
      error.requestOptions.uri,
      WebRequestProxy.proxyBase,
    );
  }

  static bool _isBrowserCors(DioException error) {
    if (!kIsWeb) return false;
    final parts = [
      error.message ?? '',
      error.error?.toString() ?? '',
      error.toString(),
    ].join(' ').toLowerCase();
    return parts.contains('xmlhttprequest') ||
        parts.contains('cors') ||
        parts.contains('failed to fetch') ||
        parts.contains('networkerror') ||
        parts.contains('access-control-allow-origin');
  }
}
