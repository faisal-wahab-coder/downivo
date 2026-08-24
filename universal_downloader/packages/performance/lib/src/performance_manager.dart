import 'lru_memory_cache.dart';
import 'timed_cache.dart';

/// Central performance metrics and cache management — docs/12.31 §30
class PerformanceManager {
  PerformanceManager({
    TimedCache<String, Object>? scanCache,
    LruMemoryCache<String, Object>? imageCache,
  })  : scanCache = scanCache ?? TimedCache<String, Object>(),
        imageCache = imageCache ?? LruMemoryCache<String, Object>(maxEntries: 48);

  final TimedCache<String, Object> scanCache;
  final LruMemoryCache<String, Object> imageCache;

  int startupMillis = 0;
  int libraryScans = 0;
  int cacheHits = 0;
  int cacheMisses = 0;

  void recordStartup(Duration duration) {
    startupMillis = duration.inMilliseconds;
  }

  void recordScan({required bool hit}) {
    if (hit) {
      cacheHits++;
    } else {
      cacheMisses++;
      libraryScans++;
    }
  }

  Map<String, int> metrics() => {
        'startup_ms': startupMillis,
        'library_scans': libraryScans,
        'cache_hits': cacheHits,
        'cache_misses': cacheMisses,
        'scan_cache_entries': scanCache.size,
        'image_cache_entries': imageCache.size,
      };

  void clearCaches() {
    scanCache.clear();
    imageCache.clear();
  }
}
