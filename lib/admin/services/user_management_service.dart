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
    if (sortBy == 'points') {
      // First get all users
      final usersQuery = await _firestore.collection('users').get();
      final List<Future<DocumentSnapshot>> statsFutures = usersQuery.docs
          .map((doc) =>
              doc.reference.collection('statistics').doc('overview').get())
          .toList();

      final List<DocumentSnapshot> statsSnapshots =
          await Future.wait(statsFutures);

      // Combine user data with their stats
      final List<Map<String, dynamic>> usersWithStats = [];
      for (var i = 0; i < usersQuery.docs.length; i++) {
        final userData = usersQuery.docs[i].data();
        final statsData = statsSnapshots[i].data() as Map<String, dynamic>?;
        usersWithStats.add({
          'doc': usersQuery.docs[i],
          'points': statsData?['points'] ?? 0,
        });
      }

      // Sort by points
      usersWithStats.sort((a, b) {
        final pointsA = a['points'] as int;
        final pointsB = b['points'] as int;
        return descending
            ? pointsB.compareTo(pointsA)
            : pointsA.compareTo(pointsB);
      });

      // Return sorted documents
      return usersWithStats
          .map((item) => item['doc'] as QueryDocumentSnapshot)
          .toList();
    }

    // For other sort fields, use regular query
    Query query = _firestore.collection('users');

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query
          .orderBy('fullName')
          .startAt([searchQuery.toLowerCase()]).endAt(
              [searchQuery.toLowerCase() + '\uf8ff']);
    }

    query = query.orderBy(sortBy, descending: descending);

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
          'ApprovedSubmissions': submissions.docs
              .where((doc) => doc.data()['status'] == 'Approved')
              .length,
          'PendingSubmissions': submissions.docs
              .where((doc) => doc.data()['status'] == 'Pending')
              .length,
          'RejectedSubmissions': submissions.docs
              .where((doc) => doc.data()['status'] == 'Rejected')
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
      print('Getting user details for userId: $userId');
      final userDoc = await _firestore.collection('users').doc(userId).get();
      print('User doc exists: ${userDoc.exists}');
      
      if (!userDoc.exists) {
        print('User document does not exist');
        return {};
      }
      
      final userData = userDoc.data() ?? {};
      print('User data: $userData');

      // Get user's submissions with status
      final submissionsQuery = _firestore
          .collection('fares')
          .where('submitter.uid', isEqualTo: userId)
          .orderBy('metadata.createdAt', descending: true)
          .limit(50);
      
      print('Submissions query: ${submissionsQuery.parameters}');
      
      final submissions = await submissionsQuery.get();
      print('Found ${submissions.docs.length} submissions');
      
      if (submissions.docs.isNotEmpty) {
        print('First submission data: ${submissions.docs.first.data()}');
      }

      // Calculate user points from submissions
      int totalPoints = 0;
      final List<Map<String, dynamic>> submissionsList = [];

      for (var doc in submissions.docs) {
        final data = doc.data();
        final points = (data['points'] ?? 0) as int;
        totalPoints += points;

        submissionsList.add({
          'id': doc.id,
          'source': data['source'] ?? '',
          'destination': data['destination'] ?? '',
          'fareAmount': data['fareAmount'] ?? 0.0,
          'status': data['metadata']?['status'] ?? 'Unknown',
          'submittedAt': data['metadata']?['createdAt'],
          'formattedDate': data['metadata']?['createdAt'] != null
              ? (data['metadata']['createdAt'] as Timestamp).toDate().toString()
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
      
      print('Stats doc exists: ${statsDoc.exists}');
      if (statsDoc.exists) {
        print('Stats data: ${statsDoc.data()}');
      }

      final stats = statsDoc.data() ??
          {
            'points': totalPoints,
            'totalSubmissions': submissions.docs.length,
            'ApprovedSubmissions': submissions.docs
                .where((doc) => doc.data()['metadata']?['status'] == 'Approved')
                .length,
            'PendingSubmissions': submissions.docs
                .where((doc) => doc.data()['metadata']?['status'] == 'Pending')
                .length,
            'RejectedSubmissions': submissions.docs
                .where((doc) => doc.data()['metadata']?['status'] == 'Rejected')
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

      final result = {
        ...userData,  // Include all user data
        'id': userDoc.id,
        'submissions': submissionsList,
        'stats': stats,
      };
      
      print('Final result: $result');
      return result;
    } catch (e, stackTrace) {
      print('Error getting user details: $e');
      print('Stack trace: $stackTrace');
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
        .where('submitter.uid', isEqualTo: userId)
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
          'ApprovedSubmissions': 0,
          'PendingSubmissions': 0,
          'RejectedSubmissions': 0,
        };
  }
}
