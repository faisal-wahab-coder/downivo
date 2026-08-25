import 'file_store.dart';
import 'file_store_factory_stub.dart'
    if (dart.library.io) 'file_store_factory_io.dart'
    if (dart.library.html) 'file_store_factory_web.dart';

FileStore createFileStore() => createPlatformFileStore();
