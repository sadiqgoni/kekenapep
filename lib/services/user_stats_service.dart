import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int POINTS_PER_SUBMISSION = 2;
  static const int BONUS_POINTS_APPROVED = 3;

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return {'points': 0, 'submissions': 0};

      final userDoc = await _firestore.collection('users').doc(userId).get();
      final totalSubmissions = await _firestore.collection('fares').count().get();

      return {
        'points': userDoc.data()?['points'] ?? 0,
        'totalSubmissions': totalSubmissions.count,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {'points': 0, 'submissions': 0};
    }
  }

  Future<void> addPoints(String userId, String type) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      int pointsToAdd = type == 'submission' 
          ? POINTS_PER_SUBMISSION 
          : BONUS_POINTS_APPROVED;

      await userRef.set({
        'points': FieldValue.increment(pointsToAdd),
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding points: $e');
    }
  }
} 