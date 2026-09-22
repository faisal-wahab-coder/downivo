import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

import 'support/qa_harness.dart';

void main() {
  ensureDownloadTestBinding();

  test('large range-capable file uses parallel connections', () async {
    final payload = Uint8List(2 * 1024 * 1024);
    for (var index = 0; index < payload.length; index++) {
      payload[index] = index & 0xff;
    }

    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) async {
      final range = request.headers.value(HttpHeaders.rangeHeader);
      var start = 0;
      var end = payload.length - 1;
      var status = HttpStatus.ok;
      if (range != null) {
        final match = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range);
        if (match != null) {
          start = int.parse(match.group(1)!);
          final endRaw = match.group(2);
          if (endRaw != null && endRaw.isNotEmpty) {
            end = int.parse(endRaw);
          }
          if (start < 0) start = 0;
          if (end >= payload.length) end = payload.length - 1;
          if (start > end) start = end;
          status = HttpStatus.partialContent;
          request.response.headers.set(
            HttpHeaders.contentRangeHeader,
            'bytes $start-$end/${payload.length}',
          );
        }
      }
      final slice = payload.sublist(start, end + 1);
      request.response
        ..statusCode = status
        ..headers.contentType = ContentType('video', 'mp4')
        ..headers.contentLength = slice.length
        ..headers.set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..add(slice);
      await request.response.close();
    });

    final harness = await DownloadQaHarness.create();
    addTearDown(harness.dispose);
    addTearDown(() => server.close(force: true));

    harness.manager.defaultConnectionCount = 4;
    final task = await harness.manager.enqueue(
      'http://${server.address.host}:${server.port}/clip.mp4',
      fileName: 'clip.mp4',
    );
    final done = await waitForTask(
      harness.manager,
      task.id,
      (current) =>
          current?.status == DownloadStatus.completed ||
          current?.status == DownloadStatus.failed,
      timeout: const Duration(seconds: 20),
    );

    expect(done!.status, DownloadStatus.completed, reason: done.errorMessage);
    expect(done.connectionCount, 4);
    final file = File(done.filePath!);
    final saved = await file.readAsBytes();
    expect(saved.length, payload.length);
    expect(saved.first, payload.first);
    expect(saved[payload.length ~/ 2], payload[payload.length ~/ 2]);
    expect(saved.last, payload.last);
  });
}
