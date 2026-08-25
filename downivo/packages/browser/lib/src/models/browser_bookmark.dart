/// A saved bookmark — docs/18, docs/10.5 §8
class BrowserBookmark {
  const BrowserBookmark({
    required this.id,
    required this.url,
    required this.title,
    required this.createdAt,
  });

  final String id;
  final String url;
  final String title;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'url': url,
        'title': title,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BrowserBookmark.fromJson(Map<String, dynamic> json) {
    return BrowserBookmark(
      id: json['id'] as String,
      url: json['url'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
