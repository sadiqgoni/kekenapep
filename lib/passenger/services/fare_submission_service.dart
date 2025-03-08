import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:keke_fairshare/passenger/services/user_stats_service.dart';

class FareSubmissionService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final UserStatsService _userStatsService = UserStatsService();

  // Auto-approval configuration
  static final Map<String, dynamic> _autoApprovalConfig = {
    'enabled': true,
    'minUserPoints': 15,
    'minFareAmount': 50,
    'maxFareAmount': 2000,
    'maxDeviationFromAverage': 0.3, // 30%
    'minRouteTakenCount': 1,
    'requireTimeOfTravel': true,
    'requireDateOfTravel': true,
    'minSubmissionsForTrustedUser': 5,
    'minApprovedSubmissionsForTrustedUser': 3,
  };

  // Load configuration from Firestore
  static Future<void> loadAutoApprovalConfig() async {
    try {
      final configDoc = await _firestore
          .collection('admin')
          .doc('settings')
          .collection('fare_submission')
          .doc('auto_approval')
          .get();

      if (configDoc.exists) {
        final configData = configDoc.data();
        if (configData != null) {
          _autoApprovalConfig.addAll(configData);
        }
      }
    } catch (e) {
      print('Error loading auto-approval config: $e');
      // Continue with default config
    }
  }

  // Submit a new fare
  static Future<Map<String, dynamic>> submitFare({
    required String source,
    required String destination,
    required List<String> routeTaken,
    required int fareAmount,
    required String passengerLoad,
    required String weatherConditions,
    required String trafficConditions,
    required String rushHourStatus,
    String? notes,
    DateTime? dateOfTravel,
    FareTimeOfDay? timeOfTravel,
  }) async {
    try {
      // Load latest config
      await loadAutoApprovalConfig();

      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to submit fares');
      }

      // Create submission data
      final submissionData = {
        'source': source.toLowerCase().trim(),
        'destination': destination.toLowerCase().trim(),
        'routeTaken': routeTaken,
        'fareAmount': fareAmount,
        'passengerLoad': passengerLoad,
        'weatherConditions': weatherConditions,
        'trafficConditions': trafficConditions,
        'rushHourStatus': rushHourStatus,
        'notes': notes,
        'dateTime': DateTime.now().toIso8601String(),
        'submitter': {
          'uid': user.uid,
          'email': user.email,
          'displayName': user.displayName,
        },
        'submittedAt': FieldValue.serverTimestamp(),
        'helpfulCount': 0,
      };

      // Add date and time of travel if provided
      if (dateOfTravel != null) {
        submissionData['dateOfTravel'] = dateOfTravel.toIso8601String();
      }

      if (timeOfTravel != null) {
        submissionData['timeOfTravel'] =
            '${timeOfTravel.hour}:${timeOfTravel.minute}';
      }

      // Determine if this submission should be auto-approved
      final approvalStatus = await _determineApprovalStatus(
        source: source,
        destination: destination,
        fareAmount: fareAmount,
        routeTaken: routeTaken,
        userUid: user.uid,
        dateOfTravel: dateOfTravel,
        timeOfTravel: timeOfTravel,
      );

      // Set status based on approval determination
      submissionData['status'] = approvalStatus.status;
      submissionData['reviewReason'] = approvalStatus.reason;

      // Add to Firestore
      final docRef = await _firestore.collection('fares').add(submissionData);

      // Update user stats
      await _userStatsService.addPoints(user.uid, 'submission');

      // If auto-approved, also add the approval points
      if (approvalStatus.status == 'Approved') {
        await _userStatsService.addPoints(user.uid, 'Approved');
      }

      // Return the submission with ID
      return {
        'id': docRef.id,
        ...submissionData,
        'autoApproved': approvalStatus.status == 'Approved',
      };
    } catch (e) {
      print('Error submitting fare: $e');
      rethrow;
    }
  }

  // Determine if a submission should be auto-approved or needs review
  static Future<ApprovalStatus> _determineApprovalStatus({
    required String source,
    required String destination,
    required int fareAmount,
    required List<String> routeTaken,
    required String userUid,
    DateTime? dateOfTravel,
    FareTimeOfDay? timeOfTravel,
  }) async {
    try {
      // Check if auto-approval is enabled
      if (!_autoApprovalConfig['enabled']) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'Auto-approval is disabled',
        );
      }

      // Check 1: User reputation (points)
      final userStats = await _getUserStats(userUid);
      final userPoints = userStats['points'] ?? 0;
      final totalSubmissions = userStats['totalSubmissions'] ?? 0;
      final approvedSubmissions = userStats['ApprovedSubmissions'] ?? 0;

      if (userPoints < _autoApprovalConfig['minUserPoints']) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'User has insufficient points for auto-approval',
        );
      }

      // Check 2: User submission history
      if (totalSubmissions <
          _autoApprovalConfig['minSubmissionsForTrustedUser']) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'User does not have enough submission history',
        );
      }

      if (approvedSubmissions <
          _autoApprovalConfig['minApprovedSubmissionsForTrustedUser']) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'User does not have enough approved submissions',
        );
      }

      // Check 3: Basic fare amount validation
      if (fareAmount < _autoApprovalConfig['minFareAmount'] ||
          fareAmount > _autoApprovalConfig['maxFareAmount']) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'Fare amount outside reasonable range',
        );
      }

      // Check 4: Route taken validation
      if (routeTaken.length < _autoApprovalConfig['minRouteTakenCount']) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'Route must include at least one landmark',
        );
      }

      // Check 5: Required fields
      if (_autoApprovalConfig['requireDateOfTravel'] && dateOfTravel == null) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'Date of travel is required for auto-approval',
        );
      }

      if (_autoApprovalConfig['requireTimeOfTravel'] && timeOfTravel == null) {
        return ApprovalStatus(
          status: 'Pending',
          reason: 'Time of travel is required for auto-approval',
        );
      }

      // Check 6: Compare with existing approved fares for this route
      final avgFare = await _getAverageFareForRoute(source, destination);
      if (avgFare > 0) {
        final deviation = (fareAmount - avgFare).abs() / avgFare;
        if (deviation > _autoApprovalConfig['maxDeviationFromAverage']) {
          return ApprovalStatus(
            status: 'Pending',
            reason: 'Fare deviates significantly from average',
          );
        }
      }

      // All checks passed, auto-approve
      return ApprovalStatus(
        status: 'Approved',
        reason: 'Auto-approved based on user reputation and fare validation',
      );
    } catch (e) {
      print('Error determining approval status: $e');
      // Default to pending if there's an error
      return ApprovalStatus(
        status: 'Pending',
        reason: 'Error in auto-approval process',
      );
    }
  }

  // Get user stats for approval decision
  static Future<Map<String, dynamic>> _getUserStats(String userId) async {
    try {
      final statsDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('statistics')
          .doc('overview')
          .get();

      return statsDoc.data() ?? {};
    } catch (e) {
      print('Error getting user stats: $e');
      return {};
    }
  }

  // Get average fare for a route
  static Future<double> _getAverageFareForRoute(
      String source, String destination) async {
    try {
      final querySnapshot = await _firestore
          .collection('fares')
          .where('source', isEqualTo: source.toLowerCase().trim())
          .where('destination', isEqualTo: destination.toLowerCase().trim())
          .where('status', isEqualTo: 'Approved')
          .get();

      if (querySnapshot.docs.isEmpty) {
        return 0;
      }

      double totalFare = 0;
      for (var doc in querySnapshot.docs) {
        totalFare += (doc.data()['fareAmount'] as num).toDouble();
      }

      return totalFare / querySnapshot.docs.length;
    } catch (e) {
      print('Error calculating average fare: $e');
      return 0;
    }
  }

  // Get submissions for admin review
  static Stream<QuerySnapshot> getPendingSubmissions() {
    return _firestore
        .collection('fares')
        .where('status', isEqualTo: 'Pending')
        .orderBy('submittedAt', descending: true)
        .snapshots();
  }

  // Admin: Approve a submission
  static Future<void> approveSubmission(String fareId) async {
    try {
      final fareDoc = await _firestore.collection('fares').doc(fareId).get();
      final data = fareDoc.data();

      if (data == null) {
        throw Exception('Fare not found');
      }

      final submitterId = data['submitter']['uid'];

      await _firestore.collection('fares').doc(fareId).update({
        'status': 'Approved',
        'reviewedAt': FieldValue.serverTimestamp(),
      });

      // Add approval points to user
      await _userStatsService.addPoints(submitterId, 'Approved');
    } catch (e) {
      print('Error approving submission: $e');
      rethrow;
    }
  }

  // Admin: Reject a submission
  static Future<void> rejectSubmission(String fareId, String reason) async {
    try {
      await _firestore.collection('fares').doc(fareId).update({
        'status': 'Rejected',
        'rejectionReason': reason,
        'reviewedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error rejecting submission: $e');
      rethrow;
    }
  }

  // Admin: Update auto-approval configuration
  static Future<void> updateAutoApprovalConfig(
      Map<String, dynamic> newConfig) async {
    try {
      await _firestore
          .collection('admin')
          .doc('settings')
          .collection('fare_submission')
          .doc('auto_approval')
          .set(newConfig, SetOptions(merge: true));

      // Update local config
      _autoApprovalConfig.addAll(newConfig);
    } catch (e) {
      print('Error updating auto-approval config: $e');
      rethrow;
    }
  }
}

// Class to represent approval decision
class ApprovalStatus {
  final String status; // 'Approved' or 'Pending'
  final String reason;

  ApprovalStatus({
    required this.status,
    required this.reason,
  });
}

// Renamed TimeOfDay class to FareTimeOfDay to avoid conflicts with Flutter's TimeOfDay
class FareTimeOfDay {
  final int hour;
  final int minute;

  const FareTimeOfDay({required this.hour, required this.minute});
}
