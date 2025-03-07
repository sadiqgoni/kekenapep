import 'dart:collection';
import 'package:cloud_firestore/cloud_firestore.dart';

class RouteCacheService {
  // LRU cache with maximum of 50 entries
  static final _cache = LinkedHashMap<String, _CacheEntry>();
  static const int _maxEntries = 50;
  static const Duration _cacheDuration = Duration(minutes: 30);

  // Generate cache key from search parameters
  static String _generateCacheKey(
      String source, String destination, List<String> landmarks) {
    final sortedLandmarks = [...landmarks]..sort();
    return '$source|$destination|${sortedLandmarks.join('|')}';
  }

  // Check if cache entry is valid
  static bool _isValidEntry(_CacheEntry entry) {
    return DateTime.now().difference(entry.timestamp) < _cacheDuration;
  }

  // Get cached routes if available
  static List<Map<String, dynamic>>? getCachedRoutes(
    String source,
    String destination,
    List<String> landmarks,
  ) {
    final key = _generateCacheKey(source, destination, landmarks);
    final entry = _cache[key];

    if (entry != null && _isValidEntry(entry)) {
      // Move to end (most recently used)
      _cache.remove(key);
      _cache[key] = entry;
      return entry.routes;
    }

    return null;
  }

  // Cache routes
  static void cacheRoutes(
    String source,
    String destination,
    List<String> landmarks,
    List<Map<String, dynamic>> routes,
  ) {
    final key = _generateCacheKey(source, destination, landmarks);

    // Remove oldest entry if cache is full
    if (_cache.length >= _maxEntries) {
      _cache.remove(_cache.keys.first);
    }

    // Add new entry
    _cache[key] = _CacheEntry(
      routes: routes,
      timestamp: DateTime.now(),
    );
  }

  // Clear expired entries
  static void clearExpiredEntries() {
    _cache.removeWhere((key, entry) => !_isValidEntry(entry));
  }

  // Clear entire cache
  static void clearCache() {
    _cache.clear();
  }
}

class _CacheEntry {
  final List<Map<String, dynamic>> routes;
  final DateTime timestamp;

  _CacheEntry({
    required this.routes,
    required this.timestamp,
  });
}
