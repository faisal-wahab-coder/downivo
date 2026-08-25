import 'package:performance/performance.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('TimedCache expires entries after ttl', () async {
    final cache = TimedCache<String, int>(ttl: const Duration(milliseconds: 20));
    cache.set('a', 1);
    expect(cache.get('a'), 1);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(cache.get('a'), isNull);
  });

  test('LruMemoryCache evicts oldest entries', () {
    final cache = LruMemoryCache<String, int>(maxEntries: 2);
    cache.set('a', 1);
    cache.set('b', 2);
    cache.set('c', 3);
    expect(cache.get('a'), isNull);
    expect(cache.get('b'), 2);
    expect(cache.get('c'), 3);
  });

  test('ThrottleGate limits run frequency', () {
    final gate = ThrottleGate(interval: const Duration(milliseconds: 100));
    expect(gate.shouldRun(now: DateTime(2026)), isTrue);
    expect(gate.shouldRun(now: DateTime(2026, 1, 1, 0, 0, 0, 50)), isFalse);
    expect(gate.shouldRun(now: DateTime(2026, 1, 1, 0, 0, 0, 150)), isTrue);
  });

  test('PerformanceManager tracks cache metrics', () {
    final manager = PerformanceManager();
    manager.recordStartup(const Duration(milliseconds: 420));
    manager.recordScan(hit: false);
    manager.recordScan(hit: true);
    expect(manager.metrics()['startup_ms'], 420);
    expect(manager.metrics()['library_scans'], 1);
    expect(manager.metrics()['cache_hits'], 1);
  });
}
