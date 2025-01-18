import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      // First verify if the email exists in our database
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email',
        );
      }

      // Generate and send verification code
      final verificationCode = _generateVerificationCode();

      // Store the verification code and its expiry time in Firestore
      await _firestore.collection('password_reset_codes').doc(email).set({
        'code': verificationCode,
        'expires_at': FieldValue.serverTimestamp(),
        'used': false,
      });

      // Send email with verification code
      await _sendVerificationEmail(email, verificationCode);
    } catch (e) {
      rethrow;
    }
  }

  // Verify code and reset password
  Future<void> verifyAndResetPassword(
    String email,
    String code,
    String newPassword,
  ) async {
    try {
      // Get the stored verification code
      final codeDoc =
          await _firestore.collection('password_reset_codes').doc(email).get();

      if (!codeDoc.exists) {
        throw FirebaseAuthException(
          code: 'invalid-code',
          message: 'Invalid or expired verification code',
        );
      }

      final data = codeDoc.data()!;
      final storedCode = data['code'] as String;
      final expiresAt = data['expires_at'] as Timestamp;
      final used = data['used'] as bool;

      // Check if code is expired (30 minutes validity)
      if (DateTime.now().difference(expiresAt.toDate()).inMinutes > 30) {
        throw FirebaseAuthException(
          code: 'expired-code',
          message: 'Verification code has expired',
        );
      }

      // Check if code is already used
      if (used) {
        throw FirebaseAuthException(
          code: 'used-code',
          message: 'This code has already been used',
        );
      }

      // Verify the code
      if (code != storedCode) {
        throw FirebaseAuthException(
          code: 'invalid-code',
          message: 'Invalid verification code',
        );
      }

      // Get user by email
      final userDoc = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userDoc.docs.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email',
        );
      }

      // Check if email exists in Firebase Auth
      final methods = await _auth.fetchSignInMethodsForEmail(email);
      if (methods.isEmpty) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email',
        );
      }

      // Send password reset email through Firebase
      await _auth.sendPasswordResetEmail(email: email);

      // Mark code as used
      await _firestore
          .collection('password_reset_codes')
          .doc(email)
          .update({'used': true});

      // Update password hash in Firestore (optional, as Firebase will handle the actual password)
      await _firestore.collection('users').doc(userDoc.docs.first.id).update({
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  // Generate a random 6-digit verification code
  String _generateVerificationCode() {
    return (100000 + DateTime.now().microsecondsSinceEpoch % 900000).toString();
  }

  // Send verification email
  Future<void> _sendVerificationEmail(String email, String code) async {
    // TODO: Implement email sending logic using your preferred email service
    // For now, we'll just print the code (in production, use a proper email service)
    print('Verification code $code sent to $email');
  }
}
