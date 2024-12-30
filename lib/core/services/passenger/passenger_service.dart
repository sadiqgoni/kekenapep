import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_user_service.dart';
import '../../constants.dart';

class PassengerService extends BaseUserService {
  Future<Map<String, dynamic>> getPassengerStats() async {
    try {
      final user = currentUser;
      if (user == null) {
        return _getEmptyStats();
      }

      final statsDoc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(user.uid)
          .collection(AppConstants.statisticsCollection)
          .doc('overview')
          .get();

      if (!statsDoc.exists) {
        return _getEmptyStats();
      }

      return statsDoc.data() ?? _getEmptyStats();
    } catch (e) {
      print('Error fetching passenger stats: $e');
      return _getEmptyStats();
    }
  }

  Future<void> submitFare(Map<String, dynamic> fareData) async {
    try {
      final user = currentUser;
      if (user == null) throw Exception('User not authenticated');

      final fareRef = firestore.collection(AppConstants.faresCollection).doc();
      
      await firestore.runTransaction((transaction) async {
        // Create fare submission
        transaction.set(fareRef, {
          ...fareData,
          'userId': user.uid,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Update user stats
        final statsRef = firestore
            .collection(AppConstants.usersCollection)
            .doc(user.uid)
            .collection(AppConstants.statisticsCollection)
            .doc('overview');

        final statsDoc = await transaction.get(statsRef);
        
        if (statsDoc.exists) {
          transaction.update(statsRef, {
            'totalSubmissions': FieldValue.increment(1),
            'pendingSubmissions': FieldValue.increment(1),
            'points': FieldValue.increment(AppConstants.pointsPerSubmission),
          });
        } else {
          transaction.set(statsRef, {
            'totalSubmissions': 1,
            'pendingSubmissions': 1,
            'approvedSubmissions': 0,
            'rejectedSubmissions': 0,
            'points': AppConstants.pointsPerSubmission,
          });
        }
      });
    } catch (e) {
      print('Error submitting fare: $e');
      rethrow;
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
}
