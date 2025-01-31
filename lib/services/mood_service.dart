import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class MoodService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Fetch partner UID from current user's document
  Future<String?> fetchPartnerUID() async {
    final userUID = _auth.currentUser?.uid;
    if (userUID == null) return null;

    try {
      final userDoc = await _firestore.collection('users').doc(userUID).get();
      return userDoc.data()?['partnerUID'];
    } catch (e) {
      print('Error fetching partnerUID: $e');
      return null;
    }
  }

  // Save mood and reason to Firestore
  Future<void> saveMood(String mood, String reason) async {
    final userUID = _auth.currentUser?.uid;
    if (userUID == null) throw 'User not authenticated';

    final now = DateTime.now();
    final date = DateFormat('dd-MM-yyyy').format(now);

    // Delete old moods
    await _deleteOldMoods(userUID, date);

    // Save new mood
    await _firestore
        .collection('users')
        .doc(userUID)
        .collection('mood')
        .add({
          'mood': mood,
          'reason': reason,
          'timestamp': FieldValue.serverTimestamp(),
          'date': date,
        });
  }

  // Get stream of current user's moods
  Stream<QuerySnapshot> getCurrentUserMoodsStream() {
    final userUID = _auth.currentUser?.uid;
    if (userUID == null) throw 'User not authenticated';

    return _firestore
        .collection('users')
        .doc(userUID)
        .collection('mood')
        .where('date', isEqualTo: DateFormat('dd-MM-yyyy').format(DateTime.now()))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Get stream of partner's moods
  Stream<QuerySnapshot> getPartnerMoodsStream(String? partnerUID) {
    if (partnerUID == null) throw 'Partner UID not available';

    return _firestore
        .collection('users')
        .doc(partnerUID)
        .collection('mood')
        .where('date', isEqualTo: DateFormat('dd-MM-yyyy').format(DateTime.now()))
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // Helper function to delete old moods
  Future<void> _deleteOldMoods(String userUID, String currentDate) async {
    final moodsSnapshot = await _firestore
        .collection('users')
        .doc(userUID)
        .collection('mood')
        .get();

    for (var doc in moodsSnapshot.docs) {
      final moodDate = doc.data()['date'] ?? '';
      if (moodDate != currentDate) {
        await doc.reference.delete();
      }
    }
  }
}