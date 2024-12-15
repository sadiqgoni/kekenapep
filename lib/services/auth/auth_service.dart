import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user
  Future<User?> registerWithEmailAndPassword(
      String email, String password, String fullName) async {
    try {
      // Create auth user
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Set display name
        await userCredential.user!.updateDisplayName(fullName);

        // Create user profile document
        await _createUserProfile(userCredential.user!.uid, {
          'uid': userCredential.user!.uid,
          'email': email,
          'fullName': fullName,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'isActive': true,
          'role': 'passenger',
        });

        // Initialize user stats
        await _initializeUserStats(userCredential.user!.uid);
      }

      return userCredential.user;
    } catch (e) {
      print('Registration Error: $e');
      throw e;
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        ...data,
        'profile': {
          'phoneNumber': null,
          'avatar': null,
          'preferences': {
            'notifications': true,
          },
        },
        'metadata': {
          'lastLogin': FieldValue.serverTimestamp(),
          'registrationCompleted': false,
        },
      });
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
        'approvedSubmissions': 0,
        'rejectedSubmissions': 0,
        'pendingSubmissions': 0,
        'lastSubmissionAt': null,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error initializing user stats: $e');
      throw e;
    }
  }

  // Sign in user
  Future<User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update last login
        await _firestore
            .collection('users')
            .doc(userCredential.user!.uid)
            .update({
          'metadata.lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return userCredential.user;
    } catch (e) {
      print('Sign In Error: $e');
      throw e;
    }
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      final String uid = _auth.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        await _firestore.collection('users').doc(uid).update({
          'metadata.lastLogout': FieldValue.serverTimestamp(),
        });
      }
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
      throw e;
    }
  }
}
