import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Register user with phone and password
  Future<User?> registerWithPhoneAndPassword(
      String phone, String password, String fullName) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: "$phone@kekefairshare.com", // Using phone as email
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
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: "$phone@kekefairshare.com", // Using phone as email
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

  // Sign out user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      print('Sign Out Error: $e');
      throw e;
    }
  }
}
