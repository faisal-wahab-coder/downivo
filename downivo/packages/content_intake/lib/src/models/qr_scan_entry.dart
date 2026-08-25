/// A saved QR scan — docs/21
class QrScanEntry {
  const QrScanEntry({
    required this.id,
    required this.rawValue,
    required this.scannedAt,
    this.resolvedUrl,
  });

  final String id;
  final String rawValue;
  final DateTime scannedAt;
  final String? resolvedUrl;

  Map<String, dynamic> toJson() => {
        'id': id,
        'rawValue': rawValue,
        'scannedAt': scannedAt.toIso8601String(),
        'resolvedUrl': resolvedUrl,
      };

  factory QrScanEntry.fromJson(Map<String, dynamic> json) {
    return QrScanEntry(
      id: json['id'] as String,
      rawValue: json['rawValue'] as String,
      scannedAt: DateTime.parse(json['scannedAt'] as String),
      resolvedUrl: json['resolvedUrl'] as String?,
    );
  }
}
