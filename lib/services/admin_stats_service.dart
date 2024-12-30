import 'package:cloud_firestore/cloud_firestore.dart';

class AdminStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      // Get total users count
      final usersCount = await _firestore.collection('users').count().get();
      
      // Get submissions statistics
      final submissions = await _firestore.collection('fares').get();
      int totalSubmissions = submissions.size;
      int approvedSubmissions = 0;
      int pendingSubmissions = 0;
      int rejectedSubmissions = 0;

      for (var doc in submissions.docs) {
        String status = doc.data()['status'] ?? 'pending';
        switch (status.toLowerCase()) {
          case 'approved':
            approvedSubmissions++;
            break;
          case 'pending':
            pendingSubmissions++;
            break;
          case 'rejected':
            rejectedSubmissions++;
            break;
        }
      }

      return {
        'totalUsers': usersCount.count,
        'totalSubmissions': totalSubmissions,
        'approvedSubmissions': approvedSubmissions,
        'pendingSubmissions': pendingSubmissions,
        'rejectedSubmissions': rejectedSubmissions,
      };
    } catch (e) {
      print('Error fetching admin stats: $e');
      return {
        'totalUsers': 0,
        'totalSubmissions': 0,
        'approvedSubmissions': 0,
        'pendingSubmissions': 0,
        'rejectedSubmissions': 0,
      };
    }
  }
}
