import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Tracks known library paths to surface newly added files — FR-035
class ImportTracker {
  ImportTracker(this._prefs);

  static const _knownPathsKey = 'library_known_paths';

  final SharedPreferences _prefs;

  Set<String> get knownPaths {
    final raw = _prefs.getString(_knownPathsKey);
    if (raw == null) return {};
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e as String).toSet();
    } on Object {
      return {};
    }
  }

  Future<void> rememberPaths(Iterable<String> paths) async {
    final merged = {...knownPaths, ...paths};
    await _prefs.setString(_knownPathsKey, jsonEncode(merged.toList()));
  }

  Future<void> acknowledgePaths(Iterable<String> paths) {
    return rememberPaths(paths);
  }
}
