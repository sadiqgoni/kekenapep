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
      if (user == null) {
        return _getEmptyStats();
      }

      final statsDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('statistics')
          .doc('overview')
          .get();

      if (!statsDoc.exists) {
        return _getEmptyStats();
      }

      return {
        'points': statsDoc.data()?['points'] ?? 0,
        'totalSubmissions': statsDoc.data()?['totalSubmissions'] ?? 0,
        'approvedSubmissions': statsDoc.data()?['approvedSubmissions'] ?? 0,
        'rejectedSubmissions': statsDoc.data()?['rejectedSubmissions'] ?? 0,
        'pendingSubmissions': statsDoc.data()?['pendingSubmissions'] ?? 0,
      };
    } catch (e) {
      print('Error fetching user stats: $e');
      return _getEmptyStats();
    }
  }

  Map<String, dynamic> _getEmptyStats() {
    return {
      'points': 0,
      'totalSubmissions': 0,
      'approvedSubmissions': 0,
      'rejectedSubmissions': 0,
      'pendingSubmissions': 0,
    };
  }

  Future<void> addPoints(String userId, String type) async {
    try {
      final statsRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('statistics')
          .doc('overview');

      // Use a transaction to safely update multiple fields
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(statsRef);
        
        // Initialize stats if they don't exist
        if (!snapshot.exists) {
          transaction.set(statsRef, _getEmptyStats());
        }

        final data = snapshot.exists ? snapshot.data()! : _getEmptyStats();
        
        // Calculate points and update counters
        final currentPoints = data['points'] ?? 0;
        final pointsToAdd = type == 'submission' 
            ? POINTS_PER_SUBMISSION 
            : BONUS_POINTS_APPROVED;

        Map<String, dynamic> updateData = {
          'points': currentPoints + pointsToAdd,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update submission counters based on type
        if (type == 'submission') {
          updateData['totalSubmissions'] = (data['totalSubmissions'] ?? 0) + 1;
          updateData['pendingSubmissions'] = (data['pendingSubmissions'] ?? 0) + 1;
          updateData['lastSubmissionAt'] = FieldValue.serverTimestamp();
        } else if (type == 'approved') {
          updateData['approvedSubmissions'] = (data['approvedSubmissions'] ?? 0) + 1;
          updateData['pendingSubmissions'] = (data['pendingSubmissions'] ?? 0) - 1;
        }

        transaction.set(statsRef, updateData, SetOptions(merge: true));

        // Add activity log
        final activityRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .doc();

        final activityData = {
          'type': type == 'submission' ? 'SUBMISSION_CREATED' : 'SUBMISSION_APPROVED',
          'points': pointsToAdd,
          'currentPoints': currentPoints + pointsToAdd,
          'pointsAdded': pointsToAdd,
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'currentPoints': currentPoints + pointsToAdd,
            'pointsAdded': pointsToAdd,
            'points': pointsToAdd,
            'timestamp': FieldValue.serverTimestamp(),
            'type': type == 'submission' ? 'SUBMISSION_CREATED' : 'SUBMISSION_APPROVED',
          }
        };

        transaction.set(activityRef, activityData);
      });

    } catch (e) {
      print('Error updating points: $e');
      rethrow;
    }
  }

  Future<void> refreshUserStats(String userId) async {
    try {
      final userRef = _firestore.collection('users').doc(userId);
      
      // Get all submissions for the user
      final submissionsQuery = await userRef.collection('submissions').get();
      
      // Count submissions by status
      int totalSubmissions = submissionsQuery.docs.length;
      int approvedSubmissions = 0;
      int rejectedSubmissions = 0;
      int pendingSubmissions = 0;
      
      for (var doc in submissionsQuery.docs) {
        String status = doc.data()['status'] ?? 'pending';
        switch (status.toLowerCase()) {
          case 'approved':
            approvedSubmissions++;
            break;
          case 'rejected':
            rejectedSubmissions++;
            break;
          default:
            pendingSubmissions++;
        }
      }

      // Calculate total points
      int totalPoints = (totalSubmissions * POINTS_PER_SUBMISSION) +
          (approvedSubmissions * BONUS_POINTS_APPROVED);

      // Update statistics
      await userRef.collection('statistics').doc('overview').update({
        'points': totalPoints,
        'totalSubmissions': totalSubmissions,
        'approvedSubmissions': approvedSubmissions,
        'rejectedSubmissions': rejectedSubmissions,
        'pendingSubmissions': pendingSubmissions,
        'updatedAt': FieldValue.serverTimestamp(),
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
      final statsRef = userRef.collection('statistics').doc('overview');
      final snapshot = await statsRef.get();

      if (!snapshot.exists) {
        await statsRef.set({
          'points': 0,
          'totalSubmissions': 0,
          'approvedSubmissions': 0,
          'rejectedSubmissions': 0,
          'pendingSubmissions': 0,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error initializing user stats: $e');
      rethrow;
    }
  }
}
