import 'package:shared_preferences/shared_preferences.dart';

class RecentSearches {
  RecentSearches(this._prefs);

  static const _key = 'recent_searches';
  static const _limit = 8;

  final SharedPreferences _prefs;

  List<String> read() {
    return _prefs.getStringList(_key) ?? const [];
  }

  Future<List<String>> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return read();
    final next = [
      trimmed,
      ...read().where((item) => item.toLowerCase() != trimmed.toLowerCase()),
    ].take(_limit).toList();
    await _prefs.setStringList(_key, next);
    return next;
  }

  Future<void> clear() => _prefs.remove(_key);
}
