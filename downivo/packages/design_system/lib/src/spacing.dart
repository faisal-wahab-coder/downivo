/// 4px spacing scale from the Zfile design system.
///
/// Named steps keep their existing call-site meaning:
/// xs 4, sm 8, md 12, lg 16, xl 20, xxl 24, xxxl 32, huge 40.
abstract final class UdmSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 48;
  static const double giant = 64;

  static const double screenPadding = lg;
  static const double cardPadding = lg;
  static const double cardPaddingLarge = xl;
  static const double gridGap = md;
  static const double listItemGap = md;
  static const double sectionSpacing = xxl;
  static const double bottomNavHeight = 64;
  static const double topNavHeight = 56;
}

/// Corner radii from the Zfile design system.
abstract final class UdmRadius {
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 20;
  static const double xl = 28;
  static const double card = 16;
  static const double stat = 24;
  static const double hero = 28;
  static const double tile = 18;
  static const double icon = 14;
  static const double button = 999;
  static const double sheet = 28;
  static const double thumbnail = 16;
  static const double navActive = 16;
}
