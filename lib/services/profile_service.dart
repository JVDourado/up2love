import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Method to pick and upload the profile picture
  Future<String?> uploadProfilePicture(File imageFile, String userUID) async {
  try {
    // Generate a unique path for the new profile picture
    String newFilePath = 'users/$userUID/profile_picture/${DateTime.now().toIso8601String()}';

    // Upload the new image to Firebase Storage
    UploadTask uploadTask = _storage.ref(newFilePath).putFile(imageFile);

    // Wait for the upload to complete
    TaskSnapshot taskSnapshot = await uploadTask;

    // Get the download URL of the uploaded image
    String downloadURL = await taskSnapshot.ref.getDownloadURL();

    // Store the file path in Firestore
    await _firestore.collection('users').doc(userUID).update({
      'profile_picture': downloadURL,
      'profile_picture_path': newFilePath, // Store the file path
    });

    return downloadURL;
  } catch (e) {
    print('Error uploading profile picture: $e');
    return null;
  }
}

  // Method to delete the old profile picture
  Future<void> deleteOldProfilePicture(String userUID, String currentProfilePicUrl) async {
  try {
    // Fetch the stored file path from Firestore
    DocumentSnapshot userSnapshot = await _firestore.collection('users').doc(userUID).get();
    String? filePath = userSnapshot.get('profile_picture_path');

    if (filePath != null && filePath.isNotEmpty) {
      // Delete the file using the stored file path
      await _storage.ref(filePath).delete();
      print('Old profile picture deleted successfully.');
    } else {
      print('No file path found for the old profile picture.');
    }
  } catch (e) {
    print('Error deleting previous profile picture: $e');
  }
}

  // Method to fetch the user's profile data from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String userUID) async {
    try {
      DocumentSnapshot snapshot = await _firestore.collection('users').doc(userUID).get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      } else {
        return null;
      }
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Method to update the user's profile in Firestore
  Future<void> updateUserProfile(String userUID, Map<String, dynamic> profileData) async {
    try {
      await _firestore.collection('users').doc(userUID).update(profileData);
    } catch (e) {
      print('Error updating user profile: $e');
    }
  }

  // Method to sync with a partner by username and email
  Future<String?> syncWithPartner(String username, String email) async {
    try {
      var partnerQuery = _firestore.collection('users')
          .where('email', isEqualTo: email.trim().toLowerCase())
          .where('username', isEqualTo: username.trim().toLowerCase())
          .limit(1);

      var partnerSnapshot = await partnerQuery.get();

      if (partnerSnapshot.docs.isNotEmpty) {
        String partnerUID = partnerSnapshot.docs.first.id;
        return partnerUID;
      } else {
        return null;
      }
    } catch (e) {
      print('Error syncing with partner: $e');
      return null;
    }
  }
}
