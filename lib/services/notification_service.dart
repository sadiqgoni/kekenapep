import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Create a notification
  Future<void> createNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
    String? fareId,
  }) async {
    try {
      print('NotificationService: Creating notification for user $userId');
      print('NotificationService: Title: $title');
      print('NotificationService: Message: $message');
      print('NotificationService: Type: $type');
      
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': title,
        'message': message,
        'type': type,
        'fareId': fareId,
        'isRead': false,
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      print('NotificationService: Notification created successfully');
    } catch (e) {
      print('NotificationService ERROR: Failed to create notification: $e');
    }
  }

  // Get notifications stream for current user
  Stream<QuerySnapshot> getNotificationsStream() {
    final userId = _auth.currentUser?.uid;
    print('NotificationService: Getting notifications for user $userId');
    
    if (userId == null) {
      print('NotificationService: No user logged in');
      return const Stream.empty();
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get unread notifications count
  Stream<int> getUnreadCount() {
    final userId = _auth.currentUser?.uid;
    print('NotificationService: Getting unread count for user $userId');
    
    if (userId == null) {
      print('NotificationService: No user logged in for unread count');
      return Stream.value(0);
    }

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
          print('NotificationService: Unread count: ${snapshot.docs.length}');
          return snapshot.docs.length;
        });
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      print('NotificationService: Marking notification $notificationId as read');
      await _firestore
          .collection('notifications')
          .doc(notificationId)
          .update({'isRead': true});
      print('NotificationService: Notification marked as read successfully');
    } catch (e) {
      print('NotificationService ERROR: Failed to mark notification as read: $e');
    }
  }

  // Delete notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      print('NotificationService: Deleting notification $notificationId');
      await _firestore.collection('notifications').doc(notificationId).delete();
      print('NotificationService: Notification deleted successfully');
    } catch (e) {
      print('NotificationService ERROR: Failed to delete notification: $e');
    }
  }

  // Mark all notifications as read
  Future<void> markAllAsRead() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      print('NotificationService: No user logged in for mark all as read');
      return;
    }

    try {
      print('NotificationService: Marking all notifications as read for user $userId');
      final batch = _firestore.batch();
      final notifications = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('isRead', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc.reference, {'isRead': true});
      }

      await batch.commit();
      print('NotificationService: All notifications marked as read successfully');
    } catch (e) {
      print('NotificationService ERROR: Failed to mark all notifications as read: $e');
    }
  }
}
