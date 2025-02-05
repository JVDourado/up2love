import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class PhotoService {
  final ImagePicker _picker = ImagePicker();

  Future<XFile?> pickImage() async {
    try {
      return await _picker.pickImage(source: ImageSource.gallery);
    } catch (e) {
      throw Exception('Falha ao selecionar imagem: $e');
    }
  }

  Future<String> uploadPhoto(File imageFile, String caption) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Por favor, autentique primeiro');
    }

    try {
      // Generate a unique file name
      final uniqueFileName = '${DateTime.now().millisecondsSinceEpoch}_${imageFile.uri.pathSegments.last}';

      // Upload the file to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(user.uid)
          .child('uploads')
          .child(uniqueFileName);

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Save photo metadata to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('uploads')
          .add({
        'url': downloadUrl,
        'caption': caption,
        'timestamp': FieldValue.serverTimestamp(),
        'uploadedBy': user.uid, // Track who uploaded the photo
      });

      return downloadUrl;
    } catch (e) {
      throw Exception('Falha ao carregar foto: $e');
    }
  }

  Future<void> deletePhoto(String photoId, String photoUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Por favor, autentique primeiro');
      }

      // Delete the photo from Firebase Storage
      await FirebaseStorage.instance.refFromURL(photoUrl).delete();

      // Delete the photo metadata from Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('uploads')
          .doc(photoId)
          .delete();
    } catch (e) {
      throw Exception('Falha ao deletar foto: $e');
    }
  }

  Future<void> editCaption(String photoId, String newCaption) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Por favor, autentique primeiro');
      }

      // Update the caption in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('uploads')
          .doc(photoId)
          .update({
        'caption': newCaption,
      });
    } catch (e) {
      throw Exception('Falha ao editar legenda: $e');
    }
  }

  // Fetch all uploads for a specific user
  Future<List<QueryDocumentSnapshot>> fetchUserUploads(String userUID) async {
    try {
      final uploadsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userUID)
          .collection('uploads')
          .orderBy('timestamp', descending: true)
          .get();

      return uploadsSnapshot.docs;
    } catch (e) {
      throw Exception('Falha ao buscar uploads do usuário: $e');
    }
  }

  // Fetch partner's UID and username
  Future<Map<String, String>?> fetchPartnerInfo(String userUID) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userUID).get();
      if (userDoc.exists && userDoc.data() != null) {
        final partnerUID = userDoc['partnerUID'];
        if (partnerUID != null) {
          final partnerDoc = await FirebaseFirestore.instance.collection('users').doc(partnerUID).get();
          if (partnerDoc.exists && partnerDoc.data() != null) {
            final partnerUsername = partnerDoc['username'];
            return {
              'partnerUID': partnerUID,
              'partnerUsername': partnerUsername,
            };
          }
        }
      }
      return null; // Return null if partner info is not found
    } catch (e) {
      throw Exception('Falha ao buscar informações do parceiro: $e');
    }
  }
}