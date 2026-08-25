import 'package:analytics/analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.disabled();
});

final remoteAppConfigProvider = Provider<RemoteAppConfig>((ref) {
  return ref.watch(analyticsServiceProvider).remote;
});
