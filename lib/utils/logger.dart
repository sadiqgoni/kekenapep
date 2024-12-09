import 'package:cloud_firestore/cloud_firestore.dart';

class AppLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logError(String component, String error, {Map<String, dynamic>? additionalInfo}) async {
    try {
      await _firestore.collection('logs').add({
        'type': 'ERROR',
        'component': component,
        'message': error,
        'timestamp': FieldValue.serverTimestamp(),
        'additionalInfo': additionalInfo,
      });
      print('ERROR [$component]: $error');
    } catch (e) {
      print('Failed to log error: $e');
    }
  }

  static Future<void> logInfo(String component, String message, {Map<String, dynamic>? additionalInfo}) async {
    try {
      await _firestore.collection('logs').add({
        'type': 'INFO',
        'component': component,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'additionalInfo': additionalInfo,
      });
      print('INFO [$component]: $message');
    } catch (e) {
      print('Failed to log info: $e');
    }
  }
} 