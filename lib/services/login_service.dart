import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';

class LoginScreenService {
  Future<void> loginUser({
    required String email,
    required String password,
    required TextEditingController emailController,
    required TextEditingController passwordController,
    required BuildContext context,
  }) async {
    try {
      String input = email.trim();
      String finalEmail = input;

      if (input.isEmpty || password.isEmpty) {
        throw 'Email e Senha não podem estar vazios';
      }

      // Check if input is an email or username
      if (!input.contains('@') || !input.contains('.')) {
        final userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input.trim().toLowerCase())
            .get();

        if (userSnapshot.docs.isEmpty) {
          throw 'Usuário não encontrado';
        }

        // Get the email from the user's document
        finalEmail = userSnapshot.docs.first['email'];
      }

      // Sign in with the email
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: finalEmail,
        password: password,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no login: $e')),
      );
    }
  }

  Future<void> resetPassword({
    required String email,
    required BuildContext context,
  }) async {
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira seu email.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link para reset enviado ao seu email')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha ao enviar reset de senha: $e')),
      );
    }
  }
}
