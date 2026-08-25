import 'app_database.dart';

class DatabaseProvider {
  DatabaseProvider({AppDatabase? database})
    : database = database ?? AppDatabase();

  final AppDatabase database;

  Future<void> initialize() async {
    await database.markInitialized();
  }

  Future<void> close() => database.close();
}
