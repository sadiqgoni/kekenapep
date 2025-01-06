import 'package:keke_fairshare/index.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitSupportRequest(String message) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw 'No user logged in';
    }

    // Get user data for additional context
    final userData = await _firestore
        .collection('users')
        .doc(user.uid)
        .get()
        .then((doc) => doc.data() ?? {});

    await _firestore.collection('support_requests').add({
      'userId': user.uid,
      'userPhone': userData['phone'] ?? '090',
      'userName': userData['fullName'] ?? 'Passenger',
      'message': message,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Map<String, dynamic>>> getUserSupportRequests() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('support_requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
            .toList());
  }
}
