import 'dart:io';

import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_types/shared_types.dart';

import '../support/qa_harness.dart';

void main() {
  ensureDownloadTestBinding();

  DownloadTask task({
    required String id,
    required DownloadStatus status,
    String? filePath,
    int bytesReceived = 0,
    int fileSize = 100,
  }) {
    final now = DateTime(2026, 8, 15, 12);
    return DownloadTask(
      id: id,
      url: 'https://example.com/$id.bin',
      fileName: '$id.bin',
      filePath: filePath,
      fileSize: fileSize,
      status: status,
      progress: bytesReceived / fileSize,
      bytesReceived: bytesReceived,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('CR-001 downloading resets to queued on load', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    await harness.repository.save(
      task(id: 'in-flight', status: DownloadStatus.downloading),
    );
    await harness.manager.loadFromDatabase();

    expect(harness.manager.tasks.single.status, DownloadStatus.queued);
    expect(
      (await harness.repository.getById('in-flight'))!.status,
      DownloadStatus.queued,
    );
  });

  test('CR-002 preparing and verifying reset to queued', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    await harness.repository.save(
      task(id: 'prep', status: DownloadStatus.preparing),
    );
    await harness.repository.save(
      task(id: 'verify', status: DownloadStatus.verifying),
    );
    await harness.manager.loadFromDatabase();

    expect(
      harness.manager.tasks.map((item) => item.status).toSet(),
      {DownloadStatus.queued},
    );
  });

  test('CR-003 paused stays paused', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    await harness.repository.save(
      task(id: 'paused', status: DownloadStatus.paused),
    );
    await harness.manager.loadFromDatabase();

    expect(harness.manager.tasks.single.status, DownloadStatus.paused);
  });

  test('CR-004 hydrates bytes from a partial file', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    final path = p.join(harness.tempRoot.path, 'partial.bin');
    await File(path).writeAsBytes(List<int>.filled(40, 1));
    await harness.repository.save(
      task(
        id: 'partial',
        status: DownloadStatus.downloading,
        filePath: path,
        bytesReceived: 0,
        fileSize: 100,
      ),
    );
    await harness.manager.loadFromDatabase();

    final recovered = harness.manager.tasks.single;
    expect(recovered.status, DownloadStatus.queued);
    expect(recovered.bytesReceived, 40);
    expect(recovered.progress, closeTo(0.4, 0.001));
  });
}
