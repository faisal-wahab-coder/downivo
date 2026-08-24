/// An open browser tab — docs/18 §11
class BrowserTab {
  const BrowserTab({
    required this.id,
    required this.url,
    this.title = 'New tab',
    this.canGoBack = false,
    this.canGoForward = false,
    this.isLoading = false,
  });

  static const homeUrl = 'udm://home';

  final String id;
  final String url;
  final String title;
  final bool canGoBack;
  final bool canGoForward;
  final bool isLoading;

  bool get isHome => url == homeUrl || url.isEmpty;

  BrowserTab copyWith({
    String? url,
    String? title,
    bool? canGoBack,
    bool? canGoForward,
    bool? isLoading,
  }) {
    return BrowserTab(
      id: id,
      url: url ?? this.url,
      title: title ?? this.title,
      canGoBack: canGoBack ?? this.canGoBack,
      canGoForward: canGoForward ?? this.canGoForward,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}
