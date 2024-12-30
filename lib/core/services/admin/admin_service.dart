import 'package:cloud_firestore/cloud_firestore.dart';
import '../base_user_service.dart';
import '../../constants.dart';

class AdminService extends BaseUserService {
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = currentUser;
      if (user == null) return false;
      
      return user.email == AppConstants.adminEmail;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<List<Map<String, dynamic>>> getPendingSubmissions() async {
    try {
      final querySnapshot = await firestore
          .collection(AppConstants.faresCollection)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      print('Error fetching pending submissions: $e');
      return [];
    }
  }

  Future<void> reviewSubmission(String submissionId, bool approved, String? comment) async {
    try {
      final submissionRef = firestore
          .collection(AppConstants.faresCollection)
          .doc(submissionId);

      final submission = await submissionRef.get();
      if (!submission.exists) throw Exception('Submission not found');

      final userId = submission.data()?['userId'];
      if (userId == null) throw Exception('Invalid submission data');

      final userStatsRef = firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection(AppConstants.statisticsCollection)
          .doc('overview');

      await firestore.runTransaction((transaction) async {
        // Update submission status
        transaction.update(submissionRef, {
          'status': approved ? 'approved' : 'rejected',
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': currentUser?.uid,
          if (comment != null) 'reviewComment': comment,
        });

        // Update user stats
        transaction.update(userStatsRef, {
          'pendingSubmissions': FieldValue.increment(-1),
          approved ? 'approvedSubmissions' : 'rejectedSubmissions': FieldValue.increment(1),
          if (approved) 'points': FieldValue.increment(AppConstants.bonusPointsApproved),
        });
      });
    } catch (e) {
      print('Error reviewing submission: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getAdminDashboardStats() async {
    try {
      final stats = await Future.wait([
        firestore.collection(AppConstants.faresCollection)
            .where('status', isEqualTo: 'pending').count().get(),
        firestore.collection(AppConstants.faresCollection)
            .where('status', isEqualTo: 'approved').count().get(),
        firestore.collection(AppConstants.faresCollection)
            .where('status', isEqualTo: 'rejected').count().get(),
        firestore.collection(AppConstants.usersCollection).count().get(),
      ]);

      return {
        'pendingSubmissions': stats[0].count,
        'approvedSubmissions': stats[1].count,
        'rejectedSubmissions': stats[2].count,
        'totalUsers': stats[3].count,
      };
    } catch (e) {
      print('Error fetching admin dashboard stats: $e');
      return {
        'pendingSubmissions': 0,
        'approvedSubmissions': 0,
        'rejectedSubmissions': 0,
        'totalUsers': 0,
      };
    }
  }
}
