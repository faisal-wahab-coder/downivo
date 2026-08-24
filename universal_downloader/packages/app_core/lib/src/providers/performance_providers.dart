import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:performance/performance.dart';

final performanceManagerProvider = Provider<PerformanceManager>((ref) {
  return PerformanceManager();
});

final performanceMetricsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(performanceManagerProvider).metrics();
});
