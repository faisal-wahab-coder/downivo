import 'dart:io';

import 'package:database/database.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_types/shared_types.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:storage/storage.dart';

class FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  FakePathProvider(this.root);

  final String root;

  @override
  Future<String?> getApplicationDocumentsPath() async => root;
}

class DownloadQaHarness {
  DownloadQaHarness._({
    required this.tempRoot,
    required this.database,
    required this.repository,
    required this.manager,
    required this.storagePaths,
  });

  final Directory tempRoot;
  final AppDatabase database;
  final DownloadRepository repository;
  final DownloadManager manager;
  final StoragePaths storagePaths;

  static Future<DownloadQaHarness> create({
    int maxConcurrent = 3,
    int maxRetries = 0,
  }) async {
    final tempRoot = await Directory.systemTemp.createTemp('udm_qa_');
    PathProviderPlatform.instance = FakePathProvider(tempRoot.path);
    final database = AppDatabase();
    await database.markInitialized();
    final repository = DownloadRepository(database);
    final storagePaths = StoragePaths(
      rootPath: p.join(tempRoot.path, 'Downloads'),
    );
    final dio = Dio()
      ..httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: _realHttpClient,
      );
    final manager = DownloadManager(
      repository: repository,
      storagePaths: storagePaths,
      dio: dio,
      contentProviders: ContentProviderRegistry(dio: dio),
      maxConcurrent: maxConcurrent,
      maxRetries: maxRetries,
    );
    return DownloadQaHarness._(
      tempRoot: tempRoot,
      database: database,
      repository: repository,
      manager: manager,
      storagePaths: storagePaths,
    );
  }

  Future<void> dispose() async {
    await manager.dispose();
    await database.close();
    if (await tempRoot.exists()) {
      await tempRoot.delete(recursive: true);
    }
  }
}

Future<DownloadTask?> waitForTask(
  DownloadManager manager,
  String id,
  bool Function(DownloadTask? task) predicate, {
  Duration timeout = const Duration(seconds: 8),
}) async {
  final deadline = DateTime.now().add(timeout);
  DownloadTask? last;
  while (DateTime.now().isBefore(deadline)) {
    final matches = manager.tasks.where((task) => task.id == id);
    last = matches.isEmpty ? null : matches.first;
    if (predicate(last)) return last;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  fail(
    'Timed out waiting for $id. last=${last?.status} ${last?.errorMessage}',
  );
}

HttpClient _realHttpClient() {
  HttpOverrides.global = null;
  return HttpClient();
}

void ensureDownloadTestBinding() {
  TestWidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = null;
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
