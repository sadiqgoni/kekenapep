import 'package:cloud_firestore/cloud_firestore.dart';

class UserPointsService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, _CachedPoints> _pointsCache = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

  // Get points for multiple users in a single batch
  static Future<Map<String, int>> getBatchUserPoints(
      List<String> userIds) async {
    if (userIds.isEmpty) return {};

    // Check cache first
    final now = DateTime.now();
    final Map<String, int> results = {};
    final List<String> idsToFetch = [];

    // Get cached values and collect IDs that need fetching
    for (final userId in userIds) {
      final cached = _pointsCache[userId];
      if (cached != null && now.difference(cached.timestamp) < _cacheDuration) {
        results[userId] = cached.points;
      } else {
        idsToFetch.add(userId);
      }
    }

    // If all results were cached, return immediately
    if (idsToFetch.isEmpty) return results;

    // Batch get the remaining user points
    try {
      final futures = idsToFetch.map((uid) => _firestore
          .collection('users')
          .doc(uid)
          .collection('statistics')
          .doc('overview')
          .get());

      final snapshots = await Future.wait(futures);

      for (var i = 0; i < snapshots.length; i++) {
        final userId = idsToFetch[i];
        final points = (snapshots[i].data()?['points'] as num?)?.toInt() ?? 0;

        // Update cache
        _pointsCache[userId] = _CachedPoints(
          points: points,
          timestamp: now,
        );

        results[userId] = points;
      }

      return results;
    } catch (e) {
      print('Error fetching batch user points: $e');
      return {};
    }
  }

  // Clear expired cache entries
  static void clearExpiredCache() {
    final now = DateTime.now();
    _pointsCache.removeWhere(
      (_, cached) => now.difference(cached.timestamp) >= _cacheDuration,
    );
  }

  // Clear entire cache
  static void clearCache() {
    _pointsCache.clear();
  }
}

class _CachedPoints {
  final int points;
  final DateTime timestamp;

  _CachedPoints({
    required this.points,
    required this.timestamp,
  });
}
