// sign_up_screen_service.dart
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class SignUpScreenService {
  // Function to pick image
  Future<XFile?> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    return image;
  }

  // Function to upload image to Firebase Storage
  Future<String?> uploadImage(XFile image, String userId) async {
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('users')
          .child(userId)
          .child('profile_picture')
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Upload the image
      await ref.putFile(File(image.path));
      // Get the image URL
      final imageUrl = await ref.getDownloadURL();
      return imageUrl;
    } catch (e) {
      print('Image upload failed: $e');
      return null;
    }
  }

  // Function to register a new user
  Future<String?> registerUser({
    required String email,
    required String password,
    required String name,
    required String username,
    required String status,
    required String partner,
    required String age,
    required XFile profileImage,
  }) async {
    try {
      final UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      final userId = userCredential.user!.uid;

      // Upload the profile picture and get the URL
      final imageUrl = await uploadImage(profileImage, userId);
      if (imageUrl == null) {
        return 'Falha ao carregar a imagem de perfil';
      }

      // Store all user data, including the profile picture URL
      await FirebaseFirestore.instance.collection('users').doc(userId).set({
        'name': name.trim(),
        'username': '@${username.trim().toLowerCase()}',
        'email': email.trim().toLowerCase(),
        'age': int.tryParse(age.trim()) ?? 0,
        'status': status.trim(),
        'partner': partner.trim(),
        'profile_picture': imageUrl, // Save the image URL in Firestore
      });

      return null; // Registration successful
    } catch (e) {
      print('Cadastro falhou: $e');
      return 'Cadastro falhou: $e';
    }
  }
}
