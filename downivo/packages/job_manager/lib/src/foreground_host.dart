abstract class ForegroundHost {
  bool get isSupported;

  Future<void> initialize();

  Future<void> start({
    required String title,
    required String text,
  });

  Future<void> update({
    required String title,
    required String text,
  });

  Future<void> stop();
}
