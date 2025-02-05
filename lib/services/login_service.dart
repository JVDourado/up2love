import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../screens/home_screen.dart';

class LoginScreenService {
  Future<void> loginUser({
    required String input,
    required String password,
    required BuildContext context,
  }) async {
    try {
      input = input.trim();

      if (input.isEmpty || password.isEmpty) {
        throw 'Email/Username e Senha não podem estar vazios';
      }

      // Check if input is a username (starts with '@')
      if (input.startsWith('@')) {
        // Handle username login
        await _loginWithUsername(input, password, context);
      } else {
        // Handle email login
        await _loginWithEmail(input, password, context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha no login: $e')),
      );
    }
  }

  Future<void> _loginWithUsername(
    String username,
    String password,
    BuildContext context,
  ) async {
    try {
      // Convert the username to lowercase for consistency
      username = username.toLowerCase();

      // Query Firestore to find the user document with the matching username
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1) // Limit to 1 document
          .get();

      if (userSnapshot.docs.isEmpty) {
        throw 'Usuário não encontrado';
      }

      // Get the email from the user's document
      final email = userSnapshot.docs.first['email'];

      // Sign in with the email
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      throw 'Erro ao fazer login com username: $e';
    }
  }

  Future<void> _loginWithEmail(
    String email,
    String password,
    BuildContext context,
  ) async {
    try {
      // Sign in with the email
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Navigate to the home screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      throw 'Erro ao fazer login com email: $e';
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