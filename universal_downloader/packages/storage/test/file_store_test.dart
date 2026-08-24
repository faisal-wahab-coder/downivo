import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:storage/storage.dart';

void main() {
  test('FileStore write/read/delete round-trip', () async {
    final store = MemoryFileStore();
    await store.createDirectory('/udm/Videos');
    await store.writeBytes('/udm/Videos/clip.mp4', Uint8List.fromList([1, 2, 3, 4]));

    expect(await store.exists('/udm/Videos/clip.mp4'), isTrue);
    expect(await store.length('/udm/Videos/clip.mp4'), 4);
    expect(await store.readBytes('/udm/Videos/clip.mp4'), [1, 2, 3, 4]);

    final listed = await store.list('/udm/Videos');
    expect(listed.single.name, 'clip.mp4');

    await store.delete('/udm/Videos/clip.mp4');
    expect(await store.exists('/udm/Videos/clip.mp4'), isFalse);
  });

  test('FileStore append sink writes combined bytes', () async {
    final store = MemoryFileStore();
    await store.writeBytes('/file.bin', Uint8List.fromList([1, 2]));
    final sink = store.openWrite('/file.bin', append: true);
    sink.add([3, 4]);
    await sink.close();
    expect(await store.readBytes('/file.bin'), [1, 2, 3, 4]);
  });

  test('FileStore rename and copy', () async {
    final store = MemoryFileStore();
    await store.writeBytes('/a.txt', Uint8List.fromList([9]));
    await store.copy('/a.txt', '/b.txt');
    await store.rename('/b.txt', '/c.txt');
    expect(await store.exists('/a.txt'), isTrue);
    expect(await store.exists('/b.txt'), isFalse);
    expect(await store.exists('/c.txt'), isTrue);
  });
}
