import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Simple check if the current user is admin
  // Future<bool> isCurrentUserAdmin() async {
  //   try {
  //     final user = _auth.currentUser;
  //     if (user == null) return false;

  //     final userDoc = await _firestore.collection('users').doc(user.uid).get();
  //     return userDoc.data()?['role'] == 'admin';
  //   } catch (e) {
  //     print('Error checking admin status: $e');
  //     return false;
  //   }
  // }

  // Create a new admin account
  Future<UserCredential> createAdminAccount(
      String email, String password) async {
    try {
      // Check if email is already registered
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        throw 'An account with this email already exists';
      }

      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Set the user's role as admin in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': 'admin',
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

  // Sign in and verify admin role
  Future<bool> signInAsAdmin(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user == null) return false;

      // Verify admin role
      final userDoc = await _firestore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      final isAdmin = userDoc.data()?['role'] == 'admin';

      // If not admin, sign out
      if (!isAdmin) {
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

  // Create admin account if it doesn't exist
  // Future<void> ensureAdminExists() async {
  //   try {
  //     // Try to sign in with default admin credentials
  //     try {
  //       await _auth.signInWithEmailAndPassword(
  //         email: 'admin@kekefairshare.com',
  //         password: 'admin123456',
  //       );
  //     } catch (e) {
  //       // If sign in fails, create the admin account
  //       await createAdminAccount('admin@kekefairshare.com', 'admin123456');
  //     }
  //   } catch (e) {
  //     print('Error ensuring admin exists: $e');
  //   }
  // }

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
      final query = await _firestore.collection('users').count().get();
      return query.count ?? 0;
    } catch (e) {
      return 0;
    }
  }

  // Update fare status
  Future<void> updateFareStatus(String fareId, String status,
      {String? rejectionReason}) async {
    try {
      final fareRef = _firestore.collection('fares').doc(fareId);

      // Get the current fare data
      final fareDoc = await fareRef.get();
      if (!fareDoc.exists) {
        throw 'Fare not found';
      }

      // Create or update metadata
      final currentMetadata =
          (fareDoc.data()?['metadata'] as Map<String, dynamic>?) ?? {};
      final updatedMetadata = {
        ...currentMetadata,
        'status': status,
        'reviewedBy': _auth.currentUser?.uid,
        'reviewedAt': FieldValue.serverTimestamp(),
      };

      if (rejectionReason != null && rejectionReason.isNotEmpty) {
        updatedMetadata['rejectionReason'] = rejectionReason;
      }

      // Update the document with the new metadata
      await fareRef.update({
        'metadata': updatedMetadata,
      });

      // Update user stats if status changed to approved
      if (status == 'Approved') {
        final userId = fareDoc.data()?['userId'];
        if (userId != null) {
          final userRef = _firestore.collection('users').doc(userId);
          final userDoc = await userRef.get();

          if (userDoc.exists) {
            final currentStats =
                (userDoc.data()?['stats'] as Map<String, dynamic>?) ?? {};
            final points = currentStats['points'] ?? 0;
            final approvedSubmissions =
                currentStats['approvedSubmissions'] ?? 0;

            await userRef.update({
              'stats': {
                ...currentStats,
                'points': points + 1,
                'approvedSubmissions': approvedSubmissions + 1,
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

  // Create first admin account if none exists
  // Future<bool> createFirstAdmin(String email, String password) async {
  //   try {
  //     // Check if any admin exists
  //     final adminSnapshot =
  //         await _firestore.collection('admins').limit(1).get();
  //     if (adminSnapshot.docs.isNotEmpty) {
  //       return false; // Admin already exists
  //     }

  //     // Create admin account
  //     final userCredential = await createAdminAccount(email, password);

  //     // Add admin to Firestore
  //     await _firestore.collection('admins').doc(userCredential.user!.uid).set({
  //       'email': email,
  //       'createdAt': Timestamp.now(),
  //       'tokenExpiry': Timestamp.fromDate(
  //         DateTime.now().add(const Duration(days: 30)),
  //       ),
  //       'isFirstAdmin': true,
  //     });

  //     return true;
  //   } catch (e) {
  //     print('Error creating first admin: $e');
  //     return false;
  //   }
  // }

  // Refresh admin token periodically
  Future<bool> isAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final isAdmin = userDoc.data()?['role'] == 'admin';
      
      // Store admin status in shared preferences
      if (isAdmin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdmin', true);
        await prefs.setString('lastLoginRole', 'admin');
      }
      
      return isAdmin;
    } catch (e) {
      return false;
    }
  }

  Future<String?> getLastLoginRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('lastLoginRole');
  }
}
