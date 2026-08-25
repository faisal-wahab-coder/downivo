import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/clipboard_entry.dart';

/// Persists recent clipboard detections — docs/19
class ClipboardHistoryStore {
  ClipboardHistoryStore(this._prefs);

  static const _historyKey = 'clipboard_history';
  static const _maxEntries = 50;

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  List<ClipboardEntry> get entries {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ClipboardEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.capturedAt.compareTo(a.capturedAt));
    } on Object {
      return [];
    }
  }

  Future<void> add({
    required String text,
    String? detectedUrl,
  }) async {
    final current = entries
        .where((entry) => entry.text != text)
        .take(_maxEntries - 1)
        .toList();

    current.insert(
      0,
      ClipboardEntry(
        id: _uuid.v4(),
        text: text,
        detectedUrl: detectedUrl,
        capturedAt: DateTime.now(),
      ),
    );

    await _prefs.setString(
      _historyKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> delete(String id) async {
    final kept = entries.where((e) => e.id != id).toList();
    await _prefs.setString(
      _historyKey,
      jsonEncode(kept.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_historyKey);
  }
}
