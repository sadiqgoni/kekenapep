import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:keke_fairshare/passenger/models/paginated_routes.dart';
import 'package:keke_fairshare/passenger/services/route_cache_service.dart';
import 'package:keke_fairshare/passenger/services/user_points_service.dart';

class RouteQueryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const int _batchSize = 10;
  static const double _minMatchScore = 80.0;
  static DocumentSnapshot? _lastDocument;

  static Future<PaginatedRoutes> searchRoutes({
    required String source,
    required String destination,
    required List<String> landmarks,
    int page = 0,
    Map<String, dynamic>? filters,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _lastDocument = null;
      }

      // Check cache first if it's the first page and no filters
      if (page == 0 && filters == null && !refresh) {
        final cachedRoutes = RouteCacheService.getCachedRoutes(
          source,
          destination,
          landmarks,
        );

        if (cachedRoutes != null && cachedRoutes.isNotEmpty) {
          print('Using cached routes for $source to $destination');
          return PaginatedRoutes(
            routes: cachedRoutes,
            hasMore: false, // Cached results don't support pagination yet
            currentPage: 0,
            totalItems: cachedRoutes.length,
          );
        }
      }

      // Start with base query
      Query query = _firestore
          .collection('fares')
          .where('status', isEqualTo: 'Approved')
          .orderBy('submittedAt', descending: true);

      // Apply filters if provided
      if (filters != null) {
        if (filters['weatherCondition'] != null) {
          query = query.where('weatherConditions',
              isEqualTo: filters['weatherCondition']);
        }
        if (filters['trafficCondition'] != null) {
          query = query.where('trafficConditions',
              isEqualTo: filters['trafficCondition']);
        }
        if (filters['passengerLoad'] != null) {
          query =
              query.where('passengerLoad', isEqualTo: filters['passengerLoad']);
        }
        if (filters['rushHourStatus'] != null) {
          query = query.where('rushHourStatus',
              isEqualTo: filters['rushHourStatus']);
        }
        if (filters['fromDate'] != null) {
          query = query.where('dateTime',
              isGreaterThanOrEqualTo: filters['fromDate']);
        }
      }

      // Get total count for pagination
      final countSnapshot = await query.count().get();
      final totalItems = countSnapshot.count ?? 0;

      // Apply pagination
      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }
      query = query.limit(_batchSize);

      // Execute query
      final querySnapshot = await query.get();
      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      final routes = querySnapshot.docs
          .map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final submitterId = data['submitter']?['uid'] as String?;

            return {
              ...data,
              'id': doc.id,
              'submitterUid': submitterId ?? '',
              'matchScore': _calculateMatchScore(
                source: source,
                destination: destination,
                landmarks: landmarks,
                routeData: data,
              ),
            };
          })
          .where((route) => route['matchScore'] >= _minMatchScore)
          .toList();

      // Get user points for ranking
      final submitterIds = routes
          .map((route) => route['submitterUid'] as String)
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      final userPoints =
          await UserPointsService.getBatchUserPoints(submitterIds);

      // Sort by match score and user points (weighted combination)
      routes.sort((a, b) {
        final scoreA = a['matchScore'] as double;
        final scoreB = b['matchScore'] as double;

        final pointsA = userPoints[a['submitterUid']] ?? 0;
        final pointsB = userPoints[b['submitterUid']] ?? 0;

        // Normalize points to 0-100 range for fair comparison
        final maxPoints =
            userPoints.values.isEmpty ? 1 : userPoints.values.reduce(max);
        final normalizedPointsA =
            maxPoints > 0 ? (pointsA / maxPoints) * 100 : 0;
        final normalizedPointsB =
            maxPoints > 0 ? (pointsB / maxPoints) * 100 : 0;

        // Weight: 80% match score, 20% user points
        final weightedScoreA = (scoreA * 0.8) + (normalizedPointsA * 0.2);
        final weightedScoreB = (scoreB * 0.8) + (normalizedPointsB * 0.2);

        return weightedScoreB.compareTo(weightedScoreA);
      });

      // Cache the results if it's the first page and no filters
      if (page == 0 && filters == null && routes.isNotEmpty) {
        RouteCacheService.cacheRoutes(source, destination, landmarks, routes);
      }

      return PaginatedRoutes(
        routes: routes,
        hasMore: querySnapshot.docs.length >= _batchSize,
        currentPage: page,
        totalItems: totalItems,
      );
    } catch (e) {
      print('Error searching routes: $e');
      return PaginatedRoutes.initial();
    }
  }

  static double _calculateMatchScore({
    required String source,
    required String destination,
    required List<String> landmarks,
    required Map<String, dynamic> routeData,
  }) {
    double score = 0.0;
    double maxScore = 0.0;

    // Source match (30%)
    maxScore += 30;
    if (_isExactMatch(routeData['source'], source)) {
      score += 30;
    } else if (_isFuzzyMatch(routeData['source'], source)) {
      score += 15;
    }

    // Destination match (30%)
    maxScore += 30;
    if (_isExactMatch(routeData['destination'], destination)) {
      score += 30;
    } else if (_isFuzzyMatch(routeData['destination'], destination)) {
      score += 15;
    }

    // Landmarks match (40%)
    final routeLandmarks = List<String>.from(routeData['routeTaken'] ?? []);
    maxScore += 40;
    double landmarkScore = 0;

    for (final landmark in landmarks) {
      double bestMatch = 0;
      for (final routeLandmark in routeLandmarks) {
        if (_isExactMatch(landmark, routeLandmark)) {
          bestMatch = 1.0;
          break;
        }
        final similarity = _calculateLevenshteinSimilarity(
          landmark.toLowerCase(),
          routeLandmark.toLowerCase(),
        );
        bestMatch = bestMatch < similarity ? similarity : bestMatch;
      }
      landmarkScore += bestMatch;
    }

    // Normalize landmark score to 40%
    if (landmarks.isNotEmpty) {
      score += (landmarkScore / landmarks.length) * 40;
    }

    // Convert to percentage (0-100)
    return maxScore > 0 ? (score / maxScore) * 100 : 0;
  }

  static bool _isExactMatch(String str1, String str2) {
    str1 = str1.toLowerCase().trim();
    str2 = str2.toLowerCase().trim();
    return str1 == str2;
  }

  static bool _isFuzzyMatch(String str1, String str2) {
    str1 = str1.toLowerCase().trim();
    str2 = str2.toLowerCase().trim();

    if (str1.contains(str2) || str2.contains(str1)) {
      return true;
    }

    return _calculateLevenshteinSimilarity(str1, str2) > 0.8;
  }

  static double _calculateLevenshteinSimilarity(String s1, String s2) {
    if (s1.isEmpty) return s2.isEmpty ? 1.0 : 0.0;
    if (s2.isEmpty) return 0.0;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    int maxLength = s1.length > s2.length ? s1.length : s2.length;
    return 1 - (matrix[s1.length][s2.length] / maxLength);
  }
}
