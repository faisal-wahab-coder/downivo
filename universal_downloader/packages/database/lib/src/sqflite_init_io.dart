import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<void> initializeSqflite() async {}

Future<String> databaseFilePath() async {
  final dir = await getApplicationDocumentsDirectory();
  return p.join(dir.path, 'universal_downloader.db');
}
