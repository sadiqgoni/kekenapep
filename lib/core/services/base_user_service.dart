import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants.dart';

abstract class BaseUserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Common methods for both admin and passenger
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();
      
      return doc.data() ?? {};
    } catch (e) {
      print('Error fetching user profile: $e');
      return {};
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      rethrow;
    }
  }

  // Protected getters for child classes
  FirebaseFirestore get firestore => _firestore;
  FirebaseAuth get auth => _auth;
  User? get currentUser => _auth.currentUser;
}
