import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreenService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? getCurrentUserUID() {
    return _auth.currentUser?.uid;
  }

  Future<String?> getUserProfilePic(String userUID) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userUID).get();
      return userDoc['profile_picture'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<String?> getPartnerUID(String userUID) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userUID).get();
      return userDoc['partnerUID'] as String?;
    } catch (e) {
      return null;
    }
  }

  Stream<DocumentSnapshot> getPartnerProfilePicStream(String partnerUID) {
    return _firestore.collection('users').doc(partnerUID).snapshots();
  }

  Future<void> sendMessageToPartner(String userUID, String message) async {
    String? partnerUID = await getPartnerUID(userUID);
    if (partnerUID != null) {
      // Check if a message has already been sent today
      bool messageSentToday = await _hasMessageBeenSentToday(userUID);
      if (!messageSentToday) {
        await _deletePreviousMessage(userUID); // Delete any previous messages
      }
      // Store the new message
      await _firestore.collection('users').doc(userUID).collection('messages').add({
        'message': message,
        'sentAt': Timestamp.now(),
        'partnerUID': partnerUID,
      });
    }
  }

  Future<void> _deletePreviousMessage(String userUID) async {
    // Fetch the previous message and delete it
    QuerySnapshot previousMessages = await _firestore
        .collection('users')
        .doc(userUID)
        .collection('messages')
        .orderBy('sentAt', descending: true)
        .limit(1)
        .get();

    if (previousMessages.docs.isNotEmpty) {
      String previousMessageID = previousMessages.docs.first.id;
      await _firestore
          .collection('users')
          .doc(userUID)
          .collection('messages')
          .doc(previousMessageID)
          .delete();
    }
  }

  Future<bool> _hasMessageBeenSentToday(String userUID) async {
    // Fetch today's messages and check if any exists
    final todayStart = Timestamp.fromDate(DateTime.now().subtract(Duration(hours: 24)));
    final todayEnd = Timestamp.fromDate(DateTime.now());

    QuerySnapshot messagesSnapshot = await _firestore
        .collection('users')
        .doc(userUID)
        .collection('messages')
        .where('sentAt', isGreaterThanOrEqualTo: todayStart)
        .where('sentAt', isLessThanOrEqualTo: todayEnd)
        .get();

    return messagesSnapshot.docs.isNotEmpty;
  }

  Stream<DocumentSnapshot<Object?>?> getPartnerMessageStream(String userUID) async* {
    String? partnerUID = await getPartnerUID(userUID);
    if (partnerUID != null) {
      yield* _firestore
          .collection('users')
          .doc(partnerUID)
          .collection('messages')
          .orderBy('sentAt', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) => snapshot.docs.isNotEmpty ? snapshot.docs.first : null);
    }
  }
}