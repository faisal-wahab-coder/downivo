/// Limits how often an action may run — docs/12.31
class ThrottleGate {
  ThrottleGate({this.interval = const Duration(milliseconds: 250)});

  final Duration interval;
  DateTime? _lastRun;

  bool shouldRun({DateTime? now}) {
    final tick = now ?? DateTime.now();
    final last = _lastRun;
    if (last != null && tick.difference(last) < interval) {
      return false;
    }
    _lastRun = tick;
    return true;
  }

  void reset() {
    _lastRun = null;
  }
}
