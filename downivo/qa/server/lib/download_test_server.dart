import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// In-process HTTP fixture server for download QA.
class DownloadTestServer {
  DownloadTestServer._(this._server, this.payloads);

  final HttpServer _server;
  final Map<String, List<int>> payloads;

  int get port => _server.port;
  String get origin => 'http://127.0.0.1:$port';

  static List<int> sampleBytes({int length = 64 * 1024}) =>
      List<int>.generate(length, (index) => index % 256);

  static Future<DownloadTestServer> start({int port = 0}) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    final payloads = <String, List<int>>{
      'sample.bin': sampleBytes(),
      'small.txt': utf8.encode('hello-udm-qa'),
      'video.mp4': sampleBytes(length: 8 * 1024),
    };
    final instance = DownloadTestServer._(server, payloads);
    server.listen(instance._handle);
    return instance;
  }

  String url(String path) => '$origin$path';

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (request.method != 'GET') {
        request.response.statusCode = HttpStatus.methodNotAllowed;
        await request.response.close();
        return;
      }

      if (path == '/health') {
        request.response
          ..statusCode = HttpStatus.ok
          ..write('ok');
        await request.response.close();
        return;
      }

      if (path.startsWith('/status/')) {
        final code = int.tryParse(path.split('/').last) ?? 500;
        request.response.statusCode = code;
        await request.response.close();
        return;
      }

      if (path == '/redirect/sample.bin') {
        request.response
          ..statusCode = HttpStatus.found
          ..headers.set(HttpHeaders.locationHeader, '/files/sample.bin');
        await request.response.close();
        return;
      }

      if (path == '/headers/html') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.html
          ..write('<html><body>not a file</body></html>');
        await request.response.close();
        return;
      }

      if (path == '/headers/disposition') {
        final body = payloads['small.txt']!;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.binary
          ..headers.set(
            HttpHeaders.contentDisposition,
            'attachment; filename="report.pdf"',
          )
          ..headers.contentLength = body.length;
        request.response.add(body);
        await request.response.close();
        return;
      }

      if (path == '/headers/utf8-name') {
        final body = payloads['small.txt']!;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.binary
          ..headers.set(
            HttpHeaders.contentDisposition,
            "attachment; filename*=UTF-8''caf%C3%A9.bin",
          )
          ..headers.contentLength = body.length;
        request.response.add(body);
        await request.response.close();
        return;
      }

      if (path == '/headers/traverse') {
        final body = payloads['small.txt']!;
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.binary
          ..headers.set(
            HttpHeaders.contentDisposition,
            'attachment; filename="../../etc/passwd"',
          )
          ..headers.contentLength = body.length;
        request.response.add(body);
        await request.response.close();
        return;
      }

      if (path == '/mismatch/file.bin') {
        request.response
          ..statusCode = HttpStatus.ok
          ..headers.contentType = ContentType.binary
          ..headers.contentLength = 100;
        request.response.add(List<int>.filled(10, 7));
        await request.response.close();
        return;
      }

      if (path.startsWith('/slow/')) {
        await _writeFile(request, path.substring('/slow/'.length), slow: true);
        return;
      }

      if (path.startsWith('/no-range/')) {
        await _writeFile(
          request,
          path.substring('/no-range/'.length),
          honorRange: false,
        );
        return;
      }

      if (path.startsWith('/files/') || path.startsWith('/range/')) {
        final name = path.split('/').last;
        await _writeFile(request, name, honorRange: true);
        return;
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } on Object {
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } on Object {
        // Client already gone.
      }
    }
  }

  Future<void> _writeFile(
    HttpRequest request,
    String name, {
    bool honorRange = true,
    bool slow = false,
  }) async {
    final body = payloads[name];
    if (body == null) {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    final contentType = name.endsWith('.mp4')
        ? ContentType('video', 'mp4')
        : name.endsWith('.txt')
            ? ContentType.text
            : ContentType.binary;

    var offset = 0;
    var status = HttpStatus.ok;
    if (honorRange) {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      final match = range == null
          ? null
          : RegExp(r'bytes=(\d+)-').firstMatch(range);
      if (match != null) {
        offset = int.parse(match.group(1)!).clamp(0, body.length);
        status = HttpStatus.partialContent;
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          'bytes $offset-${body.length - 1}/${body.length}',
        );
      }
    }

    final slice = body.sublist(offset);
    request.response
      ..statusCode = status
      ..headers.contentType = contentType
      ..headers.contentLength = slice.length
      ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes');

    if (!slow) {
      request.response.add(slice);
      await request.response.close();
      return;
    }

    const chunkSize = 1024;
    final delayMs = int.tryParse(
          request.uri.queryParameters['delayMs'] ?? '',
        ) ??
        15;
    try {
      for (var i = 0; i < slice.length; i += chunkSize) {
        final end = (i + chunkSize).clamp(0, slice.length);
        request.response.add(slice.sublist(i, end));
        await request.response.flush();
        await Future<void>.delayed(Duration(milliseconds: delayMs));
      }
      await request.response.close();
    } on Object {
      try {
        await request.response.close();
      } on Object {
        // Client cancelled the stream.
      }
    }
  }
}
