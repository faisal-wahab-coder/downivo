import 'dart:io';

import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';
import 'package:storage/storage.dart';
import 'package:udm_qa_server/download_test_server.dart';

import '../support/qa_harness.dart';

void main() {
  ensureDownloadTestBinding();

  late DownloadTestServer server;

  setUpAll(() async {
    server = await DownloadTestServer.start();
  });

  tearDownAll(() async {
    await server.close();
  });

  test('DL-002 enqueue invalid URL throws', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    expect(
      () => harness.manager.enqueue('not-a-url'),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('DL-001 enqueue persists a queued task', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(
      server.url('/files/small.txt'),
      fileName: 'small.txt',
    );
    expect(task.status, DownloadStatus.queued);
    expect(await harness.repository.getById(task.id), isNotNull);
  });

  test('DL-003 completes a small file with matching bytes', () async {
    final harness = await DownloadQaHarness.create();
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(server.url('/files/small.txt'));
    final done = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.completed,
    );
    expect(done, isNotNull);
    final file = File(done!.filePath!);
    expect(await file.readAsString(), 'hello-udm-qa');
  });

  test('DL-004 uses Content-Disposition filename', () async {
    final harness = await DownloadQaHarness.create();
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(
      server.url('/headers/disposition'),
    );
    final done = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.completed,
    );
    expect(done!.fileName, 'report.pdf');
  });

  test('DL-005 follows redirects', () async {
    final harness = await DownloadQaHarness.create();
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(
      server.url('/redirect/sample.bin'),
    );
    final done = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.completed,
    );
    expect(await File(done!.filePath!).length(), 64 * 1024);
  });

  test('DL-006 pause then resume completes an identical file', () async {
    final harness = await DownloadQaHarness.create();
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(
      server.url('/slow/sample.bin?delayMs=40'),
    );
    await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.downloading,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final inflight = harness.manager.tasks.firstWhere((item) => item.id == task.id);
    if (inflight.status != DownloadStatus.completed) {
      await harness.manager.pause(task.id);
      await waitForTask(
        harness.manager,
        task.id,
        (current) => current?.status == DownloadStatus.paused,
      );
      await Future<void>.delayed(const Duration(milliseconds: 80));
      await harness.manager.resume(task.id);
    }
    final done = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.completed,
      timeout: const Duration(seconds: 12),
    );
    expect(
      await File(done!.filePath!).readAsBytes(),
      DownloadTestServer.sampleBytes(),
    );
  });

  test('DL-007 cancel deletes the partial file', () async {
    final harness = await DownloadQaHarness.create();
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(
      server.url('/slow/sample.bin?delayMs=40'),
    );
    final started = await waitForTask(
      harness.manager,
      task.id,
      (current) =>
          current?.filePath != null && (current?.bytesReceived ?? 0) > 0,
    );
    final path = started!.filePath!;
    await harness.manager.cancel(task.id);

    expect(harness.manager.tasks.where((item) => item.id == task.id), isEmpty);
    expect(await File(path).exists(), isFalse);
    final stored = await harness.repository.getById(task.id);
    expect(stored?.status, DownloadStatus.cancelled);
  });

  test('DL-008 404 fails without retries', () async {
    final harness = await DownloadQaHarness.create(maxRetries: 0);
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(server.url('/status/404'));
    final failed = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.failed,
    );
    expect(failed!.errorMessage, contains('404'));
  });

  test('DL-009 HTML content type fails', () async {
    final harness = await DownloadQaHarness.create(maxRetries: 0);
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(server.url('/headers/html'));
    final failed = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.failed,
    );
    expect(failed!.errorMessage, contains('web page'));
  });

  test('DL-010 size mismatch fails integrity check', () async {
    final harness = await DownloadQaHarness.create(maxRetries: 0);
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(server.url('/mismatch/file.bin'));
    final failed = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.failed,
    );
    expect(failed!.status, DownloadStatus.failed);
    expect(
      failed.errorMessage,
      anyOf(contains('integrity'), contains('Connection closed')),
    );
  });

  test('DL-011 maxConcurrent keeps the second task queued', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 1);
    addTearDown(harness.dispose);

    final first = await harness.manager.enqueue(
      server.url('/slow/sample.bin?delayMs=20'),
    );
    final second = await harness.manager.enqueue(server.url('/files/small.txt'));
    await waitForTask(
      harness.manager,
      first.id,
      (current) => current?.status == DownloadStatus.downloading,
    );
    expect(
      harness.manager.tasks.firstWhere((item) => item.id == second.id).status,
      DownloadStatus.queued,
    );
    await harness.manager.cancel(first.id);
    await harness.manager.cancel(second.id);
  });

  test('DL-014 cancel queued task does not resurrect', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 1);
    addTearDown(harness.dispose);

    final first = await harness.manager.enqueue(
      server.url('/slow/sample.bin?delayMs=40'),
    );
    final second = await harness.manager.enqueue(
      server.url('/files/small.txt'),
      fileName: 'queued.txt',
    );
    await waitForTask(
      harness.manager,
      first.id,
      (current) => current?.status == DownloadStatus.downloading,
    );
    expect(
      harness.manager.tasks.firstWhere((item) => item.id == second.id).status,
      DownloadStatus.queued,
    );

    await harness.manager.cancel(second.id);

    expect(harness.manager.tasks.where((item) => item.id == second.id), isEmpty);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(harness.manager.tasks.where((item) => item.id == second.id), isEmpty);
    expect(
      (await harness.repository.getById(second.id))?.status,
      DownloadStatus.cancelled,
    );

    await harness.manager.cancel(first.id);
  });

  test('DL-015 cancel before start stays cancelled', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(
      server.url('/files/small.txt'),
      fileName: 'held.txt',
    );
    expect(task.status, DownloadStatus.queued);
    await harness.manager.cancel(task.id);

    expect(harness.manager.tasks.where((item) => item.id == task.id), isEmpty);
    expect(
      (await harness.repository.getById(task.id))?.status,
      DownloadStatus.cancelled,
    );
  });

  test('DL-012 reorderQueue persists order', () async {
    final harness = await DownloadQaHarness.create(maxConcurrent: 0);
    addTearDown(harness.dispose);

    final first = await harness.manager.enqueue(
      server.url('/files/small.txt'),
      fileName: 'a.txt',
    );
    final second = await harness.manager.enqueue(
      server.url('/files/sample.bin'),
      fileName: 'b.bin',
    );
    await harness.manager.reorderQueue([second.id, first.id]);
    expect(await harness.repository.getQueueOrder(), [second.id, first.id]);
  });

  test('DL-013 video MIME lands in Videos', () async {
    final harness = await DownloadQaHarness.create();
    addTearDown(harness.dispose);

    final task = await harness.manager.enqueue(server.url('/files/video.mp4'));
    final done = await waitForTask(
      harness.manager,
      task.id,
      (current) => current?.status == DownloadStatus.completed,
    );
    expect(
      done!.filePath,
      contains(StorageCategory.videos.folderName),
    );
  });
}
