import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import 'dailymotion_cdn_http.dart';
import 'social_http_headers.dart';

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

  var current = url;
  for (var hop = 0; hop < 8; hop++) {
    if (cancelToken != null && cancelToken.isCancelled) {
      throw cancelToken.cancelError ??
          DioException(
            requestOptions: RequestOptions(path: current),
            type: DioExceptionType.cancel,
          );
    }
    final response = await _getOnce(
      current,
      headers: DailymotionCdnHttp.withoutCookie(headers),
      cancelToken: cancelToken,
    );
    if (response.statusCode == 301 ||
        response.statusCode == 302 ||
        response.statusCode == 303 ||
        response.statusCode == 307 ||
        response.statusCode == 308) {
      final location = response.location;
      if (location == null || location.isEmpty) return response;
      current = Uri.parse(current).resolve(location).toString();
      continue;
    }
    return response;
  }
    return DailymotionCdnResponse(
      statusCode: 310,
      bytes: Uint8List(0),
      contentType: 'text/plain',
    );
}

const _timeout = Duration(seconds: 25);

Future<DailymotionCdnResponse> _getOnce(
  String url, {
  required Map<String, String> headers,
  CancelToken? cancelToken,
}) async {
  final uri = Uri.parse(url);
  final host = uri.host;
  final port = uri.hasPort ? uri.port : 443;
  final socket = await SecureSocket.connect(
    host,
    port,
    supportedProtocols: const ['http/1.1'],
    timeout: _timeout,
  );
  if (cancelToken != null) {
    cancelToken.whenCancel.then((_) {
      socket.destroy();
    });
  }

  try {
    final ua = headers['User-Agent'] ?? SocialHttpHeaders.userAgent;
    final headerLines = StringBuffer()
      ..write('GET ${DailymotionCdnHttp.requestTarget(url)} HTTP/1.1\r\n')
      ..write('Host: $host\r\n')
      ..write('User-Agent: $ua\r\n')
      ..write('Connection: close\r\n');
    headers.forEach((name, value) {
      final key = name.toLowerCase();
      if (key == 'host' ||
          key == 'user-agent' ||
          key == 'connection' ||
          key == 'content-length' ||
          key == 'cookie' ||
          key == 'accept-encoding') {
        return;
      }
      headerLines.write('$name: $value\r\n');
    });
    headerLines.write('\r\n');
    socket.add(ascii.encode(headerLines.toString()));
    await socket.flush();

    final reader = _SocketReader(socket);
    final statusLine = await reader
        .readLine()
        .timeout(_timeout, onTimeout: () => 'HTTP/1.1 504 TIMEOUT');
    final status = _statusCode(statusLine);
    final responseHeaders = <String, String>{};
    while (true) {
      final line = await reader.readLine().timeout(_timeout);
      if (line.isEmpty) break;
      final sep = line.indexOf(':');
      if (sep <= 0) continue;
      responseHeaders[line.substring(0, sep).trim().toLowerCase()] =
          line.substring(sep + 1).trim();
    }

    List<int> body;
    final encoding = responseHeaders['transfer-encoding'] ?? '';
    if (encoding.toLowerCase().contains('chunked')) {
      body = await reader.readChunked().timeout(_timeout);
    } else {
      final length = int.tryParse(responseHeaders['content-length'] ?? '');
      body = length != null
          ? await reader.readExact(length).timeout(_timeout)
          : await reader.readRemaining().timeout(_timeout);
    }

    if ((responseHeaders['content-encoding'] ?? '').contains('gzip') &&
        body.isNotEmpty) {
      body = gzip.decode(body);
    }

    return DailymotionCdnResponse(
      statusCode: status,
      contentType: responseHeaders['content-type'],
      bytes: Uint8List.fromList(body),
      location: responseHeaders['location'],
    );
  } finally {
    socket.destroy();
  }
}

int _statusCode(String statusLine) {
  final parts = statusLine.split(' ');
  if (parts.length < 2) return 0;
  return int.tryParse(parts[1]) ?? 0;
}

class _SocketReader {
  _SocketReader(SecureSocket socket) : _it = StreamIterator(socket);

  final StreamIterator<List<int>> _it;
  final List<int> _buf = <int>[];
  var _i = 0;

  Future<String> readLine() async {
    while (true) {
      for (var j = _i; j + 1 < _buf.length; j++) {
        if (_buf[j] == 13 && _buf[j + 1] == 10) {
          final line = utf8.decode(_buf.sublist(_i, j), allowMalformed: true);
          _i = j + 2;
          return line;
        }
      }
      if (!await _it.moveNext()) {
        final rest = utf8.decode(_buf.sublist(_i), allowMalformed: true);
        _i = _buf.length;
        return rest;
      }
      _buf.addAll(_it.current);
    }
  }

  Future<List<int>> readExact(int n) async {
    if (n <= 0) return const [];
    while (_buf.length - _i < n) {
      if (!await _it.moveNext()) break;
      _buf.addAll(_it.current);
    }
    final end = (_i + n).clamp(0, _buf.length);
    final out = _buf.sublist(_i, end);
    _i = end;
    return out;
  }

  Future<List<int>> readRemaining() async {
    while (await _it.moveNext()) {
      _buf.addAll(_it.current);
    }
    final out = _buf.sublist(_i);
    _i = _buf.length;
    return out;
  }

  Future<List<int>> readChunked() async {
    final out = BytesBuilder(copy: false);
    while (true) {
      final sizeLine = (await readLine()).trim();
      final hex = sizeLine.split(';').first.trim();
      final size = int.tryParse(hex, radix: 16) ?? 0;
      if (size == 0) {
        await readLine();
        break;
      }
      out.add(await readExact(size));
      await readLine();
    }
    return out.takeBytes();
  }
}
