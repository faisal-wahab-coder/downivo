/// Bounded in-memory cache with LRU eviction — docs/12.31 §12–13
class LruMemoryCache<K, V> {
  LruMemoryCache({this.maxEntries = 64});

  final int maxEntries;
  final _entries = <K, V>{};
  final _order = <K>[];

  V? get(K key) {
    if (!_entries.containsKey(key)) return null;
    _touch(key);
    return _entries[key];
  }

  void set(K key, V value) {
    if (_entries.containsKey(key)) {
      _entries[key] = value;
      _touch(key);
      return;
    }

    if (_entries.length >= maxEntries) {
      final oldest = _order.removeAt(0);
      _entries.remove(oldest);
    }

    _entries[key] = value;
    _order.add(key);
  }

  void clear() {
    _entries.clear();
    _order.clear();
  }

  int get size => _entries.length;

  void _touch(K key) {
    _order.remove(key);
    _order.add(key);
  }
}
