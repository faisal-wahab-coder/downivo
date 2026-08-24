import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const UniversalDownloaderApp(),
    ),
  );
}
