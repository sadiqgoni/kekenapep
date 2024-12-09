import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/faresubmission.dart';
import '../utils/logger.dart';
import '../models/fare_filter.dart';

class FareService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String> submitFare(FareSubmission submission) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();
      
      // Create main fare document
      final fareRef = _firestore.collection('fares').doc();
      final fareData = submission.toMap();
      batch.set(fareRef, fareData);

      // Add to user's submissions
      final userSubmissionRef = _firestore
          .collection('users')
          .doc(_auth.currentUser!.uid)
          .collection('submissions')
          .doc(fareRef.id);
      batch.set(userSubmissionRef, {
        'fareRef': fareRef.id,
        'submittedAt': submission.submittedAt.toIso8601String(),
        'status': submission.status,
      });

      // Update routes collection
      final routeId = _generateRouteId(submission.source, submission.destination);
      final routeRef = _firestore.collection('routes').doc(routeId);
      
      batch.set(routeRef, {
        'source': submission.source,
        'destination': submission.destination,
        'submissions': FieldValue.arrayUnion([fareRef.id]),
        'lastUpdated': FieldValue.serverTimestamp(),
        'metadata': {
          'popularLandmarks': FieldValue.arrayUnion(submission.routeTaken),
          'peakHours': FieldValue.arrayUnion([submission.dateTime.hour]),
        }
      }, SetOptions(merge: true));

      // Commit the batch
      await batch.commit();

      await AppLogger.logInfo(
        'FareSubmission',
        'Fare submitted successfully',
        additionalInfo: {
          'fareId': fareRef.id,
          'userId': _auth.currentUser!.uid,
          'route': routeId,
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

  String _generateRouteId(String source, String destination) {
    return '${source.toLowerCase().trim()}_${destination.toLowerCase().trim()}'
        .replaceAll(RegExp(r'[^a-z0-9_]'), '');
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
            .doc(doc.data()['fareRef'])
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
          .where('status', isEqualTo: 'Approved')
          .orderBy('submittedAt', descending: true)
          .limit(10);

      if (source != null) {
        query = query.where('source', isGreaterThanOrEqualTo: source.toLowerCase())
            .where('source', isLessThanOrEqualTo: '${source.toLowerCase()}\uf8ff');
      }

      if (filter?.fromDate != null) {
        query = query.where('dateTime', 
            isGreaterThanOrEqualTo: filter!.fromDate!.toIso8601String());
      }

      if (filter?.weatherCondition != null) {
        query = query.where('weatherConditions', isEqualTo: filter!.weatherCondition);
      }

      if (filter?.trafficCondition != null) {
        query = query.where('trafficConditions', isEqualTo: filter!.trafficCondition);
      }

      if (filter?.passengerLoad != null) {
        query = query.where('passengerLoad', isEqualTo: filter!.passengerLoad);
      }

      if (filter?.rushHourStatus != null) {
        query = query.where('rushHourStatus', isEqualTo: filter!.rushHourStatus);
      }

      final querySnapshot = await query.get();
      
      return querySnapshot.docs
          .map((doc) => FareSubmission.fromMap(doc.data() as Map<String, dynamic>))
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