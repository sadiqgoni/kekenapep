import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Default admin credentials
  static const defaultAdminEmail = 'admin@kekefairshare.com';
  static const defaultAdminPassword = 'admin123456';

  // Simple check if the current user is admin
  Future<bool> isCurrentUserAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;
      
      // Check if email matches default admin email
      return user.email == defaultAdminEmail;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Sign in as admin
  Future<bool> signInAsAdmin(String email, String password) async {
    try {
      if (email != defaultAdminEmail) {
        return false;
      }

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return userCredential.user != null;
    } catch (e) {
      print('Error signing in as admin: $e');
      return false;
    }
  }

  // Create admin account if it doesn't exist
  Future<void> ensureAdminExists() async {
    try {
      // Try to sign in with default admin credentials
      try {
        await _auth.signInWithEmailAndPassword(
          email: defaultAdminEmail,
          password: defaultAdminPassword,
        );
      } catch (e) {
        // If sign in fails, create the admin account
        await _auth.createUserWithEmailAndPassword(
          email: defaultAdminEmail,
          password: defaultAdminPassword,
        );
      }
    } catch (e) {
      print('Error ensuring admin exists: $e');
    }
  }

  // Get admin dashboard stats
  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final stats = await _firestore.collection('stats').doc('admin').get();
      return stats.data() ?? {};
    } catch (e) {
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
      return 0;
    }
  }

  // Get total users count
  Future<int> getTotalUsersCount() async {
    try {
      final query = await _firestore
          .collection('users')
          .count()
          .get();
      return query.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Update fare status
  Future<void> updateFareStatus(String fareId, String status, {String? rejectionReason}) async {
    try {
      final fareRef = _firestore.collection('fares').doc(fareId);
      final updateData = {
        'metadata.status': status,
        'metadata.reviewedBy': _auth.currentUser?.uid,
        'metadata.reviewedAt': FieldValue.serverTimestamp(),
      };
      
      if (rejectionReason != null) {
        updateData['metadata.rejectionReason'] = rejectionReason;
      }

      await fareRef.update(updateData);
    } catch (e) {
      rethrow;
    }
  }

  // Create first admin account if none exists
  Future<bool> createFirstAdmin(String email, String password) async {
    try {
      // Check if any admin exists
      final adminSnapshot = await _firestore.collection('admins').limit(1).get();
      if (adminSnapshot.docs.isNotEmpty) {
        return false; // Admin already exists
      }

      // Create admin account
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Add admin to Firestore
      await _firestore.collection('admins').doc(userCredential.user!.uid).set({
        'email': email,
        'createdAt': Timestamp.now(),
        'tokenExpiry': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 30)),
        ),
        'isFirstAdmin': true,
      });

      return true;
    } catch (e) {
      print('Error creating first admin: $e');
      return false;
    }
  }

  // Refresh admin token periodically
  Future<void> refreshAdminToken() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore
          .collection('admins')
          .doc(user.uid)
          .update({
        'tokenExpiry': Timestamp.fromDate(
          DateTime.now().add(const Duration(hours: 12)),
        ),
        'lastRefresh': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }
}
