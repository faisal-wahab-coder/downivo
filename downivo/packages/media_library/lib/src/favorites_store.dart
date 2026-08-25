import 'package:shared_preferences/shared_preferences.dart';

/// Persists favorite file paths locally.
class FavoritesStore {
  FavoritesStore(this._prefs);

  static const _key = 'library_favorites';

  final SharedPreferences _prefs;

  Set<String> get paths {
    final raw = _prefs.getStringList(_key);
    if (raw == null) return {};
    return raw.toSet();
  }

  bool isFavorite(String path) => paths.contains(path);

  Future<bool> toggle(String path) async {
    final current = paths.toList();
    if (current.contains(path)) {
      current.remove(path);
    } else {
      current.add(path);
    }
    await _prefs.setStringList(_key, current);
    return current.contains(path);
  }

  Future<void> removeMissing(Iterable<String> existingPaths) async {
    final existing = existingPaths.toSet();
    final kept = paths.where(existing.contains).toList();
    await _prefs.setStringList(_key, kept);
  }
}
