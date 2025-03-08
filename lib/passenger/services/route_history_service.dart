import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class RouteHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Local storage keys
  static const String _recentRoutesKey = 'recent_routes';
  static const String _favoriteRoutesKey = 'favorite_routes';
  static const int _maxRecentRoutes = 10;

  // Add a route to history
  static Future<void> addToHistory({
    required String source,
    required String destination,
    required List<String> landmarks,
    required int estimatedFare,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      final timestamp = DateTime.now();

      // Create route data with a copy of landmarks
      final routeData = {
        'source': source,
        'destination': destination,
        'landmarks': List<String>.from(landmarks), // Create a copy
        'estimatedFare': estimatedFare,
        'timestamp': timestamp.toIso8601String(),
      };

      print('Adding to history: $routeData');

      // Save to Firestore if user is logged in
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('routeHistory')
            .add({
          ...routeData,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Saved to Firestore history');
      }

      // Save to local storage
      await _saveToLocalHistory(routeData);
      print('Saved to local history');
    } catch (e) {
      print('Error adding route to history: $e');
    }
  }

  // Get recent routes
  static Future<List<Map<String, dynamic>>> getRecentRoutes() async {
    try {
      final userId = _auth.currentUser?.uid;

      // If user is logged in, get from Firestore
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('routeHistory')
            .orderBy('timestamp', descending: true)
            .limit(_maxRecentRoutes)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Ensure landmarks is a List<String>
          List<String> landmarks = [];
          try {
            landmarks = (data['landmarks'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
          } catch (e) {
            print('Error converting landmarks: $e');
          }

          return {
            'id': doc.id,
            'source': data['source'] ?? '',
            'destination': data['destination'] ?? '',
            'landmarks': landmarks,
            'estimatedFare': data['estimatedFare'] ?? 0,
            'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
          };
        }).toList();
      }

      // Otherwise get from local storage
      return await _getLocalHistory();
    } catch (e) {
      print('Error getting recent routes: $e');
      return [];
    }
  }

  // Add a route to favorites
  static Future<void> addToFavorites({
    required String source,
    required String destination,
    required List<String> landmarks,
    String? name,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      final timestamp = DateTime.now();

      // Create favorite data with a copy of landmarks
      final favoriteData = {
        'source': source,
        'destination': destination,
        'landmarks': List<String>.from(landmarks), // Create a copy
        'name': name ?? '$source to $destination',
        'timestamp': timestamp.toIso8601String(),
      };

      print('Adding to favorites: $favoriteData');

      // Save to Firestore if user is logged in
      if (userId != null) {
        final docRef = await _firestore
            .collection('users')
            .doc(userId)
            .collection('favoriteRoutes')
            .add({
          ...favoriteData,
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('Saved to Firestore favorites with ID: ${docRef.id}');

        // Add the ID to the local data
        favoriteData['id'] = docRef.id;
      }

      // Save to local storage
      await _saveToLocalFavorites(favoriteData);
      print('Saved to local favorites');
    } catch (e) {
      print('Error adding route to favorites: $e');
      rethrow; // Rethrow to allow handling in UI
    }
  }

  // Get favorite routes
  static Future<List<Map<String, dynamic>>> getFavoriteRoutes() async {
    try {
      final userId = _auth.currentUser?.uid;

      // If user is logged in, get from Firestore
      if (userId != null) {
        final snapshot = await _firestore
            .collection('users')
            .doc(userId)
            .collection('favoriteRoutes')
            .orderBy('timestamp', descending: true)
            .get();

        return snapshot.docs.map((doc) {
          final data = doc.data();
          // Ensure landmarks is a List<String>
          List<String> landmarks = [];
          try {
            landmarks = (data['landmarks'] as List?)
                    ?.map((e) => e.toString())
                    .toList() ??
                [];
          } catch (e) {
            print('Error converting landmarks: $e');
          }

          return {
            'id': doc.id,
            'source': data['source'] ?? '',
            'destination': data['destination'] ?? '',
            'landmarks': landmarks,
            'name':
                data['name'] ?? '${data['source']} to ${data['destination']}',
            'timestamp': data['timestamp'] ?? FieldValue.serverTimestamp(),
          };
        }).toList();
      }

      // Otherwise get from local storage
      return await _getLocalFavorites();
    } catch (e) {
      print('Error getting favorite routes: $e');
      return [];
    }
  }

  // Remove from favorites
  static Future<void> removeFromFavorites(String id) async {
    try {
      final userId = _auth.currentUser?.uid;

      // Remove from Firestore if user is logged in
      if (userId != null) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favoriteRoutes')
            .doc(id)
            .delete();
      }

      // Remove from local storage
      await _removeFromLocalFavorites(id);
    } catch (e) {
      print('Error removing route from favorites: $e');
    }
  }

  // Save to local history
  static Future<void> _saveToLocalHistory(
      Map<String, dynamic> routeData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentRoutes = await _getLocalHistory();

      // Add new route at the beginning
      recentRoutes.insert(0, routeData);

      // Keep only the most recent routes
      if (recentRoutes.length > _maxRecentRoutes) {
        recentRoutes.removeRange(_maxRecentRoutes, recentRoutes.length);
      }

      // Save back to shared preferences
      final jsonString = jsonEncode(recentRoutes);
      await prefs.setString(_recentRoutesKey, jsonString);
      print('Saved to local history: ${recentRoutes.length} routes');
    } catch (e) {
      print('Error saving to local history: $e');
    }
  }

  // Get local history
  static Future<List<Map<String, dynamic>>> _getLocalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentRoutesJson = prefs.getString(_recentRoutesKey);

      if (recentRoutesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(recentRoutesJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error getting local history: $e');
      return [];
    }
  }

  // Save to local favorites
  static Future<void> _saveToLocalFavorites(
      Map<String, dynamic> favoriteData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getLocalFavorites();

      // Generate a local ID if not present
      if (!favoriteData.containsKey('id')) {
        favoriteData['id'] = 'local_${DateTime.now().millisecondsSinceEpoch}';
      }

      // Add new favorite
      favorites.add(favoriteData);

      // Save back to shared preferences
      final jsonString = jsonEncode(favorites);
      await prefs.setString(_favoriteRoutesKey, jsonString);
      print('Saved to local favorites: ${favorites.length} routes');
    } catch (e) {
      print('Error saving to local favorites: $e');
      rethrow; // Rethrow to allow handling in UI
    }
  }

  // Get local favorites
  static Future<List<Map<String, dynamic>>> _getLocalFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getString(_favoriteRoutesKey);

      if (favoritesJson == null) return [];

      final List<dynamic> decoded = jsonDecode(favoritesJson);
      return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
    } catch (e) {
      print('Error getting local favorites: $e');
      return [];
    }
  }

  // Remove from local favorites
  static Future<void> _removeFromLocalFavorites(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await _getLocalFavorites();

      // Remove the favorite with matching ID
      favorites.removeWhere((favorite) => favorite['id'] == id);

      // Save back to shared preferences
      await prefs.setString(_favoriteRoutesKey, jsonEncode(favorites));
    } catch (e) {
      print('Error removing from local favorites: $e');
    }
  }

  // Sync local data with Firestore when user logs in
  static Future<void> syncWithFirestore() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Sync history
      final localHistory = await _getLocalHistory();
      for (final route in localHistory) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('routeHistory')
            .add({
          ...route,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }

      // Sync favorites
      final localFavorites = await _getLocalFavorites();
      for (final favorite in localFavorites) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('favoriteRoutes')
            .add({
          ...favorite,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error syncing with Firestore: $e');
    }
  }
}
