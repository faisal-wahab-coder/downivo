import 'sqflite_init_stub.dart'
    if (dart.library.io) 'sqflite_init_io.dart'
    if (dart.library.html) 'sqflite_init_web.dart';

Future<void> ensureSqfliteInitialized() => initializeSqflite();

Future<String> resolveDatabasePath() => databaseFilePath();
