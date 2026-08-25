import 'package:flutter/services.dart';

import 'content_analyzer.dart';
import 'models/detected_content.dart';

/// Reads clipboard in foreground — docs/19 §7
class ClipboardMonitor {
  ClipboardMonitor({ContentAnalyzer? analyzer})
      : _analyzer = analyzer ?? ContentAnalyzer();

  final ContentAnalyzer _analyzer;
  String? _lastFingerprint;

  Future<DetectedContent?> poll({bool force = false}) async {
    ClipboardData? data;
    try {
      data = await Clipboard.getData(Clipboard.kTextPlain);
    } on PlatformException {
      // Chrome blocks clipboard reads without permission / a user gesture.
      return null;
    }
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return null;

    final fingerprint = text.trim();
    if (!force && fingerprint == _lastFingerprint) return null;

    _lastFingerprint = fingerprint;
    final detected = _analyzer.analyzeText(text);
    if (detected.isEmpty) return null;
    return detected;
  }

  void reset() {
    _lastFingerprint = null;
  }
}
