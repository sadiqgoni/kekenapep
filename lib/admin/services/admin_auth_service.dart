import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Admin-specific collection
  CollectionReference get _adminCollection => _firestore.collection('admin');

  // Create a new admin account
  Future<UserCredential> createAdminAccount(
      String email, String password) async {
    try {
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw 'An account with this email already exists';
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _adminCollection.doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'weak-password':
          message = 'The password is too weak';
          break;
        case 'email-already-in-use':
          message = 'An account with this email already exists';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        default:
          message = 'Account creation failed: ${e.message}';
      }
      throw message;
    } catch (e) {
      print('Error creating admin account: $e');
      rethrow;
    }
  }

  // Admin sign-in
  Future<bool> signInAsAdmin(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) return false;

      final adminDoc =
          await _adminCollection.doc(userCredential.user!.uid).get();
      if (!adminDoc.exists) {
        await _auth.signOut();
        throw 'This account does not have admin privileges';
      }

      return true;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Invalid password';
          break;
        case 'invalid-email':
          message = 'Invalid email format';
          break;
        case 'user-disabled':
          message = 'This account has been disabled';
          break;
        default:
          message = 'Authentication failed: ${e.message}';
      }
      throw message;
    } catch (e) {
      print('Error signing in as admin: $e');
      rethrow;
    }
  }

  // Get admin-specific stats
  Future<Object> getAdminStats() async {
    try {
      final stats = await _adminCollection.doc('stats').get();
      return stats.data() ?? {};
    } catch (e) {
      print('Error fetching admin stats: $e');
      return {};
    }
  }

  // Get pending fares count
  Future<int> getPendingFaresCount() async {
    try {
      final query = await _firestore
          .collection('fares')
          .where('metadata.status', isEqualTo: 'pending')
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      print('Error fetching pending fares count: $e');
      return 0;
    }
  }

  // Update fare status
  Future<void> updateFareStatus(String fareId, String status,
      {String? rejectionReason}) async {
    try {
      final fareRef = _firestore.collection('fares').doc(fareId);
      final fareDoc = await fareRef.get();

      if (!fareDoc.exists) {
        throw 'Fare not found';
      }

      final updatedMetadata = {
        ...fareDoc.data()?['metadata'] ?? {},
        'status': status,
        'reviewedBy': _auth.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
        if (rejectionReason != null) 'rejectionReason': rejectionReason,
      };

      await fareRef.update({'metadata': updatedMetadata});

      if (status == 'Approved') {
        final userId = fareDoc.data()?['userId'];
        if (userId != null) {
          final userRef = _firestore.collection('users').doc(userId);
          final userDoc = await userRef.get();

          if (userDoc.exists) {
            final currentStats = userDoc.data()?['stats'] ?? {};
            await userRef.update({
              'stats': {
                ...currentStats,
                'points': (currentStats['points'] ?? 0) + 1,
                'approvedSubmissions':
                    (currentStats['approvedSubmissions'] ?? 0) + 1,
              }
            });
          }
        }
      }
    } catch (e) {
      print('Error updating fare status: $e');
      rethrow;
    }
  }
}
