/// Simple TTL cache for expensive synchronous or async computations.
class TimedCache<K, V> {
  TimedCache({this.ttl = const Duration(seconds: 30)});

  final Duration ttl;
  final _entries = <K, _TimedEntry<V>>{};

  V? get(K key) {
    final entry = _entries[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.storedAt) > ttl) {
      _entries.remove(key);
      return null;
    }
    return entry.value;
  }

  void set(K key, V value) {
    _entries[key] = _TimedEntry(value, DateTime.now());
  }

  void clear() {
    _entries.clear();
  }

  int get size => _entries.length;
}

class _TimedEntry<V> {
  _TimedEntry(this.value, this.storedAt);

  final V value;
  final DateTime storedAt;
}
