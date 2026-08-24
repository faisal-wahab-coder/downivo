import 'dart:io';

import 'package:udm_qa_server/download_test_server.dart';

Future<void> main(List<String> args) async {
  var port = 8765;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--port' && i + 1 < args.length) {
      port = int.parse(args[i + 1]);
    }
  }

  final server = await DownloadTestServer.start(port: port);
  stdout.writeln('UDM download test server on ${server.origin}');
  stdout.writeln('  GET /health');
  stdout.writeln('  GET /files/sample.bin');
  stdout.writeln('  GET /files/small.txt');
  stdout.writeln('  GET /files/video.mp4');
  stdout.writeln('  GET /slow/sample.bin?delayMs=15');
  stdout.writeln('  GET /redirect/sample.bin');
  stdout.writeln('  GET /status/404');
  await ProcessSignal.sigint.watch().first;
  await server.close();
}
