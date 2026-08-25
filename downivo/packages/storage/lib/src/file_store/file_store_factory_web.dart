import 'file_store.dart';
import 'web_file_store.dart';

FileStore createPlatformFileStore() => WebFileStore();
