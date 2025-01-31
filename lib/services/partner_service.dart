// partner_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PartnerService {
  Future<Map<String, dynamic>?> getPartnerData() async {
    User? user = FirebaseAuth.instance.currentUser;
    final userProfileRef =
        FirebaseFirestore.instance.collection('users').doc(user?.uid);

    try {
      final userSnapshot = await userProfileRef.get();
      if (!userSnapshot.exists) {
        return null; // User not found
      }

      var profileData = userSnapshot.data() as Map<String, dynamic>;
      String? partnerUID = profileData['partnerUID'];

      if (partnerUID == null || partnerUID.isEmpty) {
        return null; // Partner not found
      }

      final partnerProfileRef = FirebaseFirestore.instance
          .collection('users')
          .doc(partnerUID);

      final partnerSnapshot = await partnerProfileRef.get();
      if (!partnerSnapshot.exists) {
        return null; // Partner profile not found
      }

      return partnerSnapshot.data() as Map<String, dynamic>;
    } catch (e) {
      print('Error fetching partner data: $e');
      return null; // Error occurred
    }
  }
}