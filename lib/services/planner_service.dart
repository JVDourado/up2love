import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PlannerService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> getUserId() async {
    User? user = _auth.currentUser;
    return user?.uid;
  }

  Future<void> saveEvent(String userId, String event, String formattedDate, String? eventIdToEdit) async {
    final eventRef = _firestore.collection('users').doc(userId).collection('date_plans');

    try {
      if (eventIdToEdit != null && eventIdToEdit.isNotEmpty) {
        await eventRef.doc(eventIdToEdit).update({
          'event': event,
          'timestamp': FieldValue.serverTimestamp(),
        });
      } else {
        await eventRef.add({
          'event': event,
          'date': formattedDate,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteEvent(String userId, String eventId) async {
    try {
      await _firestore.collection('users').doc(userId).collection('date_plans').doc(eventId).delete();
    } catch (e) {
      rethrow;
    }
  }

  Stream<QuerySnapshot> getEventsForDate(String userId, String formattedDate) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('date_plans')
        .where('date', isEqualTo: formattedDate)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
