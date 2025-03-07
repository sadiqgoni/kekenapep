import 'package:keke_fairshare/index.dart';

class UserStatsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<Map<String, dynamic>> getUserStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return _getEmptyStats();
      }

      // Get user's submissions with status
      final submissionsQuery = await _firestore
          .collection('fares')
          .where('submitter.uid', isEqualTo: user.uid)
          .get();

      // Calculate stats
      int totalSubmissions = submissionsQuery.docs.length;
      int approvedSubmissions = 0;
      int pendingSubmissions = 0;
      int rejectedSubmissions = 0;
      int totalPoints = 0;

      for (var doc in submissionsQuery.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'Pending';

        // Update submission counts
        switch (status) {
          case 'Approved':
            approvedSubmissions++;
            totalPoints += AppConstants.pointsPerSubmission +
                AppConstants.bonusPointsApproved;
            break;
          case 'Pending':
            pendingSubmissions++;
            totalPoints += AppConstants.pointsPerSubmission;
            break;
          case 'Rejected':
            rejectedSubmissions++;
            break;
        }
      }

      // Update the stats document
      final statsRef = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('statistics')
          .doc('overview');

      final stats = {
        'points': totalPoints,
        'totalSubmissions': totalSubmissions,
        'ApprovedSubmissions': approvedSubmissions,
        'PendingSubmissions': pendingSubmissions,
        'RejectedSubmissions': rejectedSubmissions,
        'lastUpdated': FieldValue.serverTimestamp(),
      };

      await statsRef.set(stats, SetOptions(merge: true));
      return stats;
    } catch (e) {
      print('Error fetching user stats: $e');
      return _getEmptyStats();
    }
  }

  Map<String, dynamic> _getEmptyStats() {
    return {
      'points': 0,
      'totalSubmissions': 0,
      'ApprovedSubmissions': 0,
      'RejectedSubmissions': 0,
      'PendingSubmissions': 0,
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
            ? AppConstants.pointsPerSubmission
            : AppConstants.bonusPointsApproved;

        Map<String, dynamic> updateData = {
          'points': currentPoints + pointsToAdd,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Update submission counters based on type
        if (type == 'submission') {
          updateData['totalSubmissions'] = (data['totalSubmissions'] ?? 0) + 1;
          updateData['PendingSubmissions'] =
              (data['PendingSubmissions'] ?? 0) + 1;
          updateData['lastSubmissionAt'] = FieldValue.serverTimestamp();
        } else if (type == 'Approved') {
          updateData['ApprovedSubmissions'] =
              (data['ApprovedSubmissions'] ?? 0) + 1;
          updateData['PendingSubmissions'] =
              (data['PendingSubmissions'] ?? 0) - 1;
        }

        transaction.set(statsRef, updateData, SetOptions(merge: true));

        // Add activity log
        final activityRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('activity')
            .doc();

        final activityData = {
          'type': type == 'submission'
              ? 'SUBMISSION_CREATED'
              : 'SUBMISSION_Approved',
          'points': pointsToAdd,
          'currentPoints': currentPoints + pointsToAdd,
          'pointsAdded': pointsToAdd,
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'currentPoints': currentPoints + pointsToAdd,
            'pointsAdded': pointsToAdd,
            'points': pointsToAdd,
            'timestamp': FieldValue.serverTimestamp(),
            'type': type == 'submission'
                ? 'SUBMISSION_CREATED'
                : 'SUBMISSION_Approved',
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
      final submissionsQuery = await _firestore
          .collection('fares')
          .where('submitter.uid', isEqualTo: userId)
          .get();

      // Count submissions by status
      int totalSubmissions = submissionsQuery.docs.length;
      int approvedSubmissions = 0;
      int pendingSubmissions = 0;
      int rejectedSubmissions = 0;
      int totalPoints = 0;

      for (var doc in submissionsQuery.docs) {
        final data = doc.data();
        final status = data['status'] ?? 'Pending';

        // Update submission counts and points
        switch (status) {
          case 'Approved':
            approvedSubmissions++;
            totalPoints += AppConstants.pointsPerSubmission +
                AppConstants.bonusPointsApproved;
            break;
          case 'Pending':
            pendingSubmissions++;
            totalPoints += AppConstants.pointsPerSubmission;
            break;
          case 'Rejected':
            rejectedSubmissions++;
            break;
        }
      }

      // Update statistics
      await userRef.collection('statistics').doc('overview').set({
        'points': totalPoints,
        'totalSubmissions': totalSubmissions,
        'ApprovedSubmissions': approvedSubmissions,
        'RejectedSubmissions': rejectedSubmissions,
        'PendingSubmissions': pendingSubmissions,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
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
