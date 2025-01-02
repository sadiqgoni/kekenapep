import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserManagementService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all users with pagination
  Future<List<QueryDocumentSnapshot>> getUsers({
    DocumentSnapshot? lastDocument,
    int limit = 20,
    String? searchQuery,
    String sortBy = 'createdAt',
    bool descending = true,
  }) async {
    Query query = _firestore
        .collection('users')
        .where('role', isNotEqualTo: 'admin'); // Exclude admin users

    // Apply search if query provided
    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.orderBy('fullName')
          .startAt([searchQuery.toLowerCase()])
          .endAt([searchQuery.toLowerCase() + '\uf8ff']);
    }

    // Apply sorting
    query = query.orderBy(sortBy, descending: descending);

    // Retrieve initial results
    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument);
    }

    query = query.limit(limit);

    final querySnapshot = await query.get();
    return querySnapshot.docs;
  }

  // Attach user stats to document
  Future<void> _attachUserStats(DocumentSnapshot doc) async {
    try {
      final statsDoc = await _firestore
          .collection('users')
          .doc(doc.id)
          .collection('statistics')
          .doc('overview')
          .get();

      if (statsDoc.exists) {
        (doc.data() as Map<String, dynamic>)['stats'] = statsDoc.data();
      } else {
        // Calculate stats from submissions
        final submissions = await _firestore
            .collection('fares')
            .where('userId', isEqualTo: doc.id)
            .get();

        int totalPoints = 0;
        for (var submission in submissions.docs) {
          totalPoints += (submission.data()['points'] ?? 0) as int;
        }

        final stats = {
          'points': totalPoints,
          'totalSubmissions': submissions.docs.length,
          'approvedSubmissions': submissions.docs
              .where((doc) => doc.data()['status'] == 'approved')
              .length,
          'pendingSubmissions': submissions.docs
              .where((doc) => doc.data()['status'] == 'pending')
              .length,
          'rejectedSubmissions': submissions.docs
              .where((doc) => doc.data()['status'] == 'rejected')
              .length,
        };

        // Save stats
        await _firestore
            .collection('users')
            .doc(doc.id)
            .collection('statistics')
            .doc('overview')
            .set(stats);

        (doc.data() as Map<String, dynamic>)['stats'] = stats;
      }
    } catch (e) {
      print('Error attaching stats for user ${doc.id}: $e');
    }
  }

  // Get user details including submissions
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userData = userDoc.data() ?? {};

      // Get user's submissions with status
      final submissions = await _firestore
          .collection('fares')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limit to recent 50 submissions
          .get();

      // Calculate user points from submissions
      int totalPoints = 0;
      final List<Map<String, dynamic>> submissionsList = [];

      for (var doc in submissions.docs) {
        final data = doc.data();
        final points = (data['points'] ?? 0) as int;
        totalPoints += points;

        submissionsList.add({
          ...data,
          'id': doc.id,
          'formattedDate': data['timestamp'] != null
              ? (data['timestamp'] as Timestamp).toDate().toString()
              : 'Unknown date',
        });
      }

      // Get user statistics
      final statsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('statistics')
          .doc('overview')
          .get();

      final stats = statsDoc.data() ??
          {
            'points': totalPoints,
            'totalSubmissions': submissions.docs.length,
            'approvedSubmissions': submissions.docs
                .where((doc) => doc.data()['status'] == 'approved')
                .length,
            'pendingSubmissions': submissions.docs
                .where((doc) => doc.data()['status'] == 'pending')
                .length,
            'rejectedSubmissions': submissions.docs
                .where((doc) => doc.data()['status'] == 'rejected')
                .length,
          };

      // Update stats if they don't exist
      if (!statsDoc.exists) {
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('statistics')
            .doc('overview')
            .set(stats);
      }

      // Get user's support requests instead of messages
      final supportRequests = await _firestore
          .collection('support_requests')
          .where('userId', isEqualTo: userId)
          // .where('status', isEqualTo: 'pending')
          .get();

      return {
        ...userData,
        'submissions': submissionsList,
        'stats': stats,
        'unreadMessages': supportRequests.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList(),
        'hasUnreadMessages': supportRequests.docs.isNotEmpty,
      };
    } catch (e) {
      print('Error getting user details: $e');
      return {};
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    // Start a batch write
    final batch = _firestore.batch();

    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));

    // Delete user's submissions
    final submissions = await _firestore
        .collection('fares')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in submissions.docs) {
      batch.delete(doc.reference);
    }

    // Delete user's support requests
    final requests = await _firestore
        .collection('support_requests')
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in requests.docs) {
      batch.delete(doc.reference);
    }

    // Delete user's statistics
    batch.delete(
      _firestore
          .collection('users')
          .doc(userId)
          .collection('statistics')
          .doc('overview'),
    );

    // Commit the batch
    await batch.commit();
  }

  // Send admin response to support request
  Future<void> sendAdminResponse(
    String userId,
    String requestId,
    String response,
  ) async {
    await _firestore.collection('support_requests').doc(requestId).update({
      'adminResponse': response,
      'status': 'responded',
      'respondedAt': FieldValue.serverTimestamp(),
      'respondedBy': _auth.currentUser?.uid,
    });
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    final statsDoc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('statistics')
        .doc('overview')
        .get();

    return statsDoc.data() ??
        {
          'points': 0,
          'totalSubmissions': 0,
          'approvedSubmissions': 0,
          'pendingSubmissions': 0,
          'rejectedSubmissions': 0,
        };
  }
}
