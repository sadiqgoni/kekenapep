// ignore_for_file: non_constant_identifier_names

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
      int ApprovedSubmissions = 0;
      int PendingSubmissions = 0;
      int RejectedSubmissions = 0;

      for (var doc in submissions.docs) {
        String status = doc.data()['status'] ?? 'Pending';
        switch (status.toLowerCase()) {
          case 'Approved':
            ApprovedSubmissions++;
            break;
          case 'Pending':
            PendingSubmissions++;
            break;
          case 'Rejected':
            RejectedSubmissions++;
            break;
        }
      }

      return {
        'totalUsers': usersCount.count,
        'totalSubmissions': totalSubmissions,
        'ApprovedSubmissions': ApprovedSubmissions,
        'PendingSubmissions': PendingSubmissions,
        'RejectedSubmissions': RejectedSubmissions,
      };
    } catch (e) {
      print('Error fetching admin stats: $e');
      return {
        'totalUsers': 0,
        'totalSubmissions': 0,
        'ApprovedSubmissions': 0,
        'PendingSubmissions': 0,
        'RejectedSubmissions': 0,
      };
    }
  }
}
