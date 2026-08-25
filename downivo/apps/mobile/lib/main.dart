import 'package:app_core/app_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  FlutterForegroundTask.initCommunicationPort();

  final container = await bootstrap();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: WithForegroundTask(
        child: const DownivoApp(),
      ),
    ),
  );
}
