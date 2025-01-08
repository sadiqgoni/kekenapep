import 'package:keke_fairshare/index.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user with phone and password
  Future<User?> registerWithPhoneAndPassword(
      String phone, String password, String fullName) async {
    try {
      // Append a domain to the phone number to mimic an email format
      final emailFormattedPhone = "$phone@phone.com";

      // Use the formatted phone as the "email"
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailFormattedPhone,
        password: password,
      );

      if (userCredential.user != null) {
        // Create user profile
        await _createUserProfile(userCredential.user!.uid, {
          'fullName': fullName,
          'phoneNumber': phone,
          'role': 'passenger',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
        });

        // Initialize user stats
        await _initializeUserStats(userCredential.user!.uid);

        return userCredential.user;
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'A user with this phone number already exists';
          break;
        case 'weak-password':
          message = 'The password provided is too weak';
          break;
        default:
          message = e.message ?? 'An error occurred during registration';
      }
      throw message;
    }
    return null;
  }

  // Sign in user with phone and password
  Future<User?> signInWithPhoneAndPassword(
      String phone, String password) async {
    try {
      final emailFormattedPhone = "$phone@phone.com";

      final userCredential = await _auth.signInWithEmailAndPassword(
        email: emailFormattedPhone,
        password: password,
      );

      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this phone number';
          break;
        case 'wrong-password':
          message = 'Wrong password provided';
          break;
        default:
          message = e.message ?? 'An error occurred during sign in';
      }
      throw message;
    }
  }

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null)
        throw Exception('No user logged in');

      // Re-authenticate user before changing password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // Change password
      await user.updatePassword(newPassword);

      // Log password change in Firestore
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('security_events')
          .add({
        'type': 'password_change',
        'timestamp': FieldValue.serverTimestamp(),
        'success': true,
      });
    } catch (e) {
      String errorMessage = 'Failed to change password';
      if (e.toString().contains('wrong-password')) {
        errorMessage = 'Current password is incorrect';
      } else if (e.toString().contains('requires-recent-login')) {
        errorMessage = 'Please sign in again before changing your password';
      }
      throw Exception(errorMessage);
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set(data);
    } catch (e) {
      print('Error creating user profile: $e');
      throw e;
    }
  }

  // Initialize user statistics
  Future<void> _initializeUserStats(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('statistics')
          .doc('overview')
          .set({
        'points': 0,
        'totalSubmissions': 0,
        'ApprovedSubmissions': 0,
        'RejectedSubmissions': 0,
        'PendingSubmissions': 0,
        'lastSubmissionAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error initializing user stats: $e');
      throw e;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        try {
          // Try to update the user's status, but don't block sign out if it fails
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'lastSeen': FieldValue.serverTimestamp(),
            'isOnline': false,
          }).timeout(const Duration(seconds: 3));
        } catch (_) {
          // Ignore Firestore errors and proceed with sign out
        }
      }

      // Always attempt to sign out
      await Future.wait([
        _auth.signOut(),
        // Add any other cleanup tasks here
      ]);
    } catch (e) {
      throw Exception('Failed to sign out: ${e.toString()}');
    }
  }
}
