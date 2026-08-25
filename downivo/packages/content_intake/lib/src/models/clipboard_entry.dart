/// A clipboard history record — docs/19
class ClipboardEntry {
  const ClipboardEntry({
    required this.id,
    required this.text,
    required this.detectedUrl,
    required this.capturedAt,
  });

  final String id;
  final String text;
  final String? detectedUrl;
  final DateTime capturedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'detectedUrl': detectedUrl,
        'capturedAt': capturedAt.toIso8601String(),
      };

  factory ClipboardEntry.fromJson(Map<String, dynamic> json) {
    return ClipboardEntry(
      id: json['id'] as String,
      text: json['text'] as String,
      detectedUrl: json['detectedUrl'] as String?,
      capturedAt: DateTime.parse(json['capturedAt'] as String),
    );
  }
}
