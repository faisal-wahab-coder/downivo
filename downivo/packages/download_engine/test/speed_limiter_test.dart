import 'package:download_engine/download_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_types/shared_types.dart';

void main() {
  test('unlimited limiter does not delay', () async {
    final delays = <Duration>[];
    final limiter = SpeedLimiter(
      delay: (duration) async {
        delays.add(duration);
      },
    );

    expect(limiter.isActive, isFalse);
    await limiter.acquire(1024 * 1024);

    expect(delays, isEmpty);
  });

  test('token bucket waits for bytes above the per-second cap', () async {
    var now = DateTime(2026, 1, 1);
    final delays = <Duration>[];
    final limiter = SpeedLimiter(
      config: const SpeedLimitConfig(
        enabled: true,
        limitBytesPerSec: 1000,
      ),
      clock: () => now,
      delay: (duration) async {
        delays.add(duration);
        now = now.add(duration);
      },
    );

    await limiter.acquire(1000);
    expect(delays, isEmpty);

    await limiter.acquire(1000);
    final waitedMs = delays.fold<int>(
      0,
      (sum, duration) => sum + duration.inMilliseconds,
    );
    expect(waitedMs, 1000);
  });
}
