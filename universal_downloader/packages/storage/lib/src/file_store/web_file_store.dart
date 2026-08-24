import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'memory_file_store.dart';

/// Browser [FileStore]: in-memory map with Save-to-disk via Blob download.
class WebFileStore extends MemoryFileStore {
  @override
  Future<void> saveToUserDisk(String path, String fileName) async {
    final bytes = await readBytes(path);
    final data = bytes.toJS;
    final blob = web.Blob(
      [data].toJS,
      web.BlobPropertyBag(type: 'application/octet-stream'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = fileName
      ..style.display = 'none';
    web.document.body?.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }
}
