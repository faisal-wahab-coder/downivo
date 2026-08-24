/// Application route paths — see docs/09_Navigation_and_Information_Architecture.md
abstract final class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const downloads = '/downloads';
  static const downloadHistory = '/downloads/history';
  static const browser = '/browser';
  static const files = '/files';
  static const settings = '/settings';
  static const permissions = '/permissions';

  static const shellRoutes = [home, downloads, browser, files, settings];
}
