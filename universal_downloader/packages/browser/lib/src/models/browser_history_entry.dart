/// A visited page record — docs/18 §16
class BrowserHistoryEntry {
  const BrowserHistoryEntry({
    required this.id,
    required this.url,
    required this.title,
    required this.visitedAt,
  });

  final String id;
  final String url;
  final String title;
  final DateTime visitedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'visitedAt': visitedAt.toIso8601String(),
      };

  factory BrowserHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BrowserHistoryEntry(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      visitedAt: DateTime.parse(json['visitedAt'] as String),
    );
  }
}
