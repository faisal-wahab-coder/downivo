import 'share_intake.dart';

class StubShareIntake implements ShareIntake {
  @override
  Future<void> start(ShareMediaHandler onMedia) async {}

  @override
  Future<void> reset() async {}

  @override
  Future<void> dispose() async {}
}

ShareIntake createPlatformShareIntake() => StubShareIntake();
