import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/faresubmission.dart';
import '../utils/logger.dart';
import '../models/fare_filter.dart';
import './user_stats_service.dart';

class FareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserStatsService _userStatsService = UserStatsService();

  Future<String> submitFare(FareSubmission submission) async {
    try {
      final userId = _auth.currentUser!.uid;

      // Ensure user stats are initialized
      await _userStatsService.initializeUserStats(userId);

      // Start a batch write
      final batch = _firestore.batch();

      // Create fare document with proper structure
      final fareRef = _firestore.collection('fares').doc();
      final fareData = {
        ...submission.toMap(),
        'metadata': {
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'pending',
          'reviewedBy': null,
          'reviewedAt': null,
        },
        'submitter': {
          'uid': userId,
          'timestamp': FieldValue.serverTimestamp(),
        },
      };
      batch.set(fareRef, fareData);

      // Add to user's submissions subcollection
      final userSubmissionRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('submissions')
          .doc(fareRef.id);

      batch.set(userSubmissionRef, {
        'fareId': fareRef.id,
        'source': submission.source,
        'destination': submission.destination,
        'amount': submission.fareAmount,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
        'metadata': {
          'routeTaken': submission.routeTaken,
          'dateTime': submission.dateTime.toIso8601String(),
        }
      });

      // Update routes collection with proper structure
      final routeId =
          _generateRouteId(submission.source, submission.destination);
      final routeRef = _firestore.collection('routes').doc(routeId);

      batch.set(
          routeRef,
          {
            'source': submission.source,
            'destination': submission.destination,
            'metadata': {
              'submissions': FieldValue.arrayUnion([fareRef.id]),
              'lastUpdated': FieldValue.serverTimestamp(),
              'popularLandmarks': FieldValue.arrayUnion(submission.routeTaken),
              'peakHours': FieldValue.arrayUnion([submission.dateTime.hour]),
            },
            'stats': {
              'totalSubmissions': FieldValue.increment(1),
              'averageAmount': null, // Will be calculated by Cloud Function
              'lastSubmissionAt': FieldValue.serverTimestamp(),
            }
          },
          SetOptions(merge: true));

      // Commit the batch
      await batch.commit();

      // Award points for submission
      await _userStatsService.addPoints(userId, 'submission');

      // Log the submission
      await AppLogger.logInfo(
        'FareSubmission',
        'Fare submitted successfully',
        additionalInfo: {
          'fareId': fareRef.id,
          'userId': userId,
          'route': routeId,
          'pointsAwarded': UserStatsService.POINTS_PER_SUBMISSION,
        },
      );

      return fareRef.id;
    } catch (e) {
      await AppLogger.logError(
        'FareSubmission',
        'Error submitting fare',
        additionalInfo: {'error': e.toString()},
      );
      throw 'Failed to submit fare: ${e.toString()}';
    }
  }

  Future<void> updateFareStatus(String fareId, String status) async {
    try {
      // Get the fare document first to check current status
      final fareRef = _firestore.collection('fares').doc(fareId);
      final fareDoc = await fareRef.get();

      if (!fareDoc.exists) {
        throw 'Fare document not found';
      }

      final currentStatus = fareDoc.data()?['metadata']?['status'];
      final userId = fareDoc.data()?['submitter']?['uid'];
      final reviewerId = _auth.currentUser?.uid;

      // Only proceed if there's a status change and we have required IDs
      if (currentStatus != status && userId != null && reviewerId != null) {
        final batch = _firestore.batch();

        // Update main fare document
        batch.update(fareRef, {
          'metadata.status': status,
          'metadata.updatedAt': FieldValue.serverTimestamp(),
          'metadata.reviewedBy': reviewerId,
          'metadata.reviewedAt': FieldValue.serverTimestamp(),
        });

        // Update user's submission
        final userSubmissionRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('submissions')
            .doc(fareId);

        batch.update(userSubmissionRef, {
          'status': status,
          'reviewedAt': FieldValue.serverTimestamp(),
          'reviewedBy': reviewerId,
        });

        // Add review record
        final reviewRef = _firestore
            .collection('users')
            .doc(userId)
            .collection('submissions')
            .doc(fareId)
            .collection('reviews')
            .doc();

        batch.set(reviewRef, {
          'status': status,
          'reviewerId': reviewerId,
          'timestamp': FieldValue.serverTimestamp(),
          'metadata': {
            'previousStatus': currentStatus,
          }
        });

        // Commit the batch first
        await batch.commit();

        // If the status is being changed to 'Approved', award bonus points
        if (status == 'Approved' && currentStatus != 'Approved') {
          await _userStatsService.addPoints(userId, 'approved');

          await AppLogger.logInfo(
            'FareApproval',
            'Bonus points awarded for approved submission',
            additionalInfo: {
              'fareId': fareId,
              'userId': userId,
              'reviewerId': reviewerId,
              'bonusPoints': UserStatsService.BONUS_POINTS_APPROVED,
              'previousStatus': currentStatus,
            },
          );
        }
      }
    } catch (e) {
      await AppLogger.logError(
        'FareStatusUpdate',
        'Error updating fare status',
        additionalInfo: {
          'fareId': fareId,
          'status': status,
          'error': e.toString(),
        },
      );
      throw 'Failed to update fare status: ${e.toString()}';
    }
  }

  String _generateRouteId(String source, String destination) {
    return '${source.toLowerCase()}_${destination.toLowerCase()}'
        .replaceAll(' ', '_');
  }

  Future<List<FareSubmission>> getUserSubmissions() async {
    try {
      final submissions = await _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('submissions')
          .orderBy('submittedAt', descending: true)
          .get();

      List<FareSubmission> fares = [];
      for (var doc in submissions.docs) {
        final fareDoc = await _firestore
            .collection('fares')
            .doc(doc.data()['fareId'])
            .get();

        if (fareDoc.exists) {
          fares.add(FareSubmission.fromMap(fareDoc.data()!));
        }
      }

      return fares;
    } catch (e) {
      await AppLogger.logError(
        'FareSubmission',
        'Error fetching user submissions',
        additionalInfo: {'error': e.toString()},
      );
      throw 'Failed to fetch submissions: ${e.toString()}';
    }
  }

  Future<List<FareSubmission>> searchFares({
    String? source,
    String? destination,
    List<String>? landmarks,
    FareFilter? filter,
  }) async {
    try {
      Query query = _firestore
          .collection('fares')
          .where('metadata.status', isEqualTo: 'Approved')
          .orderBy('submittedAt', descending: true)
          .limit(10);

      if (source != null) {
        query = query
            .where('source', isGreaterThanOrEqualTo: source.toLowerCase())
            .where('source',
                isLessThanOrEqualTo: '${source.toLowerCase()}\uf8ff');
      }

      if (filter?.fromDate != null) {
        query = query.where('dateTime',
            isGreaterThanOrEqualTo: filter!.fromDate!.toIso8601String());
      }

      if (filter?.weatherCondition != null) {
        query = query.where('weatherConditions',
            isEqualTo: filter!.weatherCondition);
      }

      if (filter?.trafficCondition != null) {
        query = query.where('trafficConditions',
            isEqualTo: filter!.trafficCondition);
      }

      if (filter?.passengerLoad != null) {
        query = query.where('passengerLoad', isEqualTo: filter!.passengerLoad);
      }

      if (filter?.rushHourStatus != null) {
        query =
            query.where('rushHourStatus', isEqualTo: filter!.rushHourStatus);
      }

      final querySnapshot = await query.get();

      return querySnapshot.docs
          .map((doc) =>
              FareSubmission.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      await AppLogger.logError(
        'FareService',
        'Error searching fares',
        additionalInfo: {'error': e.toString()},
      );
      throw 'Failed to search fares: ${e.toString()}';
    }
  }
}
