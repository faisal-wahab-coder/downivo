import 'package:app_core/src/observability/analytics_route_observer.dart';
import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps routes to analytics screens', () {
    expect(screenNameForLocation('/home'), AnalyticsScreen.home);
    expect(screenNameForLocation('/downloads'), AnalyticsScreen.downloads);
    expect(
      screenNameForLocation('/downloads/history'),
      AnalyticsScreen.history,
    );
    expect(screenNameForLocation('/settings'), AnalyticsScreen.settings);
    expect(screenNameForLocation('/onboarding'), AnalyticsScreen.onboarding);
  });
}
