import 'package:database/database.dart';
import 'package:download_engine/download_engine.dart';
import 'package:permissions/permissions.dart';
import 'package:storage/storage.dart';

/// Initializes database and storage during onboarding / first launch.
class AppInitializer {
  AppInitializer({
    DatabaseProvider? databaseProvider,
    StorageInitializer? storageInitializer,
    PermissionService? permissionService,
    FileStore? fileStore,
  }) : this._(
          fileStore: fileStore ?? createFileStore(),
          databaseProvider: databaseProvider ?? DatabaseProvider(),
          permissionService: permissionService ?? PermissionService(),
          storageInitializer: storageInitializer,
        );

  AppInitializer._({
    required FileStore fileStore,
    required DatabaseProvider databaseProvider,
    required PermissionService permissionService,
    StorageInitializer? storageInitializer,
  })  : _fileStore = fileStore,
        _databaseProvider = databaseProvider,
        _permissionService = permissionService,
        _storageInitializer =
            storageInitializer ?? StorageInitializer(fileStore: fileStore);

  final FileStore _fileStore;
  final DatabaseProvider _databaseProvider;
  final StorageInitializer _storageInitializer;
  final PermissionService _permissionService;

  DownloadManager? _downloadManager;

  FileStore get fileStore => _fileStore;
  DatabaseProvider get databaseProvider => _databaseProvider;
  PermissionService get permissionService => _permissionService;
  AppDatabase get appDatabase => _databaseProvider.database;

  StoragePaths? _paths;
  StoragePaths? get storagePaths => _paths;

  Future<StoragePaths> initialize() async {
    await _fileStore.initialize();
    await _databaseProvider.initialize();
    _paths = await _storageInitializer.initialize();
    return _paths!;
  }

  Future<DownloadManager> createDownloadManager(
    StoragePaths paths, {
    bool restoreTasks = true,
  }) async {
    final manager = DownloadManager(
      repository: DownloadRepository(_databaseProvider.database),
      storagePaths: paths,
      fileStore: _fileStore,
    );
    if (restoreTasks) {
      await manager.loadFromDatabase();
    }
    _downloadManager = manager;
    return manager;
  }

  DownloadManager? get downloadManager => _downloadManager;

  Future<PermissionResult> requestPermission(AppPermission permission) {
    return _permissionService.request(permission);
  }

  Future<void> dispose() async {
    await _downloadManager?.dispose();
    await _databaseProvider.close();
  }
}
