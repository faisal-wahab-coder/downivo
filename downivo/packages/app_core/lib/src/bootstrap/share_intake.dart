import 'package:content_intake/content_intake.dart';

typedef ShareMediaHandler = Future<void> Function(SharePayload payload);

abstract class ShareIntake {
  Future<void> start(ShareMediaHandler onMedia);
  Future<void> reset();
  Future<void> dispose();
}
