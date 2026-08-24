import 'foreground_host.dart';

class StubForegroundHost implements ForegroundHost {
  @override
  bool get isSupported => false;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> start({
    required String title,
    required String text,
  }) async {}

  @override
  Future<void> update({
    required String title,
    required String text,
  }) async {}

  @override
  Future<void> stop() async {}
}

ForegroundHost createPlatformForegroundHost() => StubForegroundHost();
