import 'file_store.dart';
import 'memory_file_store.dart';

FileStore createPlatformFileStore() => MemoryFileStore();
