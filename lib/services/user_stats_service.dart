// ignore_for_file: constant_identifier_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const int POINTS_PER_SUBMISSION = 2;
  static const int BONUS_POINTS_APPROVED = 3;

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {'points': 0, 'totalSubmissions': 0, 'approvedSubmissions': 0};

      final docSnapshot =
          await _firestore.collection('users').doc(user.uid).get();

      // Ensure both points and totalSubmissions are initialized
      return {
        'points': docSnapshot.data()?['points'] ?? 0,
        'totalSubmissions': docSnapshot.data()?['totalSubmissions'] ?? 0,
        'approvedSubmissions': docSnapshot.data()?['approvedSubmissions'] ?? 0,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return {
        'points': 0,
        'totalSubmissions': 0,
        'approvedSubmissions': 0,
      };
    }
  }

  Future<void> addPoints(String userId, String type) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);

      // Use a transaction to safely update multiple fields
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(userRef);
        if (!snapshot.exists) {
          throw 'User document not found';
        }

        // Get current values or default to 0
        final currentPoints = snapshot.data()?['points'] ?? 0;
        final currentSubmissions = snapshot.data()?['totalSubmissions'] ?? 0;
        final currentApprovedSubmissions = snapshot.data()?['approvedSubmissions'] ?? 0;

        // Calculate points based on type
        int pointsToAdd = type == 'submission'
            ? POINTS_PER_SUBMISSION
            : BONUS_POINTS_APPROVED;

        // Create update map
        Map<String, dynamic> updateData = {
          'points': currentPoints + pointsToAdd,
          'lastUpdated': FieldValue.serverTimestamp(),
        };

        // Update appropriate counters based on type
        if (type == 'submission') {
          updateData['totalSubmissions'] = currentSubmissions + 1;
        } else if (type == 'approved') {
          updateData['approvedSubmissions'] = currentApprovedSubmissions + 1;
        }

        // Update the document
        transaction.update(userRef, updateData);
      });
    } catch (e) {
      print('Error adding points: $e');
      rethrow;
    }
  }

  Future<void> refreshUserStats(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final submissionsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('submissions');

      // Get the total number of submissions
      final submissionsCount = await submissionsRef.count().get();

      // Update the user document with the accurate count
      await userRef.update({
        'totalSubmissions': submissionsCount.count,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error refreshing user stats: $e');
      rethrow;
    }
  }

  // Optional: Method to initialize user stats if not exists
  Future<void> initializeUserStats(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      final snapshot = await userRef.get();

      if (!snapshot.exists) {
        await userRef.set({
          'points': 0,
          'totalSubmissions': 0,
          'approvedSubmissions': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing user stats: $e');
      rethrow;
    }
  }
}
