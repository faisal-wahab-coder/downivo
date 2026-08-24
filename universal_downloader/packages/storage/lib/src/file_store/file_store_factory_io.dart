import 'file_store.dart';
import 'io_file_store.dart';

FileStore createPlatformFileStore() => IoFileStore();
