import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'models/qr_scan_entry.dart';

/// Persists QR scan history — docs/21
class QrHistoryStore {
  QrHistoryStore(this._prefs);

  static const _historyKey = 'qr_scan_history';
  static const _maxEntries = 100;

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  List<QrScanEntry> get entries {
    final raw = _prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => QrScanEntry.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    } on Object {
      return [];
    }
  }

  Future<void> add({
    required String rawValue,
    String? resolvedUrl,
  }) async {
    final current = entries.take(_maxEntries - 1).toList();
    current.insert(
      0,
      QrScanEntry(
        id: _uuid.v4(),
        rawValue: rawValue,
        scannedAt: DateTime.now(),
        resolvedUrl: resolvedUrl,
      ),
    );

    await _prefs.setString(
      _historyKey,
      jsonEncode(current.map((e) => e.toJson()).toList()),
    );
  }

  Future<void> clear() async {
    await _prefs.remove(_historyKey);
  }
}
