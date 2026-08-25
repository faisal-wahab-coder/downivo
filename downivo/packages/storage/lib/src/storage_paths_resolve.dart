import 'storage_paths.dart';
import 'storage_paths_resolve_stub.dart'
    if (dart.library.io) 'storage_paths_resolve_io.dart'
    if (dart.library.html) 'storage_paths_resolve_web.dart';

Future<StoragePaths> resolveStoragePaths() => resolvePlatformStoragePaths();
